# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Easter
#     Copyright © 2019 Rick Measham and Jean Forget, all rights reserved
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

use strict;
use warnings;
use Test::More;

use DateTime::Event::Easter qw/golden_number
                               western_epact        
                               western_sunday_letter
                               western_sunday_number
                               eastern_epact        
                               eastern_sunday_letter
                               eastern_sunday_number
                              /;

# Data coming from Paul Couderc's book, pages 106 to 109.
# 1991 data cross-referenced with the "Almanach du Facteur" for this year.
my @data = ( [ 1991, 16,  14  , 'F' , 6, 23, 'G' , 7 ]
           , [ 2020,  7,   5  , 'ED', 4, 14, 'FE', 5 ]
           , [ 1916, 17, '25*', 'BA', 1,  4, 'CB', 2 ]
           , [ 2345,  9,  25  , 'G' , 7,  6, 'E' , 5 ]

);
plan(tests => 7 * @data);

for (@data) {
  my ($y, $gold, $w_epact, $w_sunday_l, $w_sunday_n, $e_epact, $e_sunday_l, $e_sunday_n) = @$_;
  is(golden_number        ($y), $gold      , "In $y, golden number is $gold");
  is(western_epact        ($y), $w_epact   , "In $y, western epact is $w_epact");
  is(western_sunday_letter($y), $w_sunday_l, "In $y, western sunday letter is $w_sunday_l");
  is(western_sunday_number($y), $w_sunday_n, "In $y, western sunday number is $w_sunday_n");
  is(eastern_epact        ($y), $e_epact   , "In $y, eastern epact is $e_epact");
  is(eastern_sunday_letter($y), $e_sunday_l, "In $y, eastern sunday letter is $e_sunday_l");
  is(eastern_sunday_number($y), $e_sunday_n, "In $y, eastern sunday number is $e_sunday_n");
}
