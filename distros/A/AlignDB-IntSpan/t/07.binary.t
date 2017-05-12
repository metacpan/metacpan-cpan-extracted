#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 64;

BEGIN {
    use_ok('AlignDB::IntSpan');
}

# A           B         U        I     X        A-B   B-A
my $table = <<END_TABLE;
  -           -         -        -     -         -     -
 1           1         1        1      -         -     -
 1           2         1-2       -    1-2        1     2
 3-9         1-2       1-9       -    1-9       3-9   1-2
 3-9         1-5       1-9      3-5   1-2,6-9   6-9   1-2
 3-9         4-8       3-9      4-8   3,9       3,9    -
 3-9         5-12      3-12     5-9   3-4,10-12 3-4  10-12
 3-9        10-12      3-12      -    3-12      3-9  10-12
 1-3,5,8-11  1-6       1-6,8-11 1-3,5 4,6,8-11  8-11 4,6
END_TABLE

my @binaries = map { [ split( ' ', $_ ) ] } split /\s*\n\s*/, $table;

# union
{
    my $count = 1;
    for my $t (@binaries) {
        my $op1      = $t->[0];
        my $op2      = $t->[1];
        my $expected = $t->[2];

        my $set1    = AlignDB::IntSpan->new($op1);
        my $set2    = AlignDB::IntSpan->new($op2);
        my $runlist = $set1->union($set2)->runlist();
        printf "#%-12s %-12s %-12s -> %-12s\n", "union", $op1, $op2, $runlist;
        my $test_name = "union|$count";
        is( $runlist, $expected, $test_name );
        $count++;
    }

    print "\n";
}

# intersect
{
    my $count = 1;
    for my $t (@binaries) {
        my $op1      = $t->[0];
        my $op2      = $t->[1];
        my $expected = $t->[3];

        my $set1    = AlignDB::IntSpan->new($op1);
        my $set2    = AlignDB::IntSpan->new($op2);
        my $runlist = $set1->intersect($set2)->runlist();
        printf "#%-12s %-12s %-12s -> %-12s\n", "intersect", $op1, $op2,
            $runlist;
        my $test_name = "intersect|$count";
        is( $runlist, $expected, $test_name );
        $count++;
    }

    print "\n";
}

# xor
{
    my $count = 1;
    for my $t (@binaries) {
        my $op1      = $t->[0];
        my $op2      = $t->[1];
        my $expected = $t->[4];

        my $set1    = AlignDB::IntSpan->new($op1);
        my $set2    = AlignDB::IntSpan->new($op2);
        my $runlist = $set1->xor($set2)->runlist();
        printf "#%-12s %-12s %-12s -> %-12s\n", "xor", $op1, $op2, $runlist;
        my $test_name = "xor|$count";
        is( $runlist, $expected, $test_name );
        $count++;
    }

    print "\n";
}

# diff1
{
    my $count = 1;
    for my $t (@binaries) {
        my $op1      = $t->[0];
        my $op2      = $t->[1];
        my $expected = $t->[5];

        my $set1    = AlignDB::IntSpan->new($op1);
        my $set2    = AlignDB::IntSpan->new($op2);
        my $runlist = $set1->diff($set2)->runlist();
        printf "#%-12s %-12s %-12s -> %-12s\n", "diff", $op1, $op2, $runlist;
        my $test_name = "diff|$count";
        is( $runlist, $expected, $test_name );
        $count++;
    }

    print "\n";
}

# diff2
{
    my $count = 1;
    for my $t (@binaries) {
        my $op1      = $t->[1];
        my $op2      = $t->[0];
        my $expected = $t->[6];

        my $set1    = AlignDB::IntSpan->new($op1);
        my $set2    = AlignDB::IntSpan->new($op2);
        my $runlist = $set1->diff($set2)->runlist();
        printf "#%-12s %-12s %-12s -> %-12s\n", "diff2", $op1, $op2, $runlist;
        my $test_name = "diff2|$count";
        is( $runlist, $expected, $test_name );
        $count++;
    }

    print "\n";
}

# direct union
{
    my $count = 1;
    for my $t (@binaries) {
        my $op1      = $t->[0];
        my $op2      = $t->[1];
        my $expected = $t->[2];

        my $set1    = AlignDB::IntSpan->new($op1);
        my $set2    = AlignDB::IntSpan->new($op2);
        my $set     = AlignDB::IntSpan::union( $set1, $set2 );
        my $runlist = $set->runlist();
        printf "#%-12s %-12s %-12s -> %-12s\n", "union", $op1, $op2, $runlist;
        my $test_name = "union|$count";
        is( $runlist, $expected, $test_name );
        $count++;
    }

    print "\n";
}

# direct intersect
{
    my $count = 1;
    for my $t (@binaries) {
        my $op1      = $t->[0];
        my $op2      = $t->[1];
        my $expected = $t->[3];

        my $set1    = AlignDB::IntSpan->new($op1);
        my $set2    = AlignDB::IntSpan->new($op2);
        my $set     = AlignDB::IntSpan::intersect( $set1, $set2 );
        my $runlist = $set->runlist();
        printf "#%-12s %-12s %-12s -> %-12s\n", "intersect", $op1, $op2,
            $runlist;
        my $test_name = "intersect|$count";
        is( $runlist, $expected, $test_name );
        $count++;
    }

    print "\n";
}
