#!/usr/bin/perl -w
# -*- perl -*-
#
#     Test script for Astro::Sunrise
#     Author: Slaven Rezic
#     Copyright (C) 2015, 2017 Slaven Rezic, Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
#     GNU Public License version 1 or later and Perl Artistic License
#
#     You can find the text of the licenses in the F<LICENSE> file or at
#     L<http://www.perlfoundation.org/artistic_license_1_0>
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
  eval "use DateTime;";
  if ($@) {
    plan skip_all => "DateTime needed";
    exit;
  }
  eval "use Time::Fake;";
  if ($@) {
    plan skip_all => "Time::Fake needed";
    exit;
  }
  if ($^O =~ /MSWin/i) {
    plan skip_all => "Unix-like forking needed";
    exit;
  }
}

my @tests = (
	     [1288545834, 'sun_rise', '07:00'],
	     [1288545834, 'sun_set',  '16:39'],

	     [1269738800, 'sun_rise', '06:50'],
	     [1269738800, 'sun_set',  '19:32'],
	    );

plan tests => scalar @tests;

for my $test (@tests) {
  my($epoch, $func, $expected) = @$test;
  my @cmd = ($^X, "-Mblib",
		  "-MTime::Fake=$epoch",
		  "-MAstro::Sunrise",
		  "-e", "print $func({ lon => 13.5, lat => 52.5, time_zone => 'Europe/Berlin' })");
  open my $fh, "-|", @cmd or die $!;
  local $/;
  my $res = <$fh>;
  close $fh or die "Failure while running @cmd: $!";
  is $res, $expected, "Check for $func at $epoch";
}

__END__
