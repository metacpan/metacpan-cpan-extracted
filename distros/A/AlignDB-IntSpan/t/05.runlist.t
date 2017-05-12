#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;    #qw(no_plan);

BEGIN {
    use_ok('AlignDB::IntSpan');
}

{
    print "#union runlist\n";

    my $set       = AlignDB::IntSpan->new();
    my $set_1     = $set->union();
    my $runlist_1 = $set_1->runlist();
    print "#real_set:  union set -> $runlist_1\n";
    ok( $set_1->is_empty(), "empty" );

    $set->clear();
    my $set_2     = $set->union("1-5,8-9");
    my $set_3     = $set->union($set_2);
    my $runlist_2 = $set_2->runlist();
    my $runlist_3 = $set_3->runlist();
    print "#real_set: $runlist_2 -> $runlist_3\n";
    ok( $set_2->equal($set_3), "single runlist");

    $set->clear();
    my $set_4     = $set->union(0, 3, "5-9");
    my $runlist_4 = $set_4->runlist();
    print "#real_set: $runlist_4 -> 0\n";
    ok( $runlist_4 eq "0,3,5-9", "multi runlists" );

    print "\n";
}

