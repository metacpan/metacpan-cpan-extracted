#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 4;

use DateTime;
use DateTime::Duration;
use DateTime::Set;

#======================================================================
# complement + recurrence
#====================================================================== 

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

my $res;

my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

my $month_callback = sub {
            $_[0]->truncate( to => 'month' );
            $_[0]->add( months => 1 );
            return $_[0];
        };

my $months = DateTime::Set->from_recurrence( 
    recurrence => $month_callback, 
    start => $t1,
);
$res = $months->min;
$res = $res->ymd if ref($res);
ok( $res eq '1810-09-01', 
    "min() - got $res" );

my $next_months = $months->complement( $months->min );
$res = $next_months->min;
$res = $res->ymd if ref($res);
ok( $res eq '1810-10-01',
    "min() - got $res" );

# trying to duplicate an error that happens in Date::Set

my $iter1 = $months->iterator;
my $first = $iter1->next;
$next_months = $months->complement( $first );
my $iter2 = $next_months->iterator;
$res = $iter2->next;
$res = $res->ymd if ref($res);
ok( $res eq '1810-10-01',
    "min() - got $res" );

$res = $iter2->next;
$res = $res->ymd if ref($res);
ok( $res eq '1810-11-01',
    "min() - got $res" );

1;

