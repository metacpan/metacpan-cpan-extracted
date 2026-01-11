#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny;

use_ok('Claude::Agent::Code::Review::Filter');
use_ok('Claude::Agent::Code::Review::Issue');

# Create a temp directory for file-based tests
my $tempdir = tempdir(CLEANUP => 1);
my $orig_dir = path('.')->realpath;

# Test basic filtering
subtest 'Basic filter' => sub {
    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'security',
            file        => '/nonexistent/file.pm',
            line        => 10,
            description => 'Some issue',
        ),
    );

    # Non-existent files should be kept (can't verify)
    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 1, 'keeps issues for non-existent files');
};

# Test unused import false positive detection
subtest 'Unused import false positive' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'import_test.pm');
    $test_file->spew_utf8(<<'END');
package ImportTest;
use strict;
use warnings;
use Path::Tiny;

sub do_something {
    my $path = path('/tmp');
    return $path->stringify;
}

1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'low',
            category    => 'style',
            file        => 'import_test.pm',
            line        => 4,
            description => "'path' is imported but unused",
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters false positive unused import when actually used');

    chdir($orig_dir);
};

# Test "module doesn't end with 1" false positive
subtest 'EndWithOne false positive' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'endwith1.pm');
    $test_file->spew_utf8(<<'END');
package EndWith1;
use strict;

sub foo { 1 }

1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'bugs',
            file        => 'endwith1.pm',
            line        => 1,
            description => 'Module does not end with 1; (RequireEndWithOne)',
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters false positive when module does end with 1');

    chdir($orig_dir);
};

# Test path validation false positive
subtest 'Path validation false positive' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'pathval.pm');
    $test_file->spew_utf8(<<'END');
package PathVal;
use Path::Tiny;

sub safe_read {
    my ($file) = @_;
    my $base_dir = path('.')->realpath;
    my $real = eval { path($file)->realpath };
    return unless $real && $base_dir->subsumes($real);
    return $real->slurp_utf8;
}

1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'security',
            file        => 'pathval.pm',
            line        => 5,
            description => 'Missing path validation, potential path traversal',
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters false positive when path validation exists');

    chdir($orig_dir);
};

# Test error handling false positive
subtest 'Error handling false positive' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'errorhandling.pm');
    $test_file->spew_utf8(<<'END');
package ErrorHandling;

sub process {
    my ($data) = @_;
    my $result = eval { do_risky_thing($data) };
    if ($@) {
        warn "Failed: $@";
        return;
    }
    return $result // 'default';
}

1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'bugs',
            file        => 'errorhandling.pm',
            line        => 5,
            description => 'Missing error handling for do_risky_thing',
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters false positive when error handling exists');

    chdir($orig_dir);
};

# Test silent failure false positive
subtest 'Silent failure false positive' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'silent.pm');
    $test_file->spew_utf8(<<'END');
package Silent;

sub process {
    my ($file) = @_;
    my $content = eval { read_file($file) };
    if (!$content) {
        warn "Failed to read $file";
        return;
    }
    return $content;
}

1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'bugs',
            file        => 'silent.pm',
            line        => 5,
            description => 'Code silently fails without notification',
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters false positive when warn exists');

    chdir($orig_dir);
};

# Test documented limitation acknowledgment
subtest 'Documented limitation' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'limited.pm');
    $test_file->spew_utf8(<<'END');
package Limited;

# Note: This is a basic implementation that doesn't handle all edge cases
# TODO: Add support for Windows paths
sub process_path {
    my ($path) = @_;
    return $path =~ s|/+|/|gr;
}

1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'low',
            category    => 'bugs',
            file        => 'limited.pm',
            line        => 7,
            description => "Doesn't handle Windows paths properly",
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters issues for documented limitations');

    chdir($orig_dir);
};

# Test custom filters
subtest 'Custom filters' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'custom.pm');
    $test_file->spew_utf8(<<'END');
package Custom;
sub foo { 1 }
1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'low',
            category    => 'style',
            file        => 'custom.pm',
            line        => 2,
            description => 'Known false positive in our codebase',
        ),
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'bugs',
            file        => 'custom.pm',
            line        => 2,
            description => 'Real issue',
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(
        issues  => \@issues,
        filters => [
            sub {
                my ($issue, $context) = @_;
                return $issue->description =~ /Known false positive/ ? 1 : 0;
            },
        ],
    );

    is(scalar @filtered, 1, 'custom filter removed one issue');
    is($filtered[0]->description, 'Real issue', 'kept the real issue');

    chdir($orig_dir);
};

# Test count_filtered
subtest 'count_filtered' => sub {
    my @original = (1, 2, 3, 4, 5);
    my @filtered = (1, 2, 3);

    my ($kept, $removed) = Claude::Agent::Code::Review::Filter->count_filtered(
        original => \@original,
        filtered => \@filtered,
    );

    is($kept, 3, 'kept count');
    is($removed, 2, 'removed count');
};

# Test no critic directive
subtest 'No critic directive' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'nocritic.pm');
    $test_file->spew_utf8(<<'END');
package NoCritic;

## no critic (RequireExplicitPackage)
sub foo {
    return 1;
}

1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'info',
            category    => 'style',
            file        => 'nocritic.pm',
            line        => 3,
            description => 'No critic directive may be obsolete',
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters no critic complaints when directive exists');

    chdir($orig_dir);
};

# Test inconsistent style filtering
subtest 'Inconsistent style' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'style.pm');
    $test_file->spew_utf8(<<'END');
package Style;
sub foo { 1 }
sub bar { 2 }
1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'info',
            category    => 'style',
            file        => 'style.pm',
            line        => 2,
            description => 'Inconsistent style pattern in naming',
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters inconsistent style complaints');

    chdir($orig_dir);
};

# Test TOCTOU filtering
subtest 'TOCTOU false positive' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'toctou.pm');
    $test_file->spew_utf8(<<'END');
package Toctou;

# Note: TOCTOU is unavoidable here, but downstream code handles missing files gracefully
sub read_if_exists {
    my ($file) = @_;
    return unless -f $file;
    return eval { path($file)->slurp_utf8 };
}

1;
END

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'medium',
            category    => 'security',
            file        => 'toctou.pm',
            line        => 6,
            description => 'TOCTOU race condition with file check',
        ),
    );

    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 0, 'filters TOCTOU when acknowledged');

    chdir($orig_dir);
};

# Test invalid line number handling
subtest 'Invalid line number' => sub {
    chdir($tempdir);

    my $test_file = path($tempdir, 'short.pm');
    $test_file->spew_utf8("package Short;\n1;\n");

    my @issues = (
        Claude::Agent::Code::Review::Issue->new(
            severity    => 'high',
            category    => 'bugs',
            file        => 'short.pm',
            line        => 999,  # Way beyond file length
            description => 'Some issue',
        ),
    );

    # Should not crash, should keep the issue (can't verify)
    my @filtered = Claude::Agent::Code::Review::Filter->filter(issues => \@issues);
    is(scalar @filtered, 1, 'keeps issues with invalid line numbers');

    chdir($orig_dir);
};

done_testing();
