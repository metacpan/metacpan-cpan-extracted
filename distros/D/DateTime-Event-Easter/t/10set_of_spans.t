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

use Test::More;

use DateTime::Event::Easter qw/easter/;

my @non_inclusive_expect = qw|1902-03-30 1903-04-12 1904-04-03
        1905-04-23 1906-04-15 1907-03-31 1908-04-19 1909-04-11 1910-03-27
        1911-04-16 1912-04-07 1913-03-23 1914-04-12 1915-04-04 1916-04-23|;

my @inclusive_expect     = qw|1917-04-08 1918-03-31 1919-04-20 1920-04-04
        1921-03-27 1922-04-16 1923-04-01 1924-04-20 1925-04-12 1926-04-04
        1927-04-17 1928-04-08 1929-03-31 1930-04-20 1931-04-05 1932-03-27|;

plan(tests => 3 + @non_inclusive_expect + @inclusive_expect);

my $easter_1901 = DateTime->new(
        year  => 1901,
        month =>    4,
        day   =>    7,
);

my $easter_1917 = DateTime->new(
        year  => 1917,
        month =>    4,
        day   =>    8,
);

my $easter_1932 = DateTime->new(
        year  => 1932,
        month =>    3,
        day   =>   27,
);

my $event_easter_sunday = DateTime::Event::Easter->new(as => 'span');

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
my $non_inclusive_iterator = $non_inclusive_set->iterator;
while ( my $span = $non_inclusive_iterator->next ) {

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
my $inclusive_iterator = $inclusive_set->iterator;
while ( my $span = $inclusive_iterator->next ) {

  my ($yyyy, $mm, $dd) = $inclusive_expect[$i] =~ /^(\d{4})-(\d\d)-(\d\d)$/;
  my $dt = DateTime->new(year => $yyyy, month => $mm, day => $dd);

  ok( $span->contains($dt),
      "Correct date: $inclusive_expect[$i]"
  );
  $i++;

};

