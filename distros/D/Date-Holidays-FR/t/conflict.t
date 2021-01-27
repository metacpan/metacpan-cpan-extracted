# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     t/conflict.t
#     Test script for Date::Holidays::FR
#     Copyright (c) 2021 Fabien Potencier and Jean Forget, all rights reserved
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
use Test::More;

BEGIN {
        use_ok('Date::Holidays::FR')
};

like(is_fr_holiday(1913,  1,  1), qr/an/i);
like(is_fr_holiday(1913,  5,  1), qr/scension/i);   # In 1913, Easter occurs on Sunday 23rd March, so Ascension occurs on 1913-05-01
like(is_fr_holiday(1913,  5,  8), qr/armistice/i);
like(is_fr_holiday(1913,  7, 14), qr/nationale/i);
like(is_fr_holiday(1913,  8, 15), qr/assomption/i);
like(is_fr_holiday(1913, 11,  1), qr/toussaint/i);
like(is_fr_holiday(1913, 11, 11), qr/armistice/i);
like(is_fr_holiday(1913, 12, 25), qr/no/i);

like(is_holiday(1997,  1,  1), qr/an/i);
like(is_holiday(1997,  5,  1), qr/travail/i);
like(is_holiday(1997,  5,  8), qr/ascension/i); # In 1997 (and some other years), Easter occurs on Sunday 30th March, so Ascension occurs on 8th May, same as Armistice 1945
like(is_holiday(1997,  7, 14), qr/nationale/i);
like(is_holiday(1997,  8, 15), qr/assomption/i);
like(is_holiday(1997, 11,  1), qr/toussaint/i);
like(is_holiday(1997, 11, 11), qr/armistice/i);
like(is_holiday(1997, 12, 25), qr/no/i);

done_testing();
