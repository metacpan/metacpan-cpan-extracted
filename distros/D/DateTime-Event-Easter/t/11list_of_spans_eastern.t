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
#     The purpose of this test file, compared to C<09list_of_spans.t>, is to check
#     that the use of C<DateTime::Calendar::Julian> instead of C<DateTime> does not
#     play havoc with the internals of C<as_list>

use strict;
use warnings;

use Test::More;

use DateTime::Event::Easter qw/easter/;


my $begin = DateTime->new( year => 2018, month => 4, day =>  8);
my $end   = DateTime->new( year => 2021, month => 5, day =>  2);

my @dates_in    = ([2019, 4, 28], [2020, 4, 19]);
my @dates_out   = ([2018, 4,  7], [2018, 4,  9], [2019, 4, 27], [2019, 4, 29], [2020, 4, 18], [2020, 4, 20], [2021, 5, 1], [2021, 5, 3]);
my @dates_maybe = ([2018, 4,  8], [2021, 5,  2]);

my @hours       = ([0, 0, 0, 0], [12, 0, 0, 0], [23, 59, 59, 999_999_999]);

plan(tests => 2 * @hours * (@dates_in + @dates_out + @dates_maybe));

my $event_easter_sunday = DateTime::Event::Easter->new(
        day    => 'easter sunday',
        as     => 'span',
        easter => 'eastern',
);

my @exclusive = $event_easter_sunday->as_list(from => $begin, to => $end);
my @inclusive = $event_easter_sunday->as_list(from => $begin, to => $end, inclusive => 1);

check( \@exclusive, [ @dates_in                ], 1,  " within span of exclusive list" );
check( \@exclusive, [ @dates_out, @dates_maybe ], 0, " outside span of exclusive list");
check( \@inclusive, [ @dates_in,  @dates_maybe ], 1,  " within span of inclusive list" );
check( \@inclusive, [ @dates_out               ], 0, " outside span of inclusive list");

sub check {
  my ($ref_list, $ref_dates, $expected, $msg) = @_;
  my @list  = @$ref_list;
  my @dates = @$ref_dates;
  for (@dates) {
    my ($yyyy, $mm, $dd) = @$_;
    for (@hours) {
      my ($hr, $mn, $s, $ns) = @$_;
      my $date = DateTime->new(year => $yyyy, month => $mm, day => $dd, hour => $hr, minute => $mn, second => $s, nanosecond => $ns);
      my $found = 0;
      for my $span (@list) {
        if ($span->contains($date)) {
          $found = 1;
          last;
        }
      }
      ok ($found == $expected, $date->datetime . $msg);
    }
  }
}


