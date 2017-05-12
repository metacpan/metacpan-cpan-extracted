#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 9;

use DateTime;
use DateTime::Set;

#======================================================================
# BASIC INITIALIZATION TESTS
#====================================================================== 

my $t1 = new DateTime( year => '1810', month => '11', day => '22' );
my $t2 = new DateTime( year => '1900', month => '11', day => '22' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

ok( ($t1->ymd." and ".$t2->ymd) eq '1810-11-22 and 1900-11-22',
    "got 1810-11-22 and 1900-11-22 - DateTime" );

my @a = $s1->as_list;
ok( ($a[0]->ymd." and ".$a[1]->ymd) eq '1810-11-22 and 1900-11-22',
    "got 1810-11-22 and 1900-11-22 - as_list" );

ok( $s1->min->ymd eq '1810-11-22', 
    'got 1810-11-22 - min' );

ok( $s1->max->ymd eq '1900-11-22',
    'got 1900-11-22 - max' );

is( $s1->is_empty_set, 0, 'non-empty set is not empty' );

eval { DateTime::Set->from_datetimes() };
ok( $@, 'Cannot call from_datetimes without dates parameter' );

my $empty = DateTime::Set->empty_set;
is( $empty->min, undef, 'empty set ->min should be undef' );
is( $empty->max, undef, 'empty set ->max should be undef' );
is( $empty->is_empty_set, 1, 'empty set is empty' );

1;

