use strict;

#     t/01basic.t - checking the various methods
#     Test script for DateTime::Format::Baby
#     Copyright (C) 2003, 2015, 2016 Rick Measham and Jean Forget
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

use Test::More tests => 8;

use DateTime::Format::Baby;

my $dt = DateTime->new(
	year   => 1964,
	month  => 10,
	day    => 16,
	hour   => 16,
	minute => 12,
	second => 47
);

my $baby = DateTime::Format::Baby->new('en');
isa_ok($baby, 'DateTime::Format::Baby', 'Constructor returns a DateTime::Format::Baby object');

is( $baby->format_datetime($dt), 'The big hand is on the two and the little hand is on the four', 'Format English');
is( $baby->language(), 'en', 'language() returns English');

is( $baby->language('fr'), 'fr', 'language("fr") returns French');
is( $baby->format_datetime($dt), 'La grande aiguille est sur le deux et la petite aiguille est sur le quatre', 'Format French');

$baby->language('en'); # Back to English
my $dt2 = $baby->parse_datetime('Big hand is near the seven while the little hand is near the six.');
is ($dt2->hms, "05:35:00", 'Parse English');

is( $baby->language('du'), 'du', 'language("du") returns German');
my $dt3 = $baby->parse_datetime('De grote wijzer is op de twaalf en de kleine wijzer is op de acht');
is ($dt3->hms, "08:00:00", 'Parse German');




