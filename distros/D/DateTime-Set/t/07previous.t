#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 7;

use DateTime;
use DateTime::Set;

#======================================================================
# backtracking + previous
#====================================================================== 

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

sub test {
    my $iterator = $_[0]->iterator;
    my @res;
    for (1..3) {
        my $tmp = $iterator->previous;
        $tmp = $tmp->ymd if UNIVERSAL::can( $tmp, 'ymd' );
        push @res, $tmp if defined $tmp;
    }
    return join( ' ', @res );
}

my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

# ------------- test a simple recurrence

my $month_callback = sub {
            $_[0]->truncate( to => 'month' );
            $_[0]->add( months => 1 );
            return $_[0];
        };
my $recurr_months = DateTime::Set->from_recurrence(
    recurrence => $month_callback,
    end => $t1, # 1810-08-22
);
is( test($recurr_months), '1810-08-01 1810-07-01 1810-06-01',
    "months" );


{

# --------- test a more complex recurrence

my $day_15_callback = sub {
        my $after = $_[0]->day >= 15;
        $_[0]->set( day => 15 );
        $_[0]->truncate( to => 'day' );
        $_[0]->add( months => 1 ) if $after;
        return $_[0];
    };
my $recurr_day_15 = DateTime::Set->from_recurrence( 
     recurrence => $day_15_callback, 
     end => $t1, # 1810-08-22
);
is( test($recurr_day_15), '1810-08-15 1810-07-15 1810-06-15',
    "recurr day 15" );

# ---------- test operations with recurrences

my $recurr_day_1_15 = $recurr_day_15 ->union( $recurr_months );
is( test($recurr_day_1_15), '1810-08-15 1810-08-01 1810-07-15',
    "union of recurrences: recurr day 1,15" );

# ---------- test add() to a recurrence

my $days_15 = $recurr_months->clone->add( days => 14 );
is( test($days_15), '1810-08-15 1810-07-15 1810-06-15',
    "days_15" );

# check that $recurr_months is still there
is( test($recurr_months), '1810-08-01 1810-07-01 1810-06-01',
    "months is still there" );

my $days_20 = $recurr_months->clone->add( days => 19 );
is( test($days_20), '1810-08-20 1810-07-20 1810-06-20',
    "days_20" );

# ---------- test operations with recurrences + add

my $days_15_and_20 = $days_15 ->union( $days_20 );

is( test($days_15_and_20), '1810-08-20 1810-08-15 1810-07-20',
    "days_15_and_20" );

}

1;

