#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Cwd qw(getcwd);

# Test the Tools module functionality

use_ok('Acme::Claude::Shell::Tools', 'shell_tools');

# Create a mock session object for testing
package MockSession;
sub new {
    my ($class, %args) = @_;
    return bless {
        working_dir => $args{working_dir} // '.',
        colorful    => $args{colorful} // 0,
        safe_mode   => $args{safe_mode} // 1,
        _history    => [],
        _spinner    => undef,
    }, $class;
}
sub working_dir { $_[0]->{working_dir} }
sub colorful { $_[0]->{colorful} }
sub safe_mode { $_[0]->{safe_mode} }
sub _history { $_[0]->{_history} }
sub _spinner {
    my $self = shift;
    if (@_) { $self->{_spinner} = shift }
    return $self->{_spinner};
}
sub can {
    my ($self, $method) = @_;
    return $self->SUPER::can($method) || ($method eq '_spinner' ? 1 : 0);
}

package main;

# Create temp directory for tests
my $tempdir = tempdir(CLEANUP => 1);

# Create some test files
my $test_file = File::Spec->catfile($tempdir, 'test.txt');
open my $fh, '>', $test_file or die "Cannot create test file: $!";
print $fh "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\n";
close $fh;

my $test_file2 = File::Spec->catfile($tempdir, 'test.pm');
open $fh, '>', $test_file2 or die "Cannot create test file: $!";
print $fh "package Test;\nsub foo { 1 }\n1;\n";
close $fh;

# Create subdirectory with files
my $subdir = File::Spec->catdir($tempdir, 'subdir');
mkdir $subdir or die "Cannot create subdir: $!";
my $sub_file = File::Spec->catfile($subdir, 'nested.txt');
open $fh, '>', $sub_file or die "Cannot create nested file: $!";
print $fh "Nested content\n";
close $fh;

# Create mock session
my $session = MockSession->new(
    working_dir => $tempdir,
    colorful    => 0,
    safe_mode   => 1,
);

# Get tools
my $tools = shell_tools($session);
ok($tools, 'shell_tools returns tools');
is(ref($tools), 'ARRAY', 'shell_tools returns arrayref');
ok(scalar(@$tools) >= 5, 'At least 5 tools defined');

# Check tool names
my %tool_names = map { $_->name => $_ } @$tools;
ok(exists $tool_names{execute_command}, 'execute_command tool exists');
ok(exists $tool_names{read_file}, 'read_file tool exists');
ok(exists $tool_names{list_directory}, 'list_directory tool exists');
ok(exists $tool_names{search_files}, 'search_files tool exists');
ok(exists $tool_names{get_system_info}, 'get_system_info tool exists');
ok(exists $tool_names{get_working_directory}, 'get_working_directory tool exists');

# Test tool has proper structure
for my $tool (@$tools) {
    ok($tool->name, "Tool has name: " . $tool->name);
    ok($tool->description, "Tool " . $tool->name . " has description");
    ok($tool->input_schema, "Tool " . $tool->name . " has input_schema");
}

# Test get_working_directory tool execution
subtest 'get_working_directory tool' => sub {
    plan tests => 3;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $tool = $tool_names{get_working_directory};
    my $future = $tool->execute({}, $loop);
    ok($future, 'Returns a future');

    my $result = $future->get;
    ok($result, 'Got result');
    is(ref($result->{content}), 'ARRAY', 'Result has content array');
};

# Test read_file tool (safe, no approval needed)
subtest 'read_file tool' => sub {
    plan tests => 6;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $tool = $tool_names{read_file};

    # Read full file
    my $future = $tool->execute({ path => $test_file }, $loop);
    my $result = $future->get;
    ok($result, 'Got result');
    ok(!$result->{is_error}, 'No error');
    like($result->{content}[0]{text}, qr/Line 1/, 'Content contains expected text');

    # Read with lines limit
    $future = $tool->execute({ path => $test_file, lines => 2 }, $loop);
    $result = $future->get;
    ok(!$result->{is_error}, 'No error with lines param');
    my $text = $result->{content}[0]{text};
    my @lines = split /\n/, $text;
    is(scalar(@lines), 2, 'Got only 2 lines');

    # Read non-existent file
    $future = $tool->execute({ path => '/nonexistent/file.txt' }, $loop);
    $result = $future->get;
    ok($result->{is_error}, 'Error for non-existent file');
};

# Test list_directory tool (safe, no approval needed)
subtest 'list_directory tool' => sub {
    plan tests => 5;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $tool = $tool_names{list_directory};

    # List directory
    my $future = $tool->execute({ path => $tempdir }, $loop);
    my $result = $future->get;
    ok(!$result->{is_error}, 'No error');
    like($result->{content}[0]{text}, qr/test\.txt/, 'Found test.txt');
    like($result->{content}[0]{text}, qr/test\.pm/, 'Found test.pm');
    like($result->{content}[0]{text}, qr/subdir/, 'Found subdir');

    # List with pattern filter
    $future = $tool->execute({ path => $tempdir, pattern => '*.pm' }, $loop);
    $result = $future->get;
    like($result->{content}[0]{text}, qr/test\.pm/, 'Pattern filter works');
};

# Test search_files tool (safe, no approval needed)
subtest 'search_files tool' => sub {
    plan tests => 4;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $tool = $tool_names{search_files};

    # Search by filename pattern
    my $future = $tool->execute({ path => $tempdir, pattern => '*.txt' }, $loop);
    my $result = $future->get;
    ok(!$result->{is_error}, 'No error');
    like($result->{content}[0]{text}, qr/test\.txt/, 'Found test.txt by pattern');

    # Search by content
    $future = $tool->execute({ path => $tempdir, content => 'package' }, $loop);
    $result = $future->get;
    ok(!$result->{is_error}, 'No error for content search');
    like($result->{content}[0]{text}, qr/test\.pm/, 'Found file with content');
};

# Test get_system_info tool (safe, no approval needed)
subtest 'get_system_info tool' => sub {
    plan tests => 4;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $tool = $tool_names{get_system_info};

    # Get all info
    my $future = $tool->execute({ info_type => 'all' }, $loop);
    my $result = $future->get;
    ok(!$result->{is_error}, 'No error');
    like($result->{content}[0]{text}, qr/OS Information/, 'Contains OS info');
    like($result->{content}[0]{text}, qr/System:/, 'Contains system info');

    # Get just OS info
    $future = $tool->execute({ info_type => 'os' }, $loop);
    $result = $future->get;
    like($result->{content}[0]{text}, qr/Perl:/, 'Contains Perl version');
};

done_testing();
