#!perl

# Test script for rise and set times
# Test using both DateTime and Time::Piece

use strict;
use Test::More tests => 295;
use Test::Number::Delta;
use Time::Piece qw/ :override /;
use DateTime;
use DateTime::TimeZone;

# Need this since the constants from Astro::Coords will
# not be defined if we only require
BEGIN { use_ok('Astro::Coords') };
require_ok('Astro::PAL');
require_ok('Astro::Telescope');

# reference time zones
my $UTC = new DateTime::TimeZone( name => 'UTC');
my $HST = new DateTime::TimeZone( name => 'US/Hawaii');

# telescope
my $tel = new Astro::Telescope( 'JCMT' );

# reference time (basically locks us into a day)
# Wed Jul 15 14:46:44 2003 UT
my $epoch = 1058280404;
my $timepiece = gmtime( $epoch );
my $datetime  = DateTime->from_epoch( epoch => $epoch );

for my $date ($timepiece, $datetime) {

  # The Sun
  my $c = new Astro::Coords( planet => 'sun' );
  $c->datetime( $date );
  $c->telescope( $tel );

#print $c->status;

# According to http://aa.usno.navy.mil/cgi-bin/aa_pap.pl
# [http://aa.usno.navy.mil/data/]
# Long = -155 29 Lat = 19 49
# Sun set is 19:04 and civil twilight is 19:28
# Sun rise is 05:51 and civil twilight start is 05:27
# Midday is 12:28  [22:28 UT]

  my $mtime = $c->meridian_time();
  my $civtwiri = $c->rise_time( horizon => Astro::Coords::CIVIL_TWILIGHT );
  my $rise = $c->rise_time( horizon => Astro::Coords::SUN_RISE_SET );
  my $set  = $c->set_time( horizon => Astro::Coords::SUN_RISE_SET );
  my $civtwi = $c->set_time( horizon => Astro::Coords::CIVIL_TWILIGHT );

  print "# SUN:\n";
  print "#  Local start civil twi:" . localtime($civtwiri->epoch)."\n";
  test_time( $civtwiri, [2003,7,15,5,27], "Civil twilight start", $HST);

  print "#  Local Rise time:      " . localtime($rise->epoch) ."\n";
  test_time( $rise, [2003,7,15,5, 51], "Sun rise", $HST);

  print "#  Local Transit time:   " . localtime($mtime->epoch) ."\n";
  test_time( $mtime, [2003,7,15,12,28],"Noon", $HST);

  print "#  Local Set time:       " . localtime($set->epoch) ."\n";
  test_time( $set, [2003,7,15,19,4], "Sun set", $HST);

  print "#  Local end Civil twi:  " . localtime($civtwi->epoch) ."\n";
  test_time( $civtwi, [2003,7,15,19,28], "Civil twilight end", $HST);

  print $c->status;

# Now try the moon
# USNO:
#       Moonrise                  20:27 on preceding day
#       Moon transit              02:05
#       Moonset                   07:46
#       Moonrise                  21:13
#       Moonset                   08:45 on following day

  my $moon = new Astro::Coords( planet => 'moon');
  $moon->datetime( $date );
  $moon->telescope( $tel );

  $mtime = $moon->meridian_time(nearest=>1);

  # use the default horizon for the moon
  $rise = $moon->rise_time();
  $set  = $moon->set_time();

  print "#  MOON\n";
  print "# For local time ". localtime($moon->datetime->epoch) ."\n";
  print "# Meridian: ".localtime($mtime->epoch)." [cf. Jul 15th 02:05]\n";
  print "# Rise time: ".localtime($rise->epoch)." [cf. Jul 15th 21:13]\n";
  print "# Set time: ".localtime($set->epoch)." [cf. Jul 15th 07:46]\n";
  test_time( $mtime, [2003,7,15,2,5], "Moon transit", $HST);
  test_time( $rise, [2003,7,15,21,13], "Moon rise", $HST);
  test_time( $set, [2003,7,15,7,46], "Moon set", $HST);
  print $moon->status;

}

# Do some tests for a specific date for different elevations
# Date in question is 2004-11-20 at longitude=0, latitude=0

