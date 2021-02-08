#!/usr/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Astro::Sunrise
#     Copyright (C) 2001--2003, 2013, 2015, 2017, 2021 Ron Hill and Jean Forget
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
use Astro::Sunrise(qw(:DEFAULT :constants));
use Test::More;


BEGIN {
  eval "use DateTime;";
  if ($@) {
    plan skip_all => "DateTime needed";
    exit;
  }
  eval "DateTime->now(time_zone => 'local');";
  if ($@) {
    plan skip_all => "Unable to find local time zone";
    exit;
  }
}
plan(tests => 12);

use vars qw($long $lat $offset);

my $sunrise_1 = sun_rise( -118, 33  );
my $sunrise_2 = sun_rise( -118, 33, -.833 );
my $sunrise_3 = sun_rise( -118, 33, -.833, 0 );
my $sunrise_4 = sun_rise( -118, 33, undef, 0 );
my $sunrise_5 = sun_rise({ lon => -118, lat => 33 });
my $sunrise_6 = sun_rise({ lon => -118, lat => 33, alt => DEFAULT, offset => 0, upper_limb => 0, precise => 0 });

ok( $sunrise_1 eq $sunrise_2 , "Test W/O Alt");
ok( $sunrise_2 eq $sunrise_3 , "Test W/O offset");
ok( $sunrise_3 eq $sunrise_4 , "Test setting Alt to undef");
ok( $sunrise_4 eq $sunrise_5 , "Test using named basic parameters");
ok( $sunrise_5 eq $sunrise_6 , "Test using all named parameters");

my $sunset_1 = sun_set( -118, 33  );
my $sunset_2 = sun_set( -118, 33, -.833 );
my $sunset_3 = sun_set( -118, 33, -.833, 0 );
my $sunset_4 = sun_set( -118, 33, undef, 0 );
my $sunset_5 = sun_set({ lon => -118, lat => 33 });
my $sunset_6 = sun_set({ lon => -118, lat => 33, alt => DEFAULT, offset => 0, upper_limb => 0, precise => 0 });

ok( $sunset_1 eq $sunset_2 , "Test W/O Alt");
ok( $sunset_2 eq $sunset_3 , "Test W/O offset");
ok( $sunset_3 eq $sunset_4 , "Test setting Alt to undef");
ok( $sunset_4 eq $sunset_5 , "Test using named basic parameters");
ok( $sunset_5 eq $sunset_6 , "Test using all named parameters");

my $then = DateTime->new (
                    year => 2000,
		    month => 6,
		    day => 20,
		    time_zone =>'America/Los_Angeles',
		    );
my $offset = ( ($then->offset) /60 /60);

my ($sunrise, $sunset) = sunrise($then->year, $then->mon, $then->mday,
                              -118, 33, $offset, 0);
is ($sunrise, '05:44', "Test DateTime sunrise interface");
is ($sunset,  '20:04', "Test DateTime sunset interface");

