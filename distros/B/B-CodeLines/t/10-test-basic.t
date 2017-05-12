#!/usr/bin/env perl
use warnings; use strict;
use English;  use File::Spec;
use File::Basename;
use Test::More;
if ($OSNAME eq 'MSWin32') {
    plan skip_all => "Strawberry Perl doesn't handle backtick" 
} else {
    plan;
}

sub test_it($$$)
{
    my ($invocation, $expect_ary, $msg) = @_;
    my @lines = `$invocation`;
    my $rc = $CHILD_ERROR >> 8;
    is($rc, 0, "$msg run successfully");
    map {chomp} @lines;
    is_deeply(\@lines, $expect_ary, "$msg output compares");
}

my $top_dir = File::Spec->catfile(dirname(__FILE__), '..');
my $test_prog = File::Spec->catfile($top_dir, qw(examples dolines.pl));
my $expect = [6, 7, 12, 13, 14, 15, 17, 19, 20, 21, 22, 23, 25, 26];
test_it("$EXECUTABLE_NAME $test_prog", $expect, 'file invocation');

my $lib_dir = File::Spec->catfile($top_dir, 'lib');
test_it("$EXECUTABLE_NAME -I$lib_dir -MO=CodeLines,-exec -e '
# string exec form
your(\"Perl code\");
goes(\"here\");
'", [3, 4], 'string invocation');
done_testing;
