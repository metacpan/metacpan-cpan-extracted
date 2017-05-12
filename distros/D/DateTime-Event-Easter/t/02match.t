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

use Test::More tests => 4;

use DateTime::Event::Easter qw/easter/;

my $easter_sunday_2003 = DateTime->new(
	year  => 2003,
	month => 4,
	day   => 20,
);

my $event_easter_sunday = DateTime::Event::Easter->new(day=>'easter sunday');
my $event_sunday = DateTime::Event::Easter->new(day=>'sunday');

my $event_black_saturday = DateTime::Event::Easter->new(day=>'black saturday');
my $event_saturday = DateTime::Event::Easter->new(day=>'saturday');

my $event_good_friday = DateTime::Event::Easter->new(day=>'good friday');
my $event_friday = DateTime::Event::Easter->new(day=>'friday');

my $event_maundy_thursday = DateTime::Event::Easter->new(day=>'maundy thursday');
my $event_thursday = DateTime::Event::Easter->new(day=>'thursday');

is( $event_easter_sunday->previous($easter_sunday_2003), 
	$event_sunday->previous($easter_sunday_2003), 
	"Day: Easter Sunday & Sunday match",
);

is( $event_black_saturday->previous($easter_sunday_2003), 
	$event_saturday->previous($easter_sunday_2003), 
	"Day: Black Saturday & Saturday match",
);

is( $event_good_friday->previous($easter_sunday_2003), 
	$event_friday->previous($easter_sunday_2003), 
	"Day: Easter Sunday & Sunday match",
);

is( $event_maundy_thursday->previous($easter_sunday_2003), 
	$event_thursday->previous($easter_sunday_2003), 
	"Day: Easter Sunday & Sunday match",
);


