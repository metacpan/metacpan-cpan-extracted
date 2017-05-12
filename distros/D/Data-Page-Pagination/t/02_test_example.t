#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Carp qw(croak);
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $INPUT_RECORD_SEPARATOR $OS_ERROR $CHILD_ERROR);

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 2);

my $test = 'page.pl';

my $dir = getcwd();
chdir("$dir/example");

my $result = qx{perl -I../lib $test 2>&1};
$CHILD_ERROR
    and die "Couldn't run $test (status $CHILD_ERROR)";
eq_or_diff(
    $result,
    q{},
    "run example $test",
);

my $expected_output = do {
    open my $file_handle, '<', 'expected_output.html'
        or croak $OS_ERROR;
    my $content = <$file_handle>;
    local $INPUT_RECORD_SEPARATOR = ();
    close $file_handle;
    $content;
};    

my $output = do {
    open my $file_handle, '<', 'output.html'
        or croak $OS_ERROR;
    my $content = <$file_handle>;
    local $INPUT_RECORD_SEPARATOR = ();
    close $file_handle;
    $content;
};

chdir($dir);

eq_or_diff(
    $expected_output,
    $output,
    'compare output',
);
