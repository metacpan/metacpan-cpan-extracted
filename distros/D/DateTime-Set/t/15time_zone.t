#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 14;

use DateTime;
use DateTime::Set;

#======================================================================
# TIME ZONE TESTS
#====================================================================== 

my $t1 = new DateTime( year => '2001', month => '11', day => '22' );
my $t2 = new DateTime( year => '2002', month => '11', day => '22' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );


my $s2 = $s1->set_time_zone( 'Asia/Taipei' );

is( $s2->min->datetime, '2001-11-22T00:00:00', 
    'got 2001-11-22T00:00:00 - min' );

is( $s2->min->time_zone->name, 'Asia/Taipei', 
    'got time zone name from set' );

my $span1 = DateTime::Span->from_datetimes( start => $t1, end => $t2 );
$span1->set_time_zone( 'America/Sao_Paulo' );
my $span2 = $span1->clone;

$span1->set_time_zone( 'Asia/Taipei' );

is( $span1->start->datetime, '2001-11-22T10:00:00',
    'got 2001-11-22T10:00:00 - min' );
is( $span1->end->datetime, '2002-11-22T10:00:00',
    'got 2002-11-22T10:00:00 - max' );

# check for immutability
is( $span2->start->datetime, '2001-11-22T00:00:00',
    'got 2001-11-22T00:00:00 - min' );
is( $span2->end->datetime, '2002-11-22T00:00:00',
    'got 2002-11-22T00:00:00 - max' );

# recurrence
{
my $months = DateTime::Set->from_recurrence(
                 recurrence => sub {
                     my $tz = $_[0]->time_zone;
                     $_[0]->set_time_zone( 'floating' );
                     $_[0]->truncate( to => 'month' )->add( months => 1 );
                     $_[0]->set_time_zone( $tz );
                     $_[0];
                 }
             )
             ->set_time_zone( 'Asia/Taipei' );

my $str = $months->next( $t1 )->datetime . ' ' .
          $months->next( $t1 )->time_zone_long_name;

my $original = $t1->datetime . ' ' .
               $t1->time_zone_long_name;

is( $str, '2001-12-01T00:00:00 Asia/Taipei', 'recurrence with time zone' );
is( $original, '2001-11-22T00:00:00 floating', 'does not mutate arg' );


{
  my $str;

  my $dt_floating = new DateTime( 
      year => 2001, month => 11, day => 1
  );
  my $dt_with_tz  = $dt_floating->clone->set_time_zone( 'America/Sao_Paulo' );

  my $set_floating = DateTime::Set->from_recurrence(
       recurrence => sub {
                     my $tz = $_[0]->time_zone;
                     $_[0]->set_time_zone( 'floating' );
                     $_[0]->truncate( to => 'month' )->add( months => 1 );
                     $_[0]->set_time_zone( $tz );
                     $_[0];
                  }
  );
  my $set_with_tz = $set_floating->clone->set_time_zone( 'Asia/Taipei' );

  # tests with the "next" method

  # floating set => floating dt
      is( $set_floating->next( $dt_floating )->
          strftime( "%FT%H:%M:%S %{time_zone_long_name}"),
          '2001-12-01T00:00:00 floating',
          'recurrence without time zone, arg without time zone' );
  # tz set => floating dt
      is( $set_with_tz->next( $dt_floating )->
          strftime( "%FT%H:%M:%S %{time_zone_long_name}"),
          '2001-12-01T00:00:00 Asia/Taipei',
          'recurrence with time zone, arg without time zone' );
  # floating set => tz dt
      is( $set_floating->next( $dt_with_tz )->
          strftime( "%FT%H:%M:%S %{time_zone_long_name}"),
          '2001-12-01T00:00:00 America/Sao_Paulo',
          'recurrence with time zone, arg without time zone' );

  # TODO: {
  #  local $TODO = "Time zone settings do not backtrack";
  # bug reported by Tim Mueller-Seydlitz

  # tz set => tz dt
      is( $set_with_tz->next( $dt_with_tz )->
          strftime( "%FT%H:%M:%S %{time_zone_long_name}"),
          # = '2001-12-01T00:00:00 Asia/Taipei',
          '2001-11-30T14:00:00 America/Sao_Paulo',
          'recurrence with time zone, arg with time zone' );
  # } 

    # TODO: limit set_floating with a start=>dt_floating;
    #       ask for next( dt_with_tz_before_start ) 
    #       and next( dt_with_another_tz_before_start )
    #       and next( dt_floating_before_start )
    #       and check for caching problems

}


# set locale, add duration
is ( $months->clone->add( days => 1 )->
              next( $t1 )->
              strftime( "%a" ), 'Sun', 
     'default locale' );

is ( $months->clone->add( days => 1 )->
              set( locale => 'en_US' )->
              next( $t1 )->
              strftime( "%a" ), 
     'Sun', 
     'new locale' );
}

1;