# This table is an array of coordinates.
# The value points to an array ref of the hour offset, elevation and azimuth
# for that hour.

# "Fudged" indicates that the tests have been modified for some discrepancy
# between the USNO tables. This discrepancy is always less than 0.06 degrees
# in elevation (equivalent to the error in time given in the table)
my @moon_data = (
                 [0, 10.4 , 257.1, 's'],
                 [1, -3.8 , 257.6, 's'],
                 [13, -3.7 , 99.5,  'r'],
                 [14 ,10.7 , 99.4,  'r'],
                 [15 ,25.1 , "100.0", 'r'],
                 [16 ,39.5 , 101.4, 'r'],  ## Fudged from 39.6 (18 seconds)
                 [17 ,53.9 , 104.7, 'r'],
                 [18 , "68.0", 112.8, 'r'],
                 [19 , 80.1, 145.3, 'r'],  ## Fudged from 80.2 (18 seconds)
                 [20 , "78.0", 229.1, 's'],
                 [21 , "65.0", 251.9, 's'],
                 [22 , 50.7, 258.4, 's'],  ## Fudged from 50.8 (14 seconds)
                 [23 , 36.3, 261.3, 's'],
                );

my @sun_data = (
                [ 5,   -10.7,       110.1, 'r'],
        #       [ 6,     3.6,       109.8, 'r'], # seems to come out as 3.4
                [ 7,    17.4,       110.8, 'r'], ## Fudged from 17.5 (14 sec)
                [ 8,    31.4,       113.4, 'r'],
                [ 9,    44.9,       118.6, 'r'],
                [10,    57.4,       '129.0', 'r'],
                [11,    67.2,       151.2, 'r'],
                [12,    69.9,       189.8, 's'],
                [13,    63.1,       221.4, 's'],
                [14,    51.6,       236.9, 's'],
                [15,    38.5,       244.3, 's'],
                [16,    24.8,       '248.0', 's'],
                [17,    10.8,       249.8, 's'],
                [18,    -3.3,       250.1, 's'],
               );

my $refdate = DateTime->new( year => 2004,
                             month => 11,
                             day => 20,
                             time_zone => 'UTC');

my $moon = new Astro::Coords( planet => 'moon' );
my $sun  = new Astro::Coords( planet => 'sun' );
$moon->datetime( $refdate );
$sun->datetime( $refdate );

my %data = (
            moon => { coords => $moon,
                      data => \@moon_data,
                      rise => [2004,11,20,13,12],
                      set => [2004,11,20,0,47],
                      transit => [2004,11,20,19,23],
                    },
            sun => { coords => $sun,
                     data => \@sun_data,
                     rise => [2004,11,20,5,42],
                     set => [2004,11,20,17,49],
                     transit => [2004,11,20,11,46],
                   },
           );

for my $targ (sort keys %data) {
  print "# Testing elevations for target $targ\n";

  # coordinate object
  my $c = $data{$targ}->{coords};

  # rise, set and transit
  my $transit = $c->meridian_time;
  my $set     = $c->set_time;
  my $rise    = $c->rise_time;

  print "# Transit calculated: ". $transit->datetime ."\n";
  test_time( $transit, $data{$targ}->{transit}, "$targ transit", $UTC);
  print "# Rise calculated: ". $rise->datetime ."\n";
  test_time( $rise, $data{$targ}->{rise}, "$targ rise", $UTC);
  print "# Set calculated: ". $set->datetime ."\n";
  test_time( $set, $data{$targ}->{set}, "$targ set", $UTC);

  # Loop over data table
  for my $m (@{ $data{$targ}->{data} }) {
    my $dt = $refdate->clone->add( hours => $m->[0] );
    $c->datetime( $dt );

    # We only have USNO tables to 0.1 deg accuracy
    print "# El: ". $c->el(format=>'deg') ." cf. ". $m->[1] ."\n";
    delta_within($c->el(format => 'deg'), $m->[1], 0.1, "Test elevation");
    delta_within($c->az(format => 'deg'), $m->[2], 0.1, "Test azimuth");

    # for the rise times and set times, step back a minute to make sure
    # we get to the correct "next" event (given the minute accuracy in the
    # reference tables this is important). This is relevant for the first
    # event of the day
    $dt = $refdate->clone->subtract( minutes => 1 );
    $c->datetime( $dt );

    my $time;
    if ($m->[3] eq 'r') {
      $time = $c->rise_time(horizon => ( $m->[1] * Astro::PAL::DD2R) );
    } else {
      $time = $c->set_time( horizon => ( $m->[1] * Astro::PAL::DD2R) );
    }

    if (defined $time) {
      print "# Time: ". $time->datetime ."\n";

      # Want the answer in decimal hours so that rounding can be
      # implemented
      my $dechr = $time->hour + ( $time->minute() / 60 ) +
        ( $time->second() / 3600 );

      # force to 1 decimal place and then convert back to a number
      # for comparison
      my $rounded = 0+sprintf("%.1f",$dechr);
      $rounded = 0 if $rounded == 24;

      my $day = $time->day;
      $day ++ if $dechr > 23.9; # round to next day

      is( $time->year, $refdate->year, "Check year");
      is( $time->month, $refdate->month, "Check month");
      is( $day, $refdate->day, "Check day");
      is( $rounded, $m->[0], "Test hour for this elevation");

    } else {
      ok(0, "Unable to determine time for elevation ". $m->[1]);
    }

  }
}

