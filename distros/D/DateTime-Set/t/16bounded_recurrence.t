#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 17;

use DateTime;
use DateTime::Duration;
use DateTime::Set;
use DateTime::Infinite;

my $res;

my $t0 = new DateTime( year => '1810', month => '05', day => '01' );
my $t1 = new DateTime( year => '1810', month => '08', day => '01' );
my $t2 = new DateTime( year => '1810', month => '11', day => '01' );

{
    # diag( "monthly from 1810-08-01 until infinity" );

    my $_next_month = sub {
            # warn "next of ". $_[0]->datetime;
            $_[0]->truncate( to => 'month' );
            $_[0]->add( months => 1 );
            return $_[0] if $_[0] >= $t1;
            return $t1->clone;
        };
    my $_previous_month = sub {
            # warn "previous of ". $_[0]->datetime;
            my $dt = $_[0]->clone;
            $_[0]->truncate( to => 'month' );
            $_[0]->subtract( months => 1 ) if $_[0] == $dt;
            return $_[0] if $_[0] >= $t1;
            return DateTime::Infinite::Past->new;
        };

    my $months = DateTime::Set->from_recurrence(
        next =>     $_next_month,
        previous => $_previous_month,
        # detect_bounded => 1,
    );

    # contains datetime, semi-bounded set

    is( $months->contains( $t0 ), 0, "does not contain datetime" );
    is( $months->contains( $t0, $t2 ), 0, "does not contain datetime list" );
    is( $months->contains( $t2 ), 1, "contains datetime" );

    is( $months->intersects( $t0 ), 0, "does not intersect datetime" );
    is( $months->intersects( $t0, $t2 ), 1, "intersects datetime list" );
    is( $months->intersects( $t2 ), 1, "intersects datetime" );


    $res = $months->min;
    $res = $res->ymd if ref($res);
    is( $res, '1810-08-01', 
        "min()" );
    $res = $months->max;
    is( ref($res), 'DateTime::Infinite::Future',
        "max()" );

}

{
    # diag( "monthly from infinity until 1810-08-01" );

    my $_next_month = sub {
            # warn "next of ". $_[0]->datetime;
            $_[0]->truncate( to => 'month' );
            $_[0]->add( months => 1 );
            # warn " got ".$_[0]->datetime."\n" if $_[0] <= $t1;
            return $_[0] if $_[0] <= $t1;
            # warn " got Future\n";
            return DateTime::Infinite::Future->new;
        };
    my $_previous_month = sub {
            # warn "previous of ". $_[0]->datetime;
            # warn " got ".$t1->datetime."\n" if $_[0] > $t1;
            return $t1->clone if $_[0] > $t1;
            my $dt = $_[0]->clone;
            $_[0]->truncate( to => 'month' );
            $_[0]->subtract( months => 1 ) if $_[0] == $dt;
            # warn " got ".$_[0]->datetime."\n";
            return $_[0];
        };

    my $months = DateTime::Set->from_recurrence(
        next =>     $_next_month,
        previous => $_previous_month,
        # detect_bounded => 1,
    );

    $res = $months->min;
    # $res = $res->ymd if ref($res);
    is( ref($res), 'DateTime::Infinite::Past',
        "min()" );

    $res = $months->max;
    $res = $res->ymd if ref($res);
    is( $res, '1810-08-01',   
        "max()" );

    is( $months->count, undef, "count" );

}


{
    # diag( "monthly from 1810-08-01 until 1810-11-01" );

    my $_next_month = sub {
            # warn "next of ". $_[0]->datetime;
            $_[0]->truncate( to => 'month' );
            $_[0]->add( months => 1 );
            return $t1->clone if $_[0] < $t1;
            return $_[0] if $_[0] <= $t2;
            return DateTime::Infinite::Future->new;
        };
    my $_previous_month = sub {
            # warn "previous of ". $_[0]->datetime;
            my $dt = $_[0]->clone;
            $_[0]->truncate( to => 'month' );
            $_[0]->subtract( months => 1 ) if $_[0] == $dt;
            return DateTime::Infinite::Past->new if $_[0] < $t1;
            return $_[0] if $_[0] <= $t2;
            return $t2->clone;
        };

    my $months = DateTime::Set->from_recurrence(
        next =>     $_next_month,
        previous => $_previous_month,
        # detect_bounded => 1,
    );

    $res = $months->min;
    $res = $res->ymd if ref($res);
    is( $res, '1810-08-01',
        "min()" );

    $res = $months->max;
    $res = $res->ymd if ref($res);
    is( $res, '1810-11-01',
        "max()" );

    is( $months->count, 4, "count" );

}


{
    # diag( "lists and recurrences are interchangeable" );

    my $set = DateTime::Set->from_datetimes(
        dates => [ $t0, $t1, $t2 ]
    );


    my $months = DateTime::Set->from_recurrence(
        next =>  sub{ 
            my $dt = $set->next( $_[0] ); 
            defined $dt ? $dt : DateTime::Infinite::Future->new;
        },
        previous => sub{ 
            my $dt = $set->previous( $_[0] ); 
            defined $dt ? $dt : DateTime::Infinite::Past->new;
        },
        # detect_bounded => 1,
    );

    $res = $months->min;
    $res = $res->ymd if ref($res);
    is( $res , '1810-05-01',
        "min()" );

    $res = $months->max;
    $res = $res->ymd if ref($res);
    is( $res, '1810-11-01',   
        "max()" );

    is( $months->count, 3, "count" );

}


1;

