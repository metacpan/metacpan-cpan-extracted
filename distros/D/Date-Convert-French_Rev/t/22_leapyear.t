# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Date::Convert::French_Rev
#     Copyright (C) 2013, 2015 Jean Forget
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
#
# Checking leap years.
#
# The number "22" is inherited from DateTime::Calendar::FrenchRevolutionary
#
use Test::More;
use Date::Convert::French_Rev;

my %years = qw/   1 0    2 0    3 1    4 0    5 0    6 0    7 1    8 0  9 0 10 0
                 11 1   12 0   13 0   14 0   15 1   16 0   17 0   18 0 19 0 20 1
                 21 0   22 0   23 0   24 1   25 0   26 0   27 0   28 1 29 0 30 0
                100 0  200 0  300 0  400 1  500 0  600 0  700 0  800 1
               1000 0 2000 1 3000 0 4000 0 5000 0 6000 1 7000 0 8000 0
              /;
my $nb_tests = keys %years;

plan(tests => 2 * $nb_tests);

for my $y (sort { $a <=> $b } keys %years) {
  my $msg = "Year $y is " . ($years{$y} ? "leap" : "normal");
  is(Date::Convert::French_Rev->is_leap($y), $years{$y}, $msg);
  my $d = Date::Convert::French_Rev->new($y, 1, 1);
  is($d->is_leap, $years{$y}, $msg);
}
