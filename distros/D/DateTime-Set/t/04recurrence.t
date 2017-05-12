#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 25;

use DateTime;
use DateTime::Duration;
use DateTime::Set;
# use warnings;

#======================================================================
# recurrence
#====================================================================== 

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

my $res;

my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

my $month_callback = sub {
            $_[0]->truncate( to => 'month' );
            # warn " truncate = ".$_[0]->ymd;
            $_[0]->add( months => 1 );
            # warn " add = ".$_[0]->ymd;
            return $_[0];
        };

my $months = DateTime::Set->from_recurrence(
    recurrence => $month_callback,
);

# contains datetime, unbounded set
{
    my $t0 = $t2->clone->truncate( to => 'month' );
    my $t0_set = DateTime::Set->from_datetimes( dates => [ $t0 ] );
    is( $months->contains( $t1 ), 0, "does not contain datetime" );
    is( $months->contains( $t1, $t0 ), 0, "does not contain datetime list" );
    is( $months->contains( $t0 ), 1, "contains datetime" );

    is( $months->intersects( $t1 ), 0, "does not intersect datetime" );
    is( $months->intersects( $t1, $t0 ), 1, "intersects datetime list" );
    is( $months->intersects( $t0 ), 1, "intersects datetime" );

    ok( ! defined $months->contains( $months ) , 
        "contains - can't do it with both unbounded sets, returns undef" );
        
    is( $t0_set->intersects( $months ), 1, "intersects unbounded set" );
}

# "START"

$months = DateTime::Set->from_recurrence( 
    recurrence => $month_callback, 
    start => $t1,   # 1810-08-22
);

# contains datetime, semi-bounded set
{
    my $t0 = $t2->clone->truncate( to => 'month' );
    is( $months->contains( $t1 ), 0, "does not contain datetime" );
    is( $months->contains( $t1, $t0 ), 0, "does not contain datetime list" );
    is( $months->contains( $t0 ), 1, "contains datetime" );

    is( $months->intersects( $t1 ), 0, "does not intersect datetime" );
    is( $months->intersects( $t1, $t0 ), 1, "intersects datetime list" );
    is( $months->intersects( $t0 ), 1, "intersects datetime" );
}

$res = $months->min;
$res = $res->ymd if ref($res);
is( $res, '1810-09-01', 
    "min()" );
$res = $months->max;
# $res = $res->ymd if ref($res);
is( ref($res), 'DateTime::Infinite::Future',
    "max()" );

# "END"
$months = DateTime::Set->from_recurrence(
    recurrence => $month_callback,
    end => $t1,  # 1810-08-22
);
$res = $months->min;
# $res = $res->ymd if ref($res);
is( ref($res), 'DateTime::Infinite::Past',
    "min()" );

{
$res = $months->max;
$res = $res->ymd if ref($res);
is( $res, '1810-08-01',   
    "max()" );
}

is( $months->count, undef, "count" );

# "START+END"
$months = DateTime::Set->from_recurrence(
    recurrence => $month_callback,
    start => $t1,  # 1810-08-22
    end => $t2,    # 1810-11-24
);
$res = $months->min;
$res = $res->ymd if ref($res);
is( $res, '1810-09-01',
    "min()" );

{
$res = $months->max;
$res = $res->ymd if ref($res);
is( $res, '1810-11-01',
    "max()" );
}

# "START+END" at recurrence 
$t1->set( day => 1 );  # month=8
$t2->set( day => 1 );  # month=11
$months = DateTime::Set->from_recurrence(
    recurrence => $month_callback,
    start => $t1,
    end => $t2,
);
$res = $months->min;
$res = $res->ymd if ref($res);
is( $res, '1810-08-01',
    "min()" );

{
$res = $months->max;
$res = $res->ymd if ref($res);
is( $res, '1810-11-01',
    "max()" );
}

{
# verify that the set-span when backtracking is ok.
# This is _critical_ for doing correct intersections
$res = $months->intersection( DateTime->new( year=>1810, month=>11, day=>1 ) );
$res = $res->max;
$res = $res->ymd if ref($res);
is( $res, '1810-11-01',
    "intersection at the recurrence" );
}

# big set - "START+END" at recurrence
{
my $set = DateTime::SpanSet->from_spans(
    spans => [
        DateTime::Span->from_datetimes(
            start => new DateTime( year => '1950', month => '08', day => '22' ),
            end   => new DateTime( year => '2000', month => '08', day => '22' ),
        ),
        DateTime::Span->from_datetimes(
            start => new DateTime( year => '2350', month => '08', day => '22' ),
            end   => new DateTime( year => '2400', month => '08', day => '22' ),
        ),
    ],
);
my $months = DateTime::Set->from_recurrence(
    recurrence => $month_callback,
);
my $bounded = $months->intersection( $set );

# ok( ! defined $bounded->count, "will not count: there are too many elements" );
is( $bounded->count, 1200, "too many elements - iterate" );

}

1;

