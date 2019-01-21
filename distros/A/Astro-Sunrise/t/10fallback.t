#!/usr/bin/perl -w
# -*- perl -*-
#
#     Test script for Astro::Sunrise
#     Author: Jean Forget, based on another test script by Slaven Rezic
#     Copyright (C) 2015, 2017 Slaven Rezic, Ron Hill and Jean Forget
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
use Test::More;

BEGIN {
  eval "use Time::Fake (1288545834);";
  if ($@) {
    plan skip_all => "Time::Fake needed";
    exit;
  }
  eval "use DateTime;";
  if ($@) {
    plan skip_all => "DateTime needed";
    exit;
  }
}
use Astro::Sunrise;

plan tests => 2;
is(sun_rise({ lon => 13.5, lat => 52.5, time_zone => 'Europe/Berlin' }), '07:00', "Sunrise in Berlin on 2010-10-31");
is(sun_set ({ lon => 13.5, lat => 52.5, time_zone => 'Europe/Berlin' }), '16:39', "Sunset  in Berlin on 2010-10-31");
