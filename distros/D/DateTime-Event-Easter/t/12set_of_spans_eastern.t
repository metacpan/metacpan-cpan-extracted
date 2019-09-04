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
#     The purpose of this test file, compared to C<10set_of_spans.t>, is to check
#     that the use of C<DateTime::Calendar::Julian> instead of C<DateTime> does not
#     play havoc with the internals of C<as_set> and C<DateTime::SpanSet>

use strict;
use warnings;

use Test::More;

use DateTime::Event::Easter qw/easter/;

my @non_inclusive_expect = qw|1902-04-27 1903-04-19 1904-04-10
        1905-04-30 1906-04-15 1907-05-05 1908-04-26 1909-04-11 1910-05-01
        1911-04-23 1912-04-07 1913-04-27 1914-04-19 1915-04-04 1916-04-23|;

my @inclusive_expect     = qw|1917-04-15 1918-05-05 1919-04-20 1920-04-11
        1921-05-01 1922-04-16 1923-04-08 1924-04-27 1925-04-19 1926-05-02
        1927-04-24 1928-04-15 1929-05-05 1930-04-20 1931-04-12 1932-05-01|;

plan(tests => 3 + @non_inclusive_expect + @inclusive_expect);

my $easter_1901 = DateTime->new(
        year  => 1901,
        month =>    4,
        day   =>   14,
);

my $easter_1917 = DateTime->new(
        year  => 1917,
        month =>    4,
        day   =>   15,
);

my $easter_1932 = DateTime->new(
        year  => 1932,
        month =>    5,
        day   =>    1,
);

my $event_easter_sunday = DateTime::Event::Easter->new(as => 'span', easter => 'eastern');

my $non_inclusive_set = $event_easter_sunday->as_set(from => $easter_1901, to => $easter_1917);
my $inclusive_set     = $event_easter_sunday->as_set(from => $easter_1917, to => $easter_1932, inclusive => 1);

# Check new set integration functionality:

my $non_inclusive_new_set = $event_easter_sunday->as_set(after => $easter_1901, before => $easter_1917);
my $empty_set = $non_inclusive_set->complement($non_inclusive_new_set);
ok ($empty_set->is_empty_set, "Full DateTime::Set integration: Matching Sets");


# Check the number of elements in the set
my @ni_set = $non_inclusive_set->as_list();
is ($#ni_set, $#non_inclusive_expect, "Non-inclusive: Correct number of results");

my $i = 0;
my $non_inclusive_interator = $non_inclusive_set->iterator;
while ( my $span = $non_inclusive_interator->next ) {

  my ($yyyy, $mm, $dd) = $non_inclusive_expect[$i] =~ /^(\d{4})-(\d\d)-(\d\d)$/;
  my $dt = DateTime->new(year => $yyyy, month => $mm, day => $dd);

  ok( $span->contains($dt),
      "Correct date: $non_inclusive_expect[$i]"
  );
  $i++;

};

my @i_set = $inclusive_set->as_list();
is ($#i_set, $#inclusive_expect, "Inclusive: Correct number of results");
$i = 0;
my $inclusive_interator = $inclusive_set->iterator;
while ( my $span = $inclusive_interator->next ) {

  my ($yyyy, $mm, $dd) = $inclusive_expect[$i] =~ /^(\d{4})-(\d\d)-(\d\d)$/;
  my $dt = DateTime->new(year => $yyyy, month => $mm, day => $dd);

  ok( $span->contains($dt),
      "Correct date: $inclusive_expect[$i]"
  );
  $i++;

};

