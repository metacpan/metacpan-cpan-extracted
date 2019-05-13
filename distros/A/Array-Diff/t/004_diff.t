#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

my $m;
BEGIN {
    use_ok( $m = 'Array::Diff' );
}

can_ok( $m, 'new' );
can_ok( $m, 'diff' );
can_ok( $m, 'added' );
can_ok( $m, 'deleted' );
can_ok( $m, 'count' );

my $old = [ 'a', 'b', 'c' ];
my $new = [ 'b', 'c', 'd' ];

my $diff_expected_added   = ['d'];
my $diff_expected_deleted = ['a'];
my $diff;
eval {
    $diff = $m->diff( $old, $new );
};

is( $diff->count, 2, 'diff count is ok' );
is_deeply( $diff->added,   $diff_expected_added,   "added list correctly" );
is_deeply( $diff->deleted, $diff_expected_deleted, "deleted list correctly" );

# rt bug #101707
my $old2 = [ 'a' ];
my @new2 = ( 'b', 'c', 'd' );

my $diff2 = eval { Array::Diff->diff( $old2, \@new2 ) };
my $expected_added = [ 'b', 'c', 'd' ];
my $expected_deleted = [ 'a' ];
is ( $diff2->count, 4, 'diff count is ok' );
is_deeply( $diff2->added, $expected_added, 'added list correct' );
is_deeply( $diff2->deleted, $expected_deleted, 'deleted list correct' );
