#!/usr/bin/perl -w

use strict;

use Test::More tests => 34;
use DateTime;
use DateTime::Incomplete;

my $UNDEF_CHAR = 'x';
my $UNDEF4 = $UNDEF_CHAR x 4;
my $UNDEF2 = $UNDEF_CHAR x 2;

{
    # Tests for new(), set(), datetime()

    my $base = DateTime->new( year => 1970 );

    my $dti;
    my $dt = DateTime->new( year => 2003 );
    my $str = $dt->datetime;
    my $dti_clone;
    my $str_clone;
    my $dti_half;
    my $dti_complete;
    my $str_complete;

    $dti = DateTime::Incomplete->new( 
        year =>   $dt->year,
        month =>  $dt->month,
        day =>    $dt->day,
        hour =>   $dt->hour,
        minute => $dt->minute,
        second => $dt->second,
        nanosecond => $dt->nanosecond,
        base =>   $base,
    );
    $dti_complete = $dti->clone;  # a fully-defined datetime
    $str_complete = $dti->datetime;

    is( $dti->datetime , $dt->datetime, 
        'new() matches DT->new' );


    is( $dti->has_year , 1,
        'has year' );

    $dti->set( year => undef );
    $str =~ s/^2003/$UNDEF4/;
    is( $dti->datetime , $str,
        'undef year' );

    is( $dti->has_year , 0,
        'has no year' );

    $dti->set( month => undef );
    $str =~ s/-01-/-$UNDEF2-/;
    is( $dti->datetime , $str,
        'undef month' );

    # Tests clone()

    $dti_clone = $dti->clone;
    $str_clone = $str;

    $dti->set( day => undef );
    $str =~ s/-01/-$UNDEF2/;
    is( $dti->datetime , $str,
        'undef day' );

    is( $dti_clone->datetime , $str_clone,
        'clone has day' );

    # end: Tests clone()


    # Tests is_undef, false

    is( $dti->is_undef , 0,
        'not undef' );


    # Tests to_datetime

    $dti_half = $dti->clone;   # a half-defined datetime
    my $dt2 = $dti_half->to_datetime( base => $dt );
    is( $dt->datetime , $dt2->datetime,
        'to_datetime' );

    my $dti2 = $dti_half->clone;
    $dti2->set_base( $dt );
    $dt2 = $dti2->to_datetime;
    is( $dt->datetime , $dt2->datetime,
        'to_datetime + set_base' );

    # Tests contains

    is( $dti->contains( $dt2 ), 1,
        'contains' );
    $dt2->add( hours => 1 );
    is( $dti->contains( $dt2 ), 0,
        'does not contain' );


    # undef time

    $dti->set( hour => undef );
    $str =~ s/00:/$UNDEF2:/;
    is( $dti->datetime , $str,
        'undef hour' );

    $dti->set( minute => undef );
    $str =~ s/:00:/:$UNDEF2:/;
    is( $dti->datetime , $str,
        'undef minute' );

    $dti->set( second => undef );
    $str =~ s/:00/:$UNDEF2/;
    is( $dti->datetime , $str,
        'undef second' );

    is( $dti->nanosecond , $dt->nanosecond,
        'def nanosecond' );
    $dti->set( nanosecond => undef );
    ok( ! defined( $dti->nanosecond ),
        'undef nanosecond' );


    # Tests is_undef, true

    is( $dti->is_undef , 1,
        'is undef' );

    # TESTS TODO:
    # set_time_zone, time_zone
    #   -- together with contains() and to_datetime()



  # Tests to_recurrence()

    my $set;

    # a complete definition yields a DT::Set with one element

    $set = $dti_complete->to_recurrence;
    is( $set->min->datetime , $str_complete,
        'complete definition gives a single date' );

    # no day

    my $dti_no_day = $dti_complete->clone;
    $dti_no_day->set( day => undef );   # 2003-01-xxT00:00:00
    $set = $dti_no_day->to_recurrence;
    is( $set->min->datetime , '2003-01-01T00:00:00',
        'first day in 2003-01' );
    is( $set->max->datetime , '2003-01-31T00:00:00',
        'last day in 2003-01' );

    # no year, no day, no minute

    {
      $dti_no_day = $dti_complete->clone;
      $dti_no_day->set( year => undef );  
      $dti_no_day->set( month => 12 );   
      $dti_no_day->set( day => 24 );         # xx-12-24T00:00:00
      $dti_no_day->set( minute => undef );   # xx-12-24T00:xx:00


      # to_recurrence

      $set = $dti_no_day->to_recurrence;

      my $dt = DateTime->new( year => 2003 );

      is( $set->next( $dt )->datetime , '2003-12-24T00:00:00',
          'next xmas - recurrence' );
      is( $set->previous( $dt )->datetime , '2002-12-24T00:59:00',
          'last xmas - recurrence' );

      # next

      is( $dti_no_day->next( $dt )->datetime , '2003-12-24T00:00:00',
          'next xmas' );
      $dt->subtract( seconds => 10 );
      is( $dti_no_day->next( $dt )->datetime , '2003-12-24T00:00:00',
          'next xmas again' );
      $dt = $dti_no_day->next( $dt );
      is( $dti_no_day->next( $dt )->datetime , '2003-12-24T00:00:00',
          'next xmas with "equal" value' );

      $dt->add( seconds => 20 );
      is( $dti_no_day->next( $dt )->datetime , '2003-12-24T00:01:00',
          'next xmas with "during" value' );

      $dt->add( days => 1 );
      is( $dti_no_day->next( $dt )->datetime , '2004-12-24T00:00:00',
          'next xmas with "after" value' );

      is( $dti_no_day->previous( $dt )->datetime , '2003-12-24T00:59:00',
          'previous xmas '.$dt->datetime.' with "after" value' );

      $dt->subtract( days => 1 );
      is( $dti_no_day->previous( $dt )->datetime , '2003-12-24T00:00:00',
          'previous xmas '.$dt->datetime.' with "during" value' );

      $dt->subtract( seconds => 10 );
      is( $dti_no_day->previous( $dt )->datetime , '2003-12-24T00:00:00',
          'previous xmas '.$dt->datetime.' with "equal" value' );

      $dt->subtract( hours => 1 );
      is( $dti_no_day->previous( $dt )->datetime , '2002-12-24T00:59:00',
          'previous xmas '.$dt->datetime.' with "before" value' );

      is( $dti_no_day->closest( $dt )->datetime , '2003-12-24T00:00:00',
          'closest xmas '.$dt->datetime.'' );

      $dt->subtract( months => 10 );
      is( $dti_no_day->closest( $dt )->datetime , '2002-12-24T00:59:00',
          'closest xmas '.$dt->datetime.'' );

  # End: Tests to_recurrence()

  };

}


1;

