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

plan(tests => 6);

my $w_easter = DateTime::Event::Easter->new(day => 1000);
my $ref1     = DateTime->new(year => 2019, month => 10, day => 3);
my $ref2     = DateTime->new(year => 2019, month =>  9, day => 1);

my $event  = $w_easter->following($ref1);
is ($event->ymd, "2020-01-11", "Event after 2019-10-03 is 2020-01-11");

$event  = $w_easter->following($ref2);
is ($event->ymd, "2020-01-11", "Event after 2019-09-01 is 2020-01-11");

$event  = $w_easter->previous($ref1);
is ($event->ymd, "2018-12-22", "Event before 2019-10-03 is 2018-12-22");

$event  = $w_easter->previous($ref2);
is ($event->ymd, "2018-12-22", "Event before 2019-09-01 is 2018-12-22");

ok ($w_easter->is(DateTime->new(year => 2020, month =>  1, day => 11)), "Checking that 2020-01-11 is Easter+1000");
ok ($w_easter->is(DateTime->new(year => 2018, month => 12, day => 22)), "Checking that 2018-12-22 is Easter+1000");
