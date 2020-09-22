# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for Date::Convert::French_Rev
#     Copyright © 2001, 2002, 2003, 2013, 2015, 2020 Jean Forget
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
use Test::More;
use Date::Convert::French_Rev;

sub r2g {
  my $date_g = shift;
  my $date   = Date::Convert::French_Rev->new(@_);
  Date::Convert::Gregorian->convert($date);
  my $date_resul = $date->date_string;
  is($date_resul, $date_g, "expected $date_g, got $date_resul" );
}

@tests = (["1792 Sep 22",    1,  1,  1],
          ["1793 Oct 23",    2,  2,  2],
          ["1794 July 27",   2, 11,  9], # the demise of Robespierre
          ["1794 Nov 23",    3,  3,  3],
          ["1795 Oct 5",     4,  1, 13], # Saint-Roch church demonstration
          ["1795 Dec 25",    4,  4,  4],
          ["1797 Jan 24",    5,  5,  5],
          ["1798 Feb 24",    6,  6,  6],
          ["1799 Nov 9",     8,  2, 18], # Bonaparte's coup
          ["1801 Mar 29",    9,  7,  8],
          ["1803 Apr 30",   11,  8, 10],
          ["1804 Apr 30",   12,  8, 10],
          ["1807 Jun 1",    15,  9, 12],
          ["1810 July 3",   18, 10, 14],
          ["1813 Aug 4",    21, 11, 16],
          ["1816 Sep 4",    24, 12, 18],
          ["2000 Jan 1",   208,  4, 12], # Y2K compatible? Will your computer freeze or what?
          ["2001 May 11",  209,  8, 22], # So long, Douglas, and thanks for all the fun
          ["2791 Sep 23", 1000,  1,  1],
          ["2792 Sep 22", 1001,  1,  1],
          ["3791 Sep 22", 2000,  1,  1],
          ["3792 Sep 22", 2001,  1,  1],
          ["4791 Sep 23", 3000,  1,  1],
          ["4792 Sep 22", 3001,  1,  1],
          ["5791 Sep 22", 4000,  1,  1],
          ["5792 Sep 21", 4001,  1,  1],
          ["6791 Sep 22", 5000,  1,  1],
          ["6792 Sep 21", 5001,  1,  1],
          ["7791 Sep 21", 6000,  1,  1],
          ["7792 Sep 21", 6001,  1,  1],
          );

plan(tests => scalar @tests);

foreach (@tests) { r2g @$_ }
