#     Test script for DateTime::Event::Easter
#     Copyright (C) 2003, 2004, 2015, Rick Measham and Jean Forget
#
#     This program is distributed under the same terms as Perl:
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
use strict;

use Test::More tests => 33;

use DateTime::Event::Easter qw/easter/;

my @non_inclusive_expect =        qw|1902-03-30 1903-04-12 1904-04-03
	1905-04-23 1906-04-15 1907-03-31 1908-04-19 1909-04-11 1910-03-27
	1911-04-16 1912-04-07 1913-03-23 1914-04-12 1915-04-04 1916-04-23|;
	
my @inclusive_expect = qw|1917-04-08 1918-03-31 1919-04-20 1920-04-04
	1921-03-27 1922-04-16 1923-04-01 1924-04-20 1925-04-12 1926-04-04
	1927-04-17 1928-04-08 1929-03-31 1930-04-20 1931-04-05 1932-03-27|;

		
my $easter_1901 = DateTime->new(
	year  => 1901,
	month => 4,
	day   => 7,
);

my $easter_1917 = DateTime->new(
	year  => 1917,
	month => 4,
	day   => 8,
);

my $easter_1932 = DateTime->new(
	year  => 1932,
	month => 3,
	day   => 27,
);

my $event_easter_sunday = DateTime::Event::Easter->new();

my @non_inclusive_set = $event_easter_sunday->as_list(from => $easter_1901, to => $easter_1917);
my @inclusive_set = $event_easter_sunday->as_list(from => $easter_1917, to => $easter_1932, inclusive=>1);

is ($#non_inclusive_set, $#non_inclusive_expect, "Non-inclusive: Correct number of results");
for my $i (0 .. $#non_inclusive_set) {
	is( $non_inclusive_set[$i]->ymd, 
		$non_inclusive_expect[$i], 
		"Correct date: $non_inclusive_expect[$i]"
	);
}

is ($#inclusive_set, $#inclusive_expect, "Inclusive: Correct number of results");
for my $i (0 .. $#inclusive_set) {
	is( $inclusive_set[$i]->ymd, 
		$inclusive_expect[$i], 
		"Correct date: $inclusive_expect[$i]"
	);
}



