# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     t/Date-Holidays-FR.t
#     Test script for Date::Holidays::FR
#     Copyright © 2004, 2019 Fabien Potencier and Jean Forget, all rights reserved
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
use Test::More tests => 28;

BEGIN {
        use_ok('Date::Holidays::FR')
};

ok(!is_fr_holiday(2004,  1,  2));
ok(!is_fr_holiday(2004,  4,  8));
ok(!is_fr_holiday(2004,  4, 11));
ok(!is_fr_holiday(2004,  5,  2));
ok(!is_fr_holiday(2004,  5,  7));
ok(!is_fr_holiday(2004,  7, 15));
ok(!is_fr_holiday(2004,  8, 14));
ok(!is_fr_holiday(2004, 11, 25));
ok(!is_fr_holiday(2004, 12, 24));

ok(is_fr_holiday(2004, 4, 12));
like(is_fr_holiday(2004, 5, 31), qr/pentec/i);
like(is_fr_holiday(2004, 5, 20), qr/ascension/i);

my $year = (localtime)[5];
like(is_fr_holiday($year,  1,  1), qr/an/i);
like(is_fr_holiday($year,  5,  1), qr/travail/i);
like(is_fr_holiday($year,  5,  8), qr/armistice/i);
like(is_fr_holiday($year,  7, 14), qr/nationale/i);
like(is_fr_holiday($year,  8, 15), qr/assomption/i);
like(is_fr_holiday($year, 11,  1), qr/toussaint/i);
like(is_fr_holiday($year, 11, 11), qr/armistice/i);
like(is_fr_holiday($year, 12, 25), qr/no/i);

my ($month, $day) = Date::Holidays::FR::get_easter(2004);
is($month, 4);
is($day, 11);

($month, $day) = Date::Holidays::FR::get_ascension(2004);
is($month, 5);
is($day, 20);

($month, $day) = Date::Holidays::FR::get_pentecost(2004);
is($month, 5);
is($day, 31);

# See https://rt.cpan.org/Public/Bug/Display.html?id=122022
like(is_fr_holiday(2013,  4,  1), qr/lundi de p/i);
