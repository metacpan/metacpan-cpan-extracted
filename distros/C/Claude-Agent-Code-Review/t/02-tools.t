#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use Path::Tiny;

use_ok('Claude::Agent::Code::Review::Tools');

# Test server creation
subtest 'Create Server' => sub {
    my $server = Claude::Agent::Code::Review::Tools->create_server();

    isa_ok($server, 'Claude::Agent::MCP::Server');
    is($server->name, 'code_review', 'server name');
    is($server->version, '1.0.0', 'server version');

    my $tools = $server->tools;
    is(scalar @$tools, 5, 'five tools');

    my @names = map { $_->name } @$tools;
    is_deeply([sort @names], [sort qw(
        get_file_context
        search_codebase
        check_tests
        get_dependencies
        analyze_complexity
    )], 'tool names');

    # Test tool_names method
    my $full_names = $server->tool_names;
    is(scalar @$full_names, 5, 'five full names');
    ok((grep { /^mcp__code_review__/ } @$full_names) == 5, 'all names prefixed');
};

# Create a temp directory for file-based tests
my $tempdir = tempdir(CLEANUP => 1);

# Test get_file_context tool
subtest 'get_file_context tool' => sub {
    my $server = Claude::Agent::Code::Review::Tools->create_server();
    my $tool = $server->get_tool('get_file_context');

    ok($tool, 'tool exists');
    is($tool->name, 'get_file_context', 'tool name');

    # Test with non-existent file
    my $result = $tool->execute({ file => '/nonexistent/file.pm', line => 1 });
    ok($result->{is_error}, 'error for missing file');
    like($result->{content}[0]{text}, qr/File not found/, 'error message');

    # Create a test file
    my $test_file = path($tempdir, 'test.pm');
    $test_file->spew_utf8(join("\n", map { "line $_" } 1..20));

    # Change to temp dir temporarily for path validation
    my $orig_dir = path('.')->realpath;
    chdir($tempdir);

    $result = $tool->execute({ file => 'test.pm', line => 10 });
    ok(!$result->{is_error}, 'no error for existing file');
    like($result->{content}[0]{text}, qr/>>>.*10:/, 'highlights target line');
    like($result->{content}[0]{text}, qr/line 10/, 'contains line content');

    # Test with custom context
    $result = $tool->execute({ file => 'test.pm', line => 10, before => 2, after => 2 });
    my @lines = split /\n/, $result->{content}[0]{text};
    is(scalar @lines, 5, 'custom context size');

    chdir($orig_dir);
};

# Test search_codebase tool
subtest 'search_codebase tool' => sub {
    my $server = Claude::Agent::Code::Review::Tools->create_server();
    my $tool = $server->get_tool('search_codebase');

    ok($tool, 'tool exists');

    # Create test files
    my $pm_file = path($tempdir, 'searchtest.pm');
    $pm_file->spew_utf8("package SearchTest;\nuse strict;\nmy \$foo = 'bar';\n1;\n");

    my $orig_dir = path('.')->realpath;
    chdir($tempdir);

    # Test basic search
    my $result = $tool->execute({ pattern => 'strict' });
    ok(!$result->{is_error}, 'no error');
    like($result->{content}[0]{text}, qr/strict/, 'found pattern');

    # Test with no matches
    $result = $tool->execute({ pattern => 'nonexistent_pattern_xyz' });
    like($result->{content}[0]{text}, qr/No matches found/, 'no matches message');

    # Test pattern length limit (only applies in regex mode)
    my $long_pattern = 'a' x 600;
    $result = $tool->execute({ pattern => $long_pattern, literal => 0 });
    ok($result->{is_error}, 'error for long pattern in regex mode');
    like($result->{content}[0]{text}, qr/too long/, 'pattern too long message');

    # Test invalid regex (only errors in regex mode)
    $result = $tool->execute({ pattern => '[invalid', literal => 0 });
    ok($result->{is_error}, 'error for invalid regex in regex mode');

    # Test nested quantifier rejection (ReDoS protection)
    $result = $tool->execute({ pattern => '(a+)+', literal => 0 });
    ok($result->{is_error}, 'error for nested quantifiers');
    like($result->{content}[0]{text}, qr/nested quantifiers/, 'ReDoS protection message');

    # Test literal mode (default) - long patterns and special chars are safe
    $result = $tool->execute({ pattern => 'a' x 600 });  # literal mode
    ok(!$result->{is_error}, 'long pattern OK in literal mode');

    $result = $tool->execute({ pattern => '[special*chars+' });  # literal mode
    ok(!$result->{is_error}, 'special chars OK in literal mode');

    # Test directory traversal protection
    $result = $tool->execute({ pattern => 'test', file_pattern => '../../../etc/*' });
    ok($result->{is_error}, 'error for path traversal');

    chdir($orig_dir);
};

