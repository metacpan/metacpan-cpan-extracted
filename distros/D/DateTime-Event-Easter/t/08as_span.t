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

use Test::More tests => 8;

use DateTime::Event::Easter qw/easter/;

my $post_easter_2003 = DateTime->new(
        year  => 2003,
        month => 8,
        day   => 28,
);
my $just_before = DateTime->new(
        year => 2003, month  => 4,  day    => 19,
        hour => 23,   minute => 59, second => 59, nanosecond => 999999999
);
my $just_after = DateTime->new(
        year => 2003, month  => 4,  day    => 21,
        hour => 0,    minute => 0,  second => 0,  nanosecond => 1
);



my $event_easter_sunday = DateTime::Event::Easter->new(
        day => 'easter sunday',
        as  => 'span',
);

my $span_easter_sunday = $event_easter_sunday->previous($post_easter_2003);

is( $span_easter_sunday->min->datetime, 
        '2003-04-20T00:00:00', 
        "Easter Sunday span starts at midnight",
);

is( $span_easter_sunday->max->datetime, 
        '2003-04-21T00:00:00', 
        "Easter Sunday span end at following midnight",
);

is( $span_easter_sunday->contains( $just_before ), 
        0,
        "Previous dates are not included",
);

is( $span_easter_sunday->contains( $just_after ), 
        0,
        "Following dates are not included",
);

$event_easter_sunday->as_point();

$span_easter_sunday = $event_easter_sunday->previous($post_easter_2003);
ok(   $span_easter_sunday->isa("DateTime"),       "Result is a DateTime object");
ok( ! $span_easter_sunday->isa("DateTime::Span"), "Result is no longer a span");

$event_easter_sunday->as_span();

$span_easter_sunday = $event_easter_sunday->previous($span_easter_sunday);
ok( ! $span_easter_sunday->isa("DateTime"),       "Result is no longer a DateTime object");
ok(   $span_easter_sunday->isa("DateTime::Span"), "Result is again a span");
