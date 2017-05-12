#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 4;

use DateTime;
use DateTime::Duration;
use DateTime::Set;
# use warnings;

#======================================================================
# recurrence intersection
#====================================================================== 

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

my $res;

my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

# makes a set with month-day == 15 ( always 15 )
my $month_callback_1 = sub {
            $_[0]->add( days => -14 )
                 ->truncate( to => 'month' )
                 ->add( months => 1, days => 14 );
        };

# makes a set with month-day == 15 days from end-of-month ( 13, 14, 15 or 16 )
my $month_callback_2 = sub {
            $_[0]
                 ->add( days => 16 )
                 ->truncate( to => 'month' )
                 ->add( months => 1 )
                 ->add( days => -16 );
        };


my $months1 = DateTime::Set->from_recurrence( 
    recurrence => $month_callback_1, 
    start => $t1,
);

my $months2 = DateTime::Set->from_recurrence( 
    recurrence => $month_callback_2, 
    start => $t2,
);


my $iterator = $months1->iterator;
my @res = ();
for (1..5) {
        my $tmp = $iterator->next;
        push @res, $tmp->ymd if defined $tmp;
}
$res = join( ' ', @res );
ok( $res eq '1810-09-15 1810-10-15 1810-11-15 1810-12-15 1811-01-15',
        "iterations of month1 give $res" );

$iterator = $months2->iterator;
@res = ();
for (1..5) {
        my $tmp = $iterator->next;
        push @res, $tmp->ymd if defined $tmp;
}
$res = join( ' ', @res );
ok( $res eq '1810-12-16 1811-01-16 1811-02-13 1811-03-16 1811-04-15',
        "iterations of month2 give $res" );

my $m12 = $months1->intersection( $months2 );

$res = $m12->min;
$res = $res->ymd if ref($res);
ok( $res eq '1811-04-15', 
    "min() - got $res" );


$iterator = $m12->iterator;
@res = ();
for (1..3) {
        my $tmp = $iterator->next;
        push @res, $tmp->ymd if defined $tmp && ref($tmp);
}
$res = join( ' ', @res );
ok( $res eq '1811-04-15 1811-06-15 1811-09-15',
        "3 iterations give $res" );


1;

