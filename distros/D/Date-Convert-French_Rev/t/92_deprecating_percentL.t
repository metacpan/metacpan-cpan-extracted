# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Date::Convert::French_Rev
#     Copyright © 2020 Jean Forget
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
# Checking the value checks.
#
use Test::More;
use Date::Convert::French_Rev;
BEGIN {
  eval "use Test::Warnings qw/:all/;";
  plan skip_all => "Test::Warnings needed" if $@;
}

my $date = Date::Convert::French_Rev->new(8, 2, 18);

plan(tests => 3);

my $str;

$str = $date->date_string("%L");
had_no_warnings("%L executed without warnings");
is($str, "0008", "%L gave the proper year");

# Later:
# like( warning { $str = $date->date_string("%L"); }, qr/Specifier %L is deprecated/i, "warning sent");

# Still later:
# is($str, "%L", "%L is disabled");

