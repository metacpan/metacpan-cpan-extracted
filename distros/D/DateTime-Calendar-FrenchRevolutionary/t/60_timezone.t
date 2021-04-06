# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2003, 2004, 2010, 2011, 2012, 2014, 2016, 2019, 2021 Jean Forget. All rights reserved.
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
#
# Checking the (lack of) support of time zones
# It is noon in Paris, several people around the world simultaneously want to know
# which time it is.
use DateTime::Calendar::FrenchRevolutionary;
use DateTime;
use utf8;
use strict;
use warnings;

sub g2r {
  my ($n, $date_r1, $tz) = @_;
  my $format = "%Y %m %d %H %M %S";
  my $date_g = DateTime->new(year => 2003, month => 4, day => 18, 
                        hour => 12, minute => 0, second => 0, time_zone => 'Europe/Paris');
  $date_g->set_time_zone($tz);
  my $date_result = DateTime::Calendar::FrenchRevolutionary->from_object(object => $date_g)
                             ->strftime($format);
  my $date_r2 = $date_r1; # Alternate date to check agains, because there may be a rounding error
  substr($date_r2, -2, 2) ++; # add 1 second to alternate date, hoping we do not increment 99 to 100
  if ($date_result eq $date_r1 or $date_result eq $date_r2)
    { print "ok $n\n" }
  else
    { print "not ok $n : expected $date_r1, got $date_result\n" }
}

my @tests = (["0211 07 29 5 00 00", "Europe/Paris"]
           , ["0211 07 29 5 83 33", "Europe/Moscow"]     # offset +2 ABT hours, 83.33 d-minutes
           , ["0211 07 29 4 58 33", "Europe/London"]     # offest -1 ABT hour, -41.67 d-minutes
           , ["0211 07 29 2 08 33", "America/Chicago"]   #  -7 ABT hours, -291.67 d-minutes
           , ["0211 07 29 9 16 66", "Pacific/Auckland"]  #  10 ABT hours, -416.67 d-minutes
           , ["0211 07 29 0 00 00", "Pacific/Tahiti"]    # -12 ABT hours, -500    d-minutes
           , ["0211 07 28 9 58 33", "Pacific/Pago_Pago"] # -13 ABT hours, -541.67 d-minutes
             );

my $nb_tests = @tests;
my $n = 1;

print "1..$nb_tests\n";

foreach (@tests) { g2r $n++, @$_ }
