# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Date::Convert::French_Rev
#     Copyright © 2001, 2002, 2003, 2013, 2015, 2020 Jean Forget
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
use utf8;
use Test::More;
use Date::Convert::French_Rev;

sub g2r_string {
  my ($date_r, $yr, $mr, $dr, $yg, $mg, $dg) = @_;
  my $date   = Date::Convert::Gregorian->new($yg, $mg, $dg);
  Date::Convert::French_Rev->convert($date);
  my $date_resul = $date->date_string();
  is($date_resul, $date_r, "expected $date_r, got $date_resul");
}

sub g2r_date {
  my ($date_r, $yr, $mr, $dr, $yg, $mg, $dg) = @_;
  my $date   = Date::Convert::Gregorian->new($yg, $mg, $dg);
  Date::Convert::French_Rev->convert($date);

  my ($calc_y, $calc_m, $calc_d) = $date->date();
  ok( $calc_y == $yr && $calc_m == $mr && $calc_d == $dr, "expected ($yr, $mr, $dr), got ($calc_y, $calc_m, $calc_d)" );
}

sub g2r_day {
  my ($date_r, $yr, $mr, $dr, $yg, $mg, $dg) = @_;
  my $date   = Date::Convert::Gregorian->new($yg, $mg, $dg);
  Date::Convert::French_Rev->convert($date);

  my $calc_d = $date->day();
  my $calc_m = $date->month();
  my $calc_y = $date->year();
  ok( $calc_y == $yr && $calc_m == $mr && $calc_d == $dr, "expected ($yr, $mr, $dr), got ($calc_y, $calc_m, $calc_d)" );
}

@tests = ([" 1 Vendémiaire I",       1,  1,  1, 1792,  9, 22],
          [" 2 Brumaire II",         2,  2,  2, 1793, 10, 23],
          [" 9 Thermidor II",        2, 11,  9, 1794,  7, 27],
          [" 3 Frimaire III",        3,  3,  3, 1794, 11, 23],
          ["13 Vendémiaire IV",      4,  1, 13, 1795, 10,  5],
          [" 4 Nivôse IV",           4,  4,  4, 1795, 12, 25],
          [" 5 Pluviôse V",          5,  5,  5, 1797,  1, 24],
          [" 6 Ventôse VI",          6,  6,  6, 1798,  2, 24],
          ["18 Brumaire VIII",       8,  2, 18, 1799, 11,  9],
          [" 8 Germinal IX",         9,  7,  8, 1801,  3, 29],
          ["10 Floréal XII",        12,  8, 10, 1804,  4, 30],
          ["12 Prairial XV",        15,  9, 12, 1807,  6,  1],
          ["14 Messidor XVIII",     18, 10, 14, 1810,  7,  3],
          ["16 Thermidor XXI",      21, 11, 16, 1813,  8,  4],
          ["18 Fructidor XXIV",     24, 12, 18, 1816,  9,  4],
          ["12 Nivôse CCVIII",     208,  4, 12, 2000,  1,  1], # Y2K compatible?
          ["22 Floréal CCIX",      209,  8, 22, 2001,  5, 11],
          ["12 Nivôse MCCVIII",   1208,  4, 12, 3000,  1,  1],
          ["11 Nivôse MCCIX",     1209,  4, 11, 3001,  1,  1],
          ["12 Nivôse MMCCVIII",  2208,  4, 12, 4000,  1,  1],
          ["12 Nivôse MMCCIX",    2209,  4, 12, 4001,  1,  1],
          ["12 Nivôse MMMCCVIII", 3208,  4, 12, 5000,  1,  1],
          ["11 Nivôse MMMCCIX",   3209,  4, 11, 5001,  1,  1],
          ["13 Nivôse 4208",      4208,  4, 13, 6000,  1,  1],
          ["13 Nivôse 4209",      4209,  4, 13, 6001,  1,  1],
          );

plan(tests => scalar 3 * @tests);

foreach (@tests) { g2r_string @$_ }
foreach (@tests) { g2r_date   @$_ }
foreach (@tests) { g2r_day    @$_ }

