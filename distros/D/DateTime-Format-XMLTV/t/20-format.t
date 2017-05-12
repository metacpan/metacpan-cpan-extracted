#! /usr/bin/perl
#---------------------------------------------------------------------
# Test formatting XMLTV dates
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More 0.88;            # done_testing

use DateTime::Format::XMLTV;

my $utc = DateTime::TimeZone->new(name => 'UTC');

#---------------------------------------------------------------------
my @datetimes = (
  ['20110102060000 -0600', '-0600', 2011,  1,  2,  6],
  ['20110102060000 +0930', '+0930', 2011,  1,  2,  6],
  ['20110102060000 +0000',    $utc, 2011,  1,  2,  6],
  ['20010203040506 +0000',    $utc, 2001,  2,  3,  4,  5,  6],
  ['19990101000000 +0000',    $utc, 1999],
);

plan tests => 2 * @datetimes;

for my $test (@datetimes) {
  my ($expected, $tz, $year, $month, $day, $hour, $min, $sec) = @$test;

  my $dt = DateTime->new(
    year => $year, month => $month||1, day => $day||1,
    hour => $hour||0, minute => $min||0, second => $sec||0,
    time_zone => $tz
  );

  is(DateTime::Format::XMLTV->format_datetime($dt), $expected,
     "datetime $expected");

  substr($expected, 8) = '';    # Truncate to date portion

  is(DateTime::Format::XMLTV->format_date($dt), $expected, "date $expected");
} # end for each $test in @datetimes

done_testing;
