#!/usr/bin/perl -w
# -*- perl -*-
#
#     Test script for Astro::Sunrise
#     Copyright (C) 2015, 2017, 2021 Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<https://dev.perl.org/licenses/artistic.html>
#     and L<https://www.gnu.org/licenses/gpl-1.0.html>.
#
#     Here is the summary of GPL:
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 1, or (at your option)
#     any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software Foundation,
#     Inc., <https://www.fsf.org/>.
#

use strict;
use warnings;
use POSIX qw(floor ceil);
use Test::More;
use Astro::Sunrise;

my $check_warn;

BEGIN {
  $check_warn = 1;
  eval "use Test::Warn";
  $check_warn = 0
    if $@;
}

my @tests = load_data();
my ($long, $lat, $offset);
my $fudge = 1; # in minutes

plan tests => (2 + $check_warn) * scalar @tests;

for (@tests) {
  my ($yyyy, $mm, $dd, $loc, $lat_d, $lat_m, $lat_x, $lon_d, $lon_m, $lon_x, $alt, $upper_limb, $polar_night, $day_and_night, $polar_day, $expect_r, $expect_s)
     = $_ =~ /(\d+)\s+(\d+)\s+(\d+)     # date in YYYY MM DD format $1 $2 $3
	     \s+(\w+)                   # location $4
	     \s+(\d+)\s+(\d+)\s+(\w)    # latitude $5 $6 $7
	     \s+(\d+)\s+(\d+)\s+(\w)    # longitude $8 $9 $10
	     \s+(\S+)                   # altitude $11
	     \s+(\d)                    # upper limb $12
	     \s+(\d)\s+(\d)\s+(\d)      # polar night $13, day and night $14, polar day $15
	     \s+sunrise:\s+([-\d]+:\d+) # sunrise $16
	     \s+sunset:\s+(\d+:\d+)/x;  # sunset $17
  if ( $lat_x eq 'N' ) {
    $lat = sprintf( "%.3f", ( $lat_d + ( $lat_m / 60 ) ) );
  }
  elsif ( $lat_x eq 'S' ) {
    $lat = sprintf( "%.3f", -( $lat_d + ( $lat_m / 60 ) ) );
  }

  if ( $lon_x eq 'E' ) {
    $long = sprintf( "%.3f", $lon_d + ( $lon_m / 60 ) );
  }
  elsif ( $lon_x eq 'W' ) {
    $long = sprintf( "%.3f", -( $lon_d + ( $lon_m / 60 ) ) );
  }

  if ($long < 0) {
    $offset = ceil( $long / 15 );
  }
  elsif ($long > 0) {
    $offset = floor( $long /15 );
  }
  else {
    $offset = 0;
  }
  if ($check_warn) {
    if ($polar_night) {
      warning_like { sunrise ( { year => $yyyy, month => $mm, day => $dd, tz => 0,
				 lon => $long, lat => $lat, alt => $alt, upper_limb => $upper_limb, } ); }
		   qr/sun never rises!!/i,
		   "Polar night at $loc on $yyyy-$mm-$dd";
    }
    if ($day_and_night) {
      warning_is { sunrise ( { year => $yyyy, month => $mm, day => $dd, tz => 0,
			       lon => $long, lat => $lat, alt => $alt, upper_limb => $upper_limb, } ); }
		 undef, # which means "no warning"
		 "Day and night at $loc on $yyyy-$mm-$dd";
    }
    if ($polar_day) {
      warning_like { sunrise ( { year => $yyyy, month => $mm, day => $dd, tz => 0,
				 lon => $long, lat => $lat, alt => $alt, upper_limb => $upper_limb, } ); }
		   qr/sun never sets!!/i,
		   "Polar day at $loc on $yyyy-$mm-$dd";
    }
  }
  my ($sunrise, $sunset)  = sunrise ( { year => $yyyy, month => $mm, day => $dd, tz => 0,
				 lon => $long, lat => $lat, alt => $alt, upper_limb => $upper_limb, polar => 'retval', } );
  if ($polar_night) {
    is ($sunrise, 'night', "Polar night at $loc on $yyyy-$mm-$dd");
    is ($sunset , 'night', "Polar night at $loc on $yyyy-$mm-$dd");
  }
  if ($day_and_night) {
    my $exp_h = fudge_h($expect_r, $fudge);
    my $exp_l = fudge_l($expect_r, $fudge);
    ok ($sunrise ge $exp_l && $sunrise le $exp_h
         , "Sunrise for $loc $yyyy-$mm-$dd  $alt $upper_limb $exp_l $sunrise $exp_h");
    $exp_h = fudge_h($expect_s, $fudge);
    $exp_l = fudge_l($expect_s, $fudge);
    ok ($sunset ge $exp_l && $sunset le $exp_h
         , "Sunset  for $loc $yyyy-$mm-$dd  $alt $upper_limb $exp_l $sunset $exp_h");
  }
  if ($polar_day) {
    is ($sunrise, 'day', "Polar day at $loc on $yyyy-$mm-$dd");
    is ($sunset , 'day', "Polar day at $loc on $yyyy-$mm-$dd");
  }
}

