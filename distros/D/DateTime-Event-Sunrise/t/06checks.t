# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Sunrise
#     Copyright (C) 2014 Jean Forget
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
#     Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#
#
# Checking the value checks.
#
use Test::More;
use Test::Exception;
use DateTime::Event::Sunrise;

plan(tests => 12);

# 1
dies_ok { DateTime::Event::Sunrise->new( longitude => 0, 1 ) } "Odd number of parameters";
# 2
dies_ok { DateTime::Event::Sunrise->new( precise => 1, iteration => 1) } "Parameter 'iteration' is deprecated, use only 'precise'";

my $sun = DateTime::Event::Sunrise->new (); # with all the default values!

# 3
dies_ok { my $s = $sun->sunset_datetime("illegal") } "Dates need to be DateTime objects";
# 4
dies_ok { my $s = $sun->sunrise_datetime("illegal") } "Dates need to be DateTime objects";
# 5
dies_ok { my $s = $sun->sunrise_sunset_span("illegal") } "Dates need to be DateTime objects";
# 6
dies_ok { my $s = $sun->is_polar_night("illegal") } "Dates need to be DateTime objects";
# 7
dies_ok { my $s = $sun->is_polar_day("illegal") } "Dates need to be DateTime objects";
# 8
dies_ok { my $s = $sun->is_day_and_night("illegal") } "Dates need to be DateTime objects";
# 9
dies_ok { my $s = $sun->_following_sunrise("illegal") } "Dates need to be DateTime objects";
# 10
dies_ok { my $s = $sun->_previous_sunrise("illegal") } "Dates need to be DateTime objects";
# 11
dies_ok { my $s = $sun->_following_sunset("illegal") } "Dates need to be DateTime objects";
# 12
dies_ok { my $s = $sun->_previous_sunset("illegal") } "Dates need to be DateTime objects";


