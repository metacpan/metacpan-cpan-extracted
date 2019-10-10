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
# This test is based on Eugene van der Pijll's remarks from
# https://www.nntp.perl.org/group/perl.datetime/2003/03/msg1437.html
# but taking them in the other way. Instead of computing Eastern Easter
# with Gregorian dates, this test script computes
# the *Western* Easter with *Julian* dates.
#

use strict;
use warnings;
use Test::More;

use DateTime::Event::Easter;
use DateTime::Calendar::Julian;

my @list1 = qw/
           14399-01-02
           14399-12-18
           14401-01-06
           14401-12-29
           14402-12-14
           14404-01-03
           14404-12-25
       /;
plan(tests => 2 * @list1);


my $easter = DateTime::Event::Easter->new(easter => 'western');
my $begin1 = DateTime::Calendar::Julian->new(year => 14398, month => 1, day => 1);
my $end1   = DateTime::Calendar::Julian->new(year => 14405, month => 1, day => 1);

sub checking {
  my ($ref_list, $begin, $end) = @_;
  my @list = @$ref_list;

  # checking "following"
  my $dt = $begin;
  for my $i (0..$#list) {
    my $dt1 = $easter->following($dt);
    is ($dt1->ymd, $list[$i], "Following Easter on $list[$i]");
    $dt = $dt1;
  }

  # checking "previous"
  $dt = $end;
  for my $i (reverse (0..$#list)) {
    my $dt1 = $easter->previous($dt);
    is ($dt1->ymd, $list[$i], "Previous Easter on $list[$i]");
    $dt = $dt1;
  }
}

checking(\@list1, $begin1, $end1);

