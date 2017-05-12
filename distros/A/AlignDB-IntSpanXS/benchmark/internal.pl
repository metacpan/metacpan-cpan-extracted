#!/usr/bin/perl
use warnings;
use strict;

use YAML qw(Dump Load DumpFile LoadFile);

use Set::IntSpan;
use Set::IntSpan::Fast;
use AlignDB::IntSpan;
use AlignDB::IntSpanXS;

{
    my $set = Set::IntSpan->new("1-3,5,7-10,15-20");
    $set->insert($_) for 100 .. 1000;
    print "runlist: ", $set->run_list, "\n";
    print "contain 80\n" if $set->member(80);
    print Dump { internal => $set };
}

{
    my $set = Set::IntSpan::Fast->new();
    $set->add( 1, 2, 3, 5, 7, 8, 9, 10, 15 .. 20 );
    $set->add_range( 100, 1_000 );
    print "runlist: ", $set->as_string, "\n";
    print "contain 80\n" if $set->contains(80);
    print Dump { internal => $set };
}

{
    my $set = AlignDB::IntSpan->new();
    $set->add( 1, 2, 3, 5, 7, 8, 9, 10, 15 .. 20 );
    print $set, "\n";
    print "$_ " for ( $set->_list_to_ranges( 1, 3, 5, 7, 9 ) );
    print "\n";
    $set->add_range( 100, 1_000 );
    $set->add( 50 . '-' . 90 );
    print "runlist: ", $set, "\n";
    print "contain 80\n" if $set->contains(80);
    print $set->slice(10, 20), "\n";
    print Dump { internal => $set };
}

{
    my $set = AlignDB::IntSpanXS->new();
    $set->add( 1, 2, 3, 5, 7, 8, 9, 10, 15 .. 20 );
    print $set, "\n";
    print "$_ " for ( $set->_list_to_ranges( 1, 3, 5, 7, 9 ) );
    print "\n";
    $set->add_range( 100, 1_000 );
    $set->add( 50 . '-' . 90 );
    print "runlist: ", $set, "\n";
    print "contain 80\n" if $set->contains(80);
    print $set->slice(10, 20), "\n";
    print Dump { internal => $set };
}

