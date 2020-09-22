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
use Test::More;
use Date::Convert::French_Rev;

sub r2g {
  my $date_g = shift;
  my $date = Date::Convert::French_Rev->new(@_);
  Date::Convert::Gregorian->convert($date);
  my $date_resul = $date->date_string;
  is($date_resul, $date_g, "expected $date_g, got $date_resul");
}


@tests = (["1792 Sep 22",   1,  1,  1],
          ["1793 Sep 21",   1, 13,  5],
          ["1793 Sep 22",   2,  1,  1],
          ["1794 Sep 21",   2, 13,  5],
          ["1794 Sep 22",   3,  1,  1],
          ["1795 Sep 22",   3, 13,  6],
          ["1795 Sep 23",   4,  1,  1],
          ["1796 Sep 21",   4, 13,  5],
          ["1796 Sep 22",   5,  1,  1],
          ["1797 Sep 21",   5, 13,  5],
          ["1797 Sep 22",   6,  1,  1],
          ["1799 Sep 22",   7, 13,  6],
          ["1799 Sep 23",   8,  1,  1],
          ["1800 Sep 22",   8, 13,  5],
          ["1800 Sep 23",   9,  1,  1],
          ["1801 Sep 22",   9, 13,  5],
          ["1801 Sep 23",  10,  1,  1],
          ["1823 Sep 22",  31, 13,  5],
          ["1823 Sep 23",  32,  1,  1],
          ["1824 Sep 22",  32, 13,  6],
          ["1824 Sep 23",  33,  1,  1],
          ["1825 Sep 22",  33, 13,  5],
          ["1825 Sep 23",  34,  1,  1],
          ["1892 Sep 21", 100, 13,  5],
          ["1892 Sep 22", 101,  1,  1],
          ["1900 Sep 22", 108, 13,  6],
          ["1900 Sep 23", 109,  1,  1],
          ["1992 Sep 21", 200, 13,  5],
          ["1992 Sep 22", 201,  1,  1],
          ["2000 Sep 21", 208, 13,  6],
          ["2000 Sep 22", 209,  1,  1],
          ["2092 Sep 20", 300, 13,  5],
          ["2092 Sep 21", 301,  1,  1],
          ["2100 Sep 21", 308, 13,  6],
          ["2100 Sep 22", 309,  1,  1],
          ["2192 Sep 21", 400, 13,  6],
          ["2192 Sep 22", 401,  1,  1],
          );

plan(tests => scalar @tests);

foreach (@tests) { r2g @$_ }

