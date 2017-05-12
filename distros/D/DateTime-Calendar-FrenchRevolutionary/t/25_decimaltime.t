# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Calendar::FrenchRevolutionary
#     Copyright (C) 2011, 2012, 2014, 2016 Jean Forget. All rights reserved.
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
use DateTime::Calendar::FrenchRevolutionary;
use utf8;
use strict;
use warnings;

# Yes, that's shotgun testing. You have in the end 990 tests and the
# 0.08 version would fail 57/990. So I guess that it is still a good
# set of data for the test
my @hours = (0..9);
my @minutes = qw/0 3 8 12 23 42 65 77 99/;
my @seconds = qw/0 2 5 10 18 26 37 56 64 88 99/;
my $nb_tests = @hours * @minutes * @seconds;

my $n = 1;

sub check_time {
  my ($n, $h, $m, $s) = @_;
  my $dt = DateTime::Calendar::FrenchRevolutionary->new(
            year => 1, month => 2, day => 3, hour => $h, minute => $m, second => $s);
  my $resul    = $dt->iso8601;
  my $expected = sprintf "0001-02-03T%d:%02d:%02d", $h, $m, $s;
  if ($expected eq $resul) {
    print "ok $n\n";
  }
  else {
    print "not ok $n : expected $expected, got $resul\n";
  }
}


printf "1..$nb_tests\n";

for my $h (@hours) {
  for my $m (@minutes) {
    for my $s (@seconds) {
      check_time $n++, $h, $m, $s;
    }
  }
}
