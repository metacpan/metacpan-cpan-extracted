# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Easter
#     Copyright © 2003-2004, 2015, 2019 Rick Measham and Jean Forget, all rights reserved
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

use Test::More tests => 12;

use DateTime::Event::Easter qw/easter/;

my $easter_sunday_2003 = DateTime->new(
        year  => 2003,
        month => 4,
        day   => 20,
);

my $zone_2003 = DateTime->new(
        year  => 2003,
        month => 10,
        day   => 1,
);

my $pre_zone_2003 = DateTime->new(
        year  => 2003,
        month => 8,
        day   => 1,
);

my $post_zone_2003 = DateTime->new(
        year  => 2003,
        month => 11,
        day   => 1,
);

my $event_easter_sunday = DateTime::Event::Easter->new();

is( $event_easter_sunday->previous( $easter_sunday_2003)->ymd, '2002-03-31', "Easter Sunday 2003: Check the previous" );
is( $event_easter_sunday->following($easter_sunday_2003)->ymd, '2004-04-11', "Easter Sunday 2003: Check the following" );
is( $event_easter_sunday->closest(  $easter_sunday_2003)->ymd, '2003-04-20', "Easter Sunday 2003: Check the closest" );

is( $event_easter_sunday->previous( $zone_2003)->ymd, '2003-04-20', "Zone 2003: Check the previous" );
is( $event_easter_sunday->following($zone_2003)->ymd, '2004-04-11', "Zone 2003: Check the following" );
is( $event_easter_sunday->closest(  $zone_2003)->ymd, '2003-04-20', "Zone 2003: Check the closest" );

is( $event_easter_sunday->previous( $pre_zone_2003)->ymd, '2003-04-20', "Pre-Zone 2003: Check the previous" );
is( $event_easter_sunday->following($pre_zone_2003)->ymd, '2004-04-11', "Pre-Zone 2003: Check the following" );
is( $event_easter_sunday->closest(  $pre_zone_2003)->ymd, '2003-04-20', "Pre-Zone 2003: Check the closest" );

is( $event_easter_sunday->previous( $post_zone_2003)->ymd, '2003-04-20', "Post-Zone 2003: Check the previous" );
is( $event_easter_sunday->following($post_zone_2003)->ymd, '2004-04-11', "Post-Zone 2003: Check the following" );
is( $event_easter_sunday->closest(  $post_zone_2003)->ymd, '2004-04-11', "Post-Zone 2003: Check the closest" );