# Test check_tests tool
subtest 'check_tests tool' => sub {
    my $server = Claude::Agent::Code::Review::Tools->create_server();
    my $tool = $server->get_tool('check_tests');

    ok($tool, 'tool exists');

    # Create test directory structure
    my $t_dir = path($tempdir, 't');
    $t_dir->mkpath;

    my $test_file = path($t_dir, 'My-Module.t');
    $test_file->spew_utf8("use Test::More;\nok(my_function(), 'test');\ndone_testing;\n");

    my $orig_dir = path('.')->realpath;
    chdir($tempdir);

    # Test finding tests
    my $result = $tool->execute({ module => 'My::Module' });
    ok(!$result->{is_error}, 'no error');
    like($result->{content}[0]{text}, qr/Found test files/, 'found test files');

    # Test with function check
    $result = $tool->execute({ module => 'My::Module', function => 'my_function' });
    like($result->{content}[0]{text}, qr/mentions 'my_function'/, 'function mentioned');

    # Test with non-existent module
    $result = $tool->execute({ module => 'Non::Existent::Module' });
    like($result->{content}[0]{text}, qr/No test files found/, 'no tests found');

    chdir($orig_dir);
};

# Test get_dependencies tool
subtest 'get_dependencies tool' => sub {
    my $server = Claude::Agent::Code::Review::Tools->create_server();
    my $tool = $server->get_tool('get_dependencies');

    ok($tool, 'tool exists');

    # Test with non-existent file
    my $result = $tool->execute({ file => '/nonexistent/file.pm' });
    ok($result->{is_error}, 'error for missing file');

    # Create a test file with dependencies
    my $dep_file = path($tempdir, 'deps.pm');
    $dep_file->spew_utf8(<<'END');
package Deps;
use strict;
use warnings;
use Path::Tiny;
use Cpanel::JSON::XS;
require Some::Module;
1;
END

    my $orig_dir = path('.')->realpath;
    chdir($tempdir);

    $result = $tool->execute({ file => 'deps.pm' });
    ok(!$result->{is_error}, 'no error');
    like($result->{content}[0]{text}, qr/Path::Tiny/, 'found Path::Tiny');
    like($result->{content}[0]{text}, qr/Cpanel::JSON::XS/, 'found JSON::XS');
    like($result->{content}[0]{text}, qr/Some::Module/, 'found require');
    unlike($result->{content}[0]{text}, qr/use statements:.*strict/s, 'excludes strict');

    chdir($orig_dir);
};

# Test analyze_complexity tool
subtest 'analyze_complexity tool' => sub {
    my $server = Claude::Agent::Code::Review::Tools->create_server();
    my $tool = $server->get_tool('analyze_complexity');

    ok($tool, 'tool exists');

    # Test with non-existent file
    my $result = $tool->execute({ file => '/nonexistent/file.pm', function => 'foo' });
    ok($result->{is_error}, 'error for missing file');

    # Create a test file with functions
    my $complex_file = path($tempdir, 'complex.pm');
    $complex_file->spew_utf8(<<'END');
package Complex;

sub simple {
    my ($x) = @_;
    return $x + 1;
}

sub moderate {
    my ($x, $y) = @_;
    if ($x > 0) {
        if ($y > 0) {
            return $x + $y;
        } else {
            return $x - $y;
        }
    } elsif ($x < 0) {
        return -$x;
    }
    return 0;
}

sub complex {
    my ($data) = @_;
    for my $item (@$data) {
        if ($item->{active} && $item->{valid}) {
            if ($item->{type} eq 'a') {
                process_a($item);
            } elsif ($item->{type} eq 'b') {
                process_b($item);
            } else {
                my $result = $item->{fallback} || default();
                if ($result) {
                    return $result;
                }
            }
        } elsif ($item->{retry}) {
            while ($item->{attempts} < 3) {
                try_again($item);
            }
        }
    }
}

1;
END

    my $orig_dir = path('.')->realpath;
    chdir($tempdir);

    # Test simple function
    $result = $tool->execute({ file => 'complex.pm', function => 'simple' });
    ok(!$result->{is_error}, 'no error');
    like($result->{content}[0]{text}, qr/Cyclomatic complexity: \d+/, 'has complexity');
    like($result->{content}[0]{text}, qr/Low complexity/, 'simple is low');

    # Test moderate function
    $result = $tool->execute({ file => 'complex.pm', function => 'moderate' });
    like($result->{content}[0]{text}, qr/complexity/, 'has complexity');

    # Test complex function
    $result = $tool->execute({ file => 'complex.pm', function => 'complex' });
    like($result->{content}[0]{text}, qr/complexity/, 'has complexity');

    # Test non-existent function
    $result = $tool->execute({ file => 'complex.pm', function => 'nonexistent' });
    like($result->{content}[0]{text}, qr/not found/, 'function not found');

    chdir($orig_dir);
};

# Test path traversal protection
subtest 'Path traversal protection' => sub {
    my $server = Claude::Agent::Code::Review::Tools->create_server();

    # Test get_file_context with path traversal
    my $tool = $server->get_tool('get_file_context');
    my $result = $tool->execute({ file => '../../../etc/passwd', line => 1 });
    ok($result->{is_error}, 'blocked path traversal in get_file_context');

    # Test get_dependencies with path traversal
    $tool = $server->get_tool('get_dependencies');
    $result = $tool->execute({ file => '../../../etc/passwd' });
    ok($result->{is_error}, 'blocked path traversal in get_dependencies');

    # Test analyze_complexity with path traversal
    $tool = $server->get_tool('analyze_complexity');
    $result = $tool->execute({ file => '../../../etc/passwd', function => 'test' });
    ok($result->{is_error}, 'blocked path traversal in analyze_complexity');
};

done_testing();
