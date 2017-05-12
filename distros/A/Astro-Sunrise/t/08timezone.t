#!/usr/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Astro::Sunrise
#     Copyright (C) 2015 Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<http://www.perlfoundation.org/artistic_license_1_0>
#     and L<http://www.gnu.org/licenses/gpl-1.0.html>.
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
#     Inc., <http://www.fsf.org/>.
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
}
plan(tests => 4);

my $sunrise_5 = sun_rise({ lon => -118, lat => 33, time_zone =>'America/Los_Angeles', });
my $sunrise_6 = sun_rise({ lon => -118, lat => 33, time_zone =>'America/Los_Angeles',
                           alt => DEFAULT, offset => 0, upper_limb => 0, precise => 0 });

is( $sunrise_5, $sunrise_6 , "Comparing basic parameters with all parameters");

my $sunset_5 = sun_set({ lon => -118, lat => 33, time_zone =>'America/Los_Angeles', });
my $sunset_6 = sun_set({ lon => -118, lat => 33, time_zone =>'America/Los_Angeles',
                         alt => DEFAULT, offset => 0, upper_limb => 0, precise => 0 });

is($sunset_5, $sunset_6, "Comparing basic parameters with all parameters");

my $then = DateTime->today ( time_zone =>'America/Los_Angeles', );
my $offset = ($then->offset) /60 /60;
my ($sunrise, $sunset) = sunrise($then->year, $then->mon, $then->mday,
                              -118, 33, $offset, 0);
is ($sunrise, $sunrise_6, "Test DateTime sunrise interface");
is ($sunset,  $sunset_6,  "Test DateTime sunset interface");


