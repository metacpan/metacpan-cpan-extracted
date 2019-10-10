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

use DateTime::Event::Easter;

plan(tests => 4);

my $palm_sundays = DateTime::Event::Easter->new(day => 'palm');
my $all_palm_sundays_point = $palm_sundays->as_set();
$palm_sundays = $palm_sundays->as_span;
my $all_palm_sundays_span = $palm_sundays->as_set();

is($all_palm_sundays_point->next(DateTime->new(year => 1991, month => 1, day => 1))->ymd, '1991-03-24', "Point following is correct");
is($all_palm_sundays_point->next(DateTime->new(year => 2019, month => 1, day => 1))->ymd, '2019-04-14', "Point following is correct");


my $palm_2015 = $all_palm_sundays_span->closest(DateTime->new(year => 2015, month => 1, day => 1));
my $noon  = DateTime->new(year => 2015, month => 3, day => 29, hour => 12);
ok($palm_2015->contains($noon), "Span following is correct");

my $palm_1901 = $all_palm_sundays_span->previous(DateTime->new(year => 1901, month => 6, day => 30));
my $midnight = DateTime->new(year => 1901, month => 3, day => 31, hour => 23, minute => 59);
ok($palm_1901->contains($midnight), "Span previous is correct");

