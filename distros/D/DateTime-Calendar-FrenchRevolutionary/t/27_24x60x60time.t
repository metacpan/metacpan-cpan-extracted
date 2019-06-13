# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2011, 2012, 2014, 2016, 2019 Jean Forget. All rights reserved.
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
use DateTime::Calendar::FrenchRevolutionary;
use utf8;
use strict;
use warnings;

my $n = 1;
my @tests = ( [ "0:41:66", "0:41:67",  1,  0,  0],
              [ "0:72:91", "0:72:92",  1, 45,  0],
              [ "0:85:46", "0:85:47",  2,  3,  4],
              [ "7:99:99", "8:00:00", 19, 12,  0],
              [ "8:99:99", "9:00:00", 21, 36,  0],
            );
my @tests1 = ( [ "01-00-00",      1,  0,  0, '-'],
               [ "01+45+00",      1, 45,  0, '+'],
               [ "02*03*04",      2,  3,  4, '*'],
               [ "19<->12<->00", 19, 12, 0, '<->'],
               [ '21$$$36$$$00', 21, 36, 0, '$$$'],
             );

sub check_time {
  my ($n, $ch1, $ch2, $h, $m, $s) = @_;
  my $dt = DateTime::Calendar::FrenchRevolutionary->new(
            year => 1, month => 2, day => 3, abt_hour => $h, abt_minute => $m, abt_second => $s);
  my $resul    = $dt->iso8601;
  my $expected1 = "0001-02-03T" . $ch1;
  my $expected2 = "0001-02-03T" . $ch2;
  if ($resul eq $expected1 or $resul eq $expected2) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected $expected1 or $expected2, got $resul\n";
  }
}

sub check_time_1 {
  my ($n, $ch1, $h, $m, $s, $sep) = @_;
  my $dt = DateTime::Calendar::FrenchRevolutionary->new(
            year => 1, month => 2, day => 3, abt_hour => $h, abt_minute => $m, abt_second => $s);
  my $resul    = $dt->abt_hms($sep);
  if ($resul eq $ch1) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected $ch1, got $resul\n";
  }
}

printf "1..%d\n", scalar(@tests) + scalar(@tests1);

for (@tests) {
  check_time $n++, @$_;
}

for (@tests1) {
  check_time_1 $n++, @$_;
}
