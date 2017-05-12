# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Date::Convert::French_Rev
#     Copyright (C) 2001, 2002, 2003, 2013, 2015 Jean Forget
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
# Checking negative dates. What matters is only that you can convert *to*
# a negative revolutionary date and then *from* the same date and get
# the same result.
# That is, we do not check the dates are correct, we check the conversions are consistent.
#
# The number "80" is inherited from DateTime::Calendar::FrenchRevolutionary
#
use Test::More;
use Date::Convert::French_Rev;

sub check_cycle {
  my ($y, $m, $d) = @_;
  my $dt  = Date::Convert::Gregorian->new(@_);
  my $date_g1  = $dt->date_string;
  Date::Convert::French_Rev->convert($dt);
  Date::Convert::Gregorian->convert($dt);
  my $date_g2  = $dt->date_string;
  is($date_g1, $date_g2);
}

@tests = ([1792, 9, 22,  1,  1,  1] # the DT-C-FR epoch
        , [1792, 9, 21,  0, 13,  5] # 1 day before the DT-C-FR epoch
        , [1789, 7, 14, -3, 10, 25] # Storming of the Bastille
);
plan(tests => scalar @tests);

foreach (@tests) { check_cycle @$_ }