sub fudge_h {
  my ($exp, $fudge) = @_;
  my ($hh, $mn) = $exp =~ /^(\d\d):(\d\d)$/;
  $mn += $fudge;
  if ($mn > 59) {
    $hh ++;
    $mn -= 60;
  }
  if ($hh > 23) {
    $hh -= 24;
  }
  elsif ($hh < 0) {
    $hh += 24;
  }
  return sprintf("%02d:%02d", $hh, $mn);
}

sub fudge_l {
  my ($exp, $fudge) = @_;
  my ($hh, $mn) = $exp =~ /^(\d\d):(\d\d)$/;
  $mn -= $fudge;
  if ($mn < 0) {
    $hh --;
    $mn += 60;
  }
  if ($hh > 23) {
    $hh -= 24;
  }
  elsif ($hh < 0) {
    $hh += 24;
  }
  return sprintf("%02d:%02d", $hh, $mn);
}

sub load_data {
    return split "\n", <<'EOD';
2013  1  1 North_Pole           89 59 N   0  0 E 0          0 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E 0          1 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E -0.583     0 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E -0.583     1 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E -0.833     0 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E -0.833     1 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E -12        0 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E -12        1 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E -18        0 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 North_Pole           89 59 N   0  0 E -18        1 1 0 0 sunrise: 12:03 sunset: 12:03
2013  3 21 North_Pole           89 59 N   0  0 E 0          0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E 0          1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E -0.583     0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E -0.583     1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E -0.833     0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E -0.833     1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E -12        0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E -12        1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E -18        0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 North_Pole           89 59 N   0  0 E -18        1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  6 21 North_Pole           89 59 N   0  0 E 0          0 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E 0          1 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E -0.583     0 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E -0.583     1 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E -0.833     0 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E -0.833     1 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E -12        0 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E -12        1 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E -18        0 0 0 1 sunrise: 00:01 sunset: 24:01
2013  6 21 North_Pole           89 59 N   0  0 E -18        1 0 0 1 sunrise: 00:01 sunset: 24:01
2013  8 31 North_Pole           89 59 N   0  0 E 0          0 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E 0          1 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E -0.583     0 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E -0.583     1 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E -0.833     0 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E -0.833     1 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E -12        0 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E -12        1 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E -18        0 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 North_Pole           89 59 N   0  0 E -18        1 0 0 1 sunrise: 00:00 sunset: 24:00
2013  9 21 North_Pole           89 59 N   0  0 E 0          0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E 0          1 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E -0.583     0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E -0.583     1 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E -0.833     0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E -0.833     1 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E -12        0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E -12        1 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E -18        0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 North_Pole           89 59 N   0  0 E -18        1 0 0 1 sunrise: -1:53 sunset: 23:53
2013 12 31 North_Pole           89 59 N   0  0 E 0          0 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E 0          1 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E -0.583     0 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E -0.583     1 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E -0.833     0 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E -0.833     1 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E -12        0 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E -12        1 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E -18        0 1 0 0 sunrise: 12:03 sunset: 12:03
2013 12 31 North_Pole           89 59 N   0  0 E -18        1 1 0 0 sunrise: 12:03 sunset: 12:03
2013  1  1 Halley_Base          75 35 S  26 39 W 0          0 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W 0          1 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W -0.583     0 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W -0.583     1 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W -0.833     0 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W -0.833     1 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W -12        0 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W -12        1 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W -18        0 0 0 1 sunrise: 01:50 sunset: 25:50
2013  1  1 Halley_Base          75 35 S  26 39 W -18        1 0 0 1 sunrise: 01:50 sunset: 25:50
2013  3 21 Halley_Base          75 35 S  26 39 W 0          0 0 1 0 sunrise: 08:00 sunset: 19:46
2013  3 21 Halley_Base          75 35 S  26 39 W 0          1 0 1 0 sunrise: 07:56 sunset: 19:51
2013  3 21 Halley_Base          75 35 S  26 39 W -0.583     0 0 1 0 sunrise: 07:51 sunset: 19:56
2013  3 21 Halley_Base          75 35 S  26 39 W -0.583     1 0 1 0 sunrise: 07:46 sunset: 20:00
2013  3 21 Halley_Base          75 35 S  26 39 W -0.833     0 0 1 0 sunrise: 07:47 sunset: 20:00
2013  3 21 Halley_Base          75 35 S  26 39 W -0.833     1 0 1 0 sunrise: 07:42 sunset: 20:04
2013  3 21 Halley_Base          75 35 S  26 39 W -12        0 0 1 0 sunrise: 04:19 sunset: 23:28
2013  3 21 Halley_Base          75 35 S  26 39 W -12        1 0 1 0 sunrise: 04:11 sunset: 23:35
2013  3 21 Halley_Base          75 35 S  26 39 W -18        0 0 0 1 sunrise: 01:53 sunset: 25:53
2013  3 21 Halley_Base          75 35 S  26 39 W -18        1 0 0 1 sunrise: 01:53 sunset: 25:53
2013  6 21 Halley_Base          75 35 S  26 39 W 0          0 1 0 0 sunrise: 13:48 sunset: 13:48
2013  6 21 Halley_Base          75 35 S  26 39 W 0          1 1 0 0 sunrise: 13:48 sunset: 13:48
2013  6 21 Halley_Base          75 35 S  26 39 W -0.583     0 1 0 0 sunrise: 13:48 sunset: 13:48
2013  6 21 Halley_Base          75 35 S  26 39 W -0.583     1 1 0 0 sunrise: 13:48 sunset: 13:48
2013  6 21 Halley_Base          75 35 S  26 39 W -0.833     0 1 0 0 sunrise: 13:48 sunset: 13:48
2013  6 21 Halley_Base          75 35 S  26 39 W -0.833     1 1 0 0 sunrise: 13:48 sunset: 13:48
2013  6 21 Halley_Base          75 35 S  26 39 W -12        0 0 1 0 sunrise: 11:12 sunset: 16:24
2013  6 21 Halley_Base          75 35 S  26 39 W -12        1 0 1 0 sunrise: 11:05 sunset: 16:31
2013  6 21 Halley_Base          75 35 S  26 39 W -18        0 0 1 0 sunrise: 09:06 sunset: 18:30
2013  6 21 Halley_Base          75 35 S  26 39 W -18        1 0 1 0 sunrise: 09:01 sunset: 18:35
2013  8 31 Halley_Base          75 35 S  26 39 W 0          0 0 1 0 sunrise: 10:08 sunset: 17:25
2013  8 31 Halley_Base          75 35 S  26 39 W 0          1 0 1 0 sunrise: 10:02 sunset: 17:30
2013  8 31 Halley_Base          75 35 S  26 39 W -0.583     0 0 1 0 sunrise: 09:56 sunset: 17:37
2013  8 31 Halley_Base          75 35 S  26 39 W -0.583     1 0 1 0 sunrise: 09:51 sunset: 17:42
2013  8 31 Halley_Base          75 35 S  26 39 W -0.833     0 0 1 0 sunrise: 09:51 sunset: 17:41
2013  8 31 Halley_Base          75 35 S  26 39 W -0.833     1 0 1 0 sunrise: 09:46 sunset: 17:46
2013  8 31 Halley_Base          75 35 S  26 39 W -12        0 0 1 0 sunrise: 06:45 sunset: 20:48
2013  8 31 Halley_Base          75 35 S  26 39 W -12        1 0 1 0 sunrise: 06:40 sunset: 20:53
2013  8 31 Halley_Base          75 35 S  26 39 W -18        0 0 1 0 sunrise: 04:56 sunset: 22:37
2013  8 31 Halley_Base          75 35 S  26 39 W -18        1 0 1 0 sunrise: 04:50 sunset: 22:42
2013  9 21 Halley_Base          75 35 S  26 39 W 0          0 0 1 0 sunrise: 07:47 sunset: 19:31
2013  9 21 Halley_Base          75 35 S  26 39 W 0          1 0 1 0 sunrise: 07:43 sunset: 19:36
2013  9 21 Halley_Base          75 35 S  26 39 W -0.583     0 0 1 0 sunrise: 07:37 sunset: 19:41
2013  9 21 Halley_Base          75 35 S  26 39 W -0.583     1 0 1 0 sunrise: 07:33 sunset: 19:45
2013  9 21 Halley_Base          75 35 S  26 39 W -0.833     0 0 1 0 sunrise: 07:33 sunset: 19:45
2013  9 21 Halley_Base          75 35 S  26 39 W -0.833     1 0 1 0 sunrise: 07:29 sunset: 19:49
2013  9 21 Halley_Base          75 35 S  26 39 W -12        0 0 1 0 sunrise: 04:06 sunset: 23:12
2013  9 21 Halley_Base          75 35 S  26 39 W -12        1 0 1 0 sunrise: 03:59 sunset: 23:19
2013  9 21 Halley_Base          75 35 S  26 39 W -18        0 0 0 1 sunrise: 01:39 sunset: 25:39
2013  9 21 Halley_Base          75 35 S  26 39 W -18        1 0 0 1 sunrise: 01:39 sunset: 25:39
2013 12 31 Halley_Base          75 35 S  26 39 W 0          0 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W 0          1 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W -0.583     0 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W -0.583     1 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W -0.833     0 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W -0.833     1 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W -12        0 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W -12        1 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W -18        0 0 0 1 sunrise: 01:49 sunset: 25:49
2013 12 31 Halley_Base          75 35 S  26 39 W -18        1 0 0 1 sunrise: 01:49 sunset: 25:49
2013  1  1 South_Pole           89 59 S   0  0 W 0          0 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W 0          1 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W -0.583     0 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W -0.583     1 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W -0.833     0 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W -0.833     1 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: 00:03 sunset: 24:03
2013  1  1 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: 00:03 sunset: 24:03
2013  3 21 South_Pole           89 59 S   0  0 W 0          0 1 0 0 sunrise: 12:07 sunset: 12:07
2013  3 21 South_Pole           89 59 S   0  0 W 0          1 1 0 0 sunrise: 12:07 sunset: 12:07
2013  3 21 South_Pole           89 59 S   0  0 W -0.583     0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 South_Pole           89 59 S   0  0 W -0.583     1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 South_Pole           89 59 S   0  0 W -0.833     0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 South_Pole           89 59 S   0  0 W -0.833     1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: 00:07 sunset: 24:07
2013  3 21 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: 00:07 sunset: 24:07
2013  6 21 South_Pole           89 59 S   0  0 W 0          0 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W 0          1 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W -0.583     0 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W -0.583     1 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W -0.833     0 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W -0.833     1 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W -12        0 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W -12        1 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W -18        0 1 0 0 sunrise: 12:01 sunset: 12:01
2013  6 21 South_Pole           89 59 S   0  0 W -18        1 1 0 0 sunrise: 12:01 sunset: 12:01
2013  8 31 South_Pole           89 59 S   0  0 W 0          0 1 0 0 sunrise: 12:00 sunset: 12:00
2013  8 31 South_Pole           89 59 S   0  0 W 0          1 1 0 0 sunrise: 12:00 sunset: 12:00
2013  8 31 South_Pole           89 59 S   0  0 W -0.583     0 1 0 0 sunrise: 12:00 sunset: 12:00
2013  8 31 South_Pole           89 59 S   0  0 W -0.583     1 1 0 0 sunrise: 12:00 sunset: 12:00
2013  8 31 South_Pole           89 59 S   0  0 W -0.833     0 1 0 0 sunrise: 12:00 sunset: 12:00
2013  8 31 South_Pole           89 59 S   0  0 W -0.833     1 1 0 0 sunrise: 12:00 sunset: 12:00
2013  8 31 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: 00:00 sunset: 24:00
2013  8 31 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: 00:00 sunset: 24:00
2013  9 21 South_Pole           89 59 S   0  0 W 0          0 1 0 0 sunrise: 11:53 sunset: 11:53
2013  9 21 South_Pole           89 59 S   0  0 W 0          1 1 0 0 sunrise: 11:53 sunset: 11:53
2013  9 21 South_Pole           89 59 S   0  0 W -0.583     0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 South_Pole           89 59 S   0  0 W -0.583     1 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 South_Pole           89 59 S   0  0 W -0.833     0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 South_Pole           89 59 S   0  0 W -0.833     1 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: -1:53 sunset: 23:53
2013  9 21 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: -1:53 sunset: 23:53
2013 12 31 South_Pole           89 59 S   0  0 W 0          0 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W 0          1 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W -0.583     0 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W -0.583     1 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W -0.833     0 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W -0.833     1 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W -12        0 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W -12        1 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W -18        0 0 0 1 sunrise: 00:03 sunset: 24:03
2013 12 31 South_Pole           89 59 S   0  0 W -18        1 0 0 1 sunrise: 00:03 sunset: 24:03
EOD
}