# Test edge case for moon that doesn't set
# This test from Beat Vontobel.
my $moon2 = new Astro::Coords( planet => 'MOON' );

my $place = new Astro::Telescope(Name => 'test',
                                 Long => 18.4 * Astro::PAL::DD2R,
                                 Lat =>  64.80 * Astro::PAL::DD2R,
                                 Alt =>  0);

my $time = DateTime->new(year => 2005,
                         month => 01,
                         day => 20,
                         hour => 8,
                         minute => 11,
                         second => 41,
                         time_zone => $UTC
                        );

$moon2->telescope($place);
$moon2->datetime($time);

my $rise = $moon2->rise_time();
test_time( $rise, [2005,1,20,8,12], "Moon rise", $UTC);
my $transit = $moon2->meridian_time();
test_time( $transit, [2005,1,20,19,19], "Moon transit", $UTC);
my $set = $moon2->set_time();
is($set, undef, "Moon does not set");

# and another from Beat Vontobel
$time = DateTime->new ( year => 2005,
                        month =>   1,
                        day =>     7,
                        hour =>    9,
                        minute =>  2,
                        second =>  24,
                        time_zone => $UTC
                      );

$moon2->datetime($time);
$rise = $moon2->rise_time(nearest => 1);

# Should be 05:57. Off by 49 seconds
test_time( $rise, [2005,1,7,5,58], "Moon rise", $UTC);
$transit = $moon2->meridian_time(nearest => 1);
test_time( $transit, [2005,1,7,7,37], "Moon transit", $UTC);
$set = $moon2->set_time(nearest => 1);

# Should be 09:03. Off by 38 seconds
test_time( $set, [2005,1,7,9,2], "Moon set", $UTC);


exit;

# dates to be tested are in UTC but answer is given in HST
sub test_time {
  my ($ref, $answer, $text, $tz) = @_;
  my @methods = qw/ year month day hour minute /;


  my $dt = new DateTime( year => $answer->[0],
                         month => $answer->[1],
                         day => $answer->[2],
                         hour => $answer->[3],
                         minute => $answer->[4],
                         time_zone => $tz,
                       );

  my $localref;
  $localref = DateTime->from_epoch( epoch => $ref->epoch,
                                    time_zone => $tz,
                                  ) if defined $ref;

  print "# Cf ".(defined $localref ? $localref : 'undef' )." with $dt\n";
  my $sec = (defined $localref ? $localref->second : 0);
  for my $method ( @methods ) {
    my $comp = (defined $localref ? $localref->$method : undef );
    # round up seconds
    $comp++ if ($method eq 'minute' && $sec >= 30);

    is($comp, $dt->$method, "$text: $method  [".$dt->datetime."]");
  }
#  is($ref->min, $answer->[1], "$text: minute [".$dt->datetime."]");

}
