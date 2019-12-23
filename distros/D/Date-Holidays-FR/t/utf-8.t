# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     t/utf-8.t
#     Test script for Date::Holidays::FR
#     Copyright © 2019 Fabien Potencier and Jean Forget, all rights reserved
#
#     This program is distributed under the same terms as Perl:
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
use strict;
use warnings;
use Date::Holidays::FR;
use Test::More;

# Remember RT 100311 for DateTime::Calendar::FrenchRevolutionary,
# where the module and the test scripts looked like they were working
# in UTF-8 and actually they were working in ISO-8859. Checking the
# string length allow us to be sure they work in UTF-8.
                       #             1         2
my @data = (           #    1...5....0....5....0
        [2013,  1,  1,  9, "Nouvel an"]
     ,  [2013,  4,  1, 15, "Lundi de Pâques"]
     ,  [2013,  5,  1, 15, "Fête du travail"]
     ,  [2013,  5,  8, 19, "Armistice 1939-1945"]
     ,  [2013,  5,  9,  9, "Ascension"]
     ,  [2013,  5, 20, 18, "Lundi de Pentecôte"]
     ,  [2013,  7, 14, 14, "Fête nationale"]
     ,  [2013,  8, 15, 10, "Assomption"]
     ,  [2013, 11,  1,  9, "Toussaint"]
     ,  [2013, 11, 11, 19, "Armistice 1914-1918"]
     ,  [2013, 12, 25,  4, "Noël"]
     );

plan(tests => 2 * @data);

for (@data) {
  my ($year, $month, $day, $length, $string) = @$_;
  is(       is_fr_holiday($year, $month, $day) , $string);
  is(length(is_fr_holiday($year, $month, $day)), $length);
}
