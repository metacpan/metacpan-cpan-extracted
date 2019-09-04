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

my $post_easter_2003 = DateTime->new(
        year  => 2003,
        month => 8,
        day   => 28,
);

my $event_easter_sunday = DateTime::Event::Easter->new(day=>'easter sunday');
is( $event_easter_sunday->previous($post_easter_2003)->ymd, 
        '2003-04-20', 
        "Day: Easter Sunday is correct",
);

my $event_black_saturday = DateTime::Event::Easter->new(day=>'black saturday');
is( $event_black_saturday->previous($post_easter_2003)->ymd, 
        '2003-04-19', 
        "Day: Black Saturday is correct",
);

my $event_good_friday = DateTime::Event::Easter->new(day=>'good friday');
is( $event_good_friday->previous($post_easter_2003)->ymd, 
        '2003-04-18', 
        "Day: Good Friday is correct",
);

my $event_maundy_thursday = DateTime::Event::Easter->new(day=>'maundy thursday');
is( $event_maundy_thursday->previous($post_easter_2003)->ymd, 
        '2003-04-17', 
        "Day: Maundy Thursday is correct",
);

my $event_palm_sunday = DateTime::Event::Easter->new(day=>'palm sunday');
is( $event_palm_sunday->previous($post_easter_2003)->ymd, 
        '2003-04-13', 
        "Day: Palm Sunday is correct",
);

my $event_fat_tuesday = DateTime::Event::Easter->new(day=>'fat tuesday');
is( $event_fat_tuesday->previous($post_easter_2003)->ymd, 
        '2003-03-04', 
        "Day: Fat Tuesday is correct",
);

my $event_ash_wednesday = DateTime::Event::Easter->new(day=>'ash wednesday');
is( $event_ash_wednesday->previous($post_easter_2003)->ymd, 
        '2003-03-05', 
        "Day: Ash Wednesday is correct",
);


my $event_ascension = DateTime::Event::Easter->new(day=>'ascension');
is( $event_ascension->previous($post_easter_2003)->ymd, 
        '2003-05-29', 
        "Day: Ascension is correct",
);

my $event_pentecost = DateTime::Event::Easter->new(day=>'pentecost');
is( $event_pentecost->previous($post_easter_2003)->ymd, 
        '2003-06-08', 
        "Day: Pentecost is correct",
);

my $event_trinity_sunday = DateTime::Event::Easter->new(day=>'trinity sunday');
is( $event_trinity_sunday->previous($post_easter_2003)->ymd, 
        '2003-06-15', 
        "Day: Trinity Sunday is correct",
);

my $event_pentecost1 = DateTime::Event::Easter->new(day=>49);
is( $event_pentecost1->previous($post_easter_2003)->ymd, 
        '2003-06-08', 
        "Day: +49 is correct",
);

my $event_ash_wednesday1 = DateTime::Event::Easter->new(day=>-46);
is( $event_ash_wednesday1->previous($post_easter_2003)->ymd, 
        '2003-03-05', 
        "Day: -46 is correct",
);

