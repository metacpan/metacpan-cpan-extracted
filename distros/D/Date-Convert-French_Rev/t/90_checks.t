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
# Checking the value checks.
#
use Test::More;
use Test::Exception;
use Date::Convert::French_Rev;

my @tests = ( [ "Year number is zero",              0,  1,  1 ],
              [ "Year number is negative",         -2,  1,  1 ],
              [ "Month number is zero",          2000,  0,  1 ],
              [ "Month number is more than 14",  2000, 14,  1 ],
              [ "Day number is zero",            2000,  1,  0 ],
              [ "Day number is more than 30",    2000,  1, 31 ],
              [ "Day number is more than 30",    2000, 13, 31 ],
              [ "Additional day number is zero", 2000, 13,  0 ],
              [ "Additional day number is less than zero",            2000, 13, -1 ],
              [ "Additional day number is more than 5 (normal year)", 2001, 13,  6 ],
              [ "Additional day number is more than 6 (leap year)",   2004, 13,  7 ],
              [ "Incomplete parameters",                              2004         ],
              [ "Incomplete parameters",                              2004,  1     ],
              [ "Incomplete parameters",                              2004, undef, 1 ],
              [ "Incomplete parameters",                             undef,  1,    1 ],
);

plan(tests => 1 + scalar @tests);

for (@tests) {
  my ($msg, @args) = @$_;
  dies_ok { Date::Convert::French_Rev->new(@args) } $msg;
}
my $d1 = Date::Convert::French_Rev->new(1, 2, 3);
dies_ok { $d1->change_to() } "One argument required for 'change_to'";
