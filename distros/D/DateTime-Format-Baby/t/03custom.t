#     t/03custom.t - checking the customization of the language
#     Test script for DateTime::Format::Baby
#     Copyright (C) 2015, 2016, Rick Measham and Jean Forget
#     with some code taken from Acme::Time::Baby
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
use Test::More;
use DateTime::Format::Baby;

my @data1 = ( [ 16, 29, 28, 'The big hand is on the Pumpkin and the little hand is on the Garlic',        'a bit before thirty', '04:30:00' ],
              [ 16, 32, 28, 'The big hand is on the Pumpkin and the little hand is on the Green Onion',   'a bit past thirty',   '05:30:00' ],
              [ 16, 34, 28, 'The big hand is on the Asparagus and the little hand is on the Green Onion', 'past thirty',         '04:35:00' ],
              [ 16, 58, 28, 'The big hand is on the Cabbage and the little hand is on the Green Onion',   'before the hour',     '05:00:00' ],
              [ 17, 02, 28, 'The big hand is on the Cabbage and the little hand is on the Green Onion',   'just after the hour', '05:00:00' ],
              [ 23, 58, 28, 'The big hand is on the Cabbage and the little hand is on the Cabbage',       'around midnight',     '12:00:00' ],
              [ 00, 02, 28, 'The big hand is on the Cabbage and the little hand is on the Cabbage',       'around midnight',     '12:00:00' ],
            );

my @data2 = ( [ 16, 29, 28, 'The fork is on the Pumpkin and the spoon is on the Garlic',        'a bit before thirty', '04:30:00' ],
              [ 16, 32, 28, 'The fork is on the Pumpkin and the spoon is on the Green Onion',   'a bit past thirty',   '05:30:00' ],
              [ 16, 34, 28, 'The fork is on the Asparagus and the spoon is on the Green Onion', 'past thirty',         '04:35:00' ],
              [ 16, 58, 28, 'The fork is on the Cabbage and the spoon is on the Green Onion',   'before the hour',     '05:00:00' ],
              [ 17, 02, 28, 'The fork is on the Cabbage and the spoon is on the Green Onion',   'just after the hour', '05:00:00' ],
              [ 23, 58, 28, 'The fork is on the Cabbage and the spoon is on the Cabbage',       'around midnight',     '12:00:00' ],
              [ 00, 02, 28, 'The fork is on the Cabbage and the spoon is on the Cabbage',       'around midnight',     '12:00:00' ],
            );

plan(tests => 2 * (@data1 + @data2));

# See Rich Bowen's http://drbacchus.com/images/clock.jpg
my $baby1 = DateTime::Format::Baby->new(language => 'en',
                                        numbers  => [ 'Tomato',      'Eggplant',        'Carrot',     'Garlic',
                                                      'Green Onion', 'Pumpkin',         'Asparagus',  'Onion',
                                                      'Corn',        'Brussels Sprout', 'Red Pepper', 'Cabbage',
                                                      ]
);
my $baby2 = DateTime::Format::Baby->new(language => 'en',
                                     ,  numbers  => [ 'Tomato',      'Eggplant',        'Carrot',     'Garlic',
                                                      'Green Onion', 'Pumpkin',         'Asparagus',  'Onion',
                                                      'Corn',        'Brussels Sprout', 'Red Pepper', 'Cabbage',
                                                    ]
                                     ,  big      => [ 'fork' ]
                                     ,  little   => [ 'spoon' ]
                                     ,  format   => "The fork is on the %s and the spoon is on the %s"
);

foreach my $data (@data1) {
  my ($hh, $mm, $ss, $expect1, $comment, $expect2) = @$data;

  my $dt = DateTime->new(
        year   => 1964,
        month  => 10,
        day    => 16,
        hour   => $hh,
        minute => $mm,
        second => $ss
      );

  my $result = $baby1->format_datetime($dt);
  is( $result, $expect1, 'format:  ' . $comment);

  my $dt2 = $baby1->parse_datetime($result);
  is ($dt2->hms, $expect2, 'parsing: ' . $comment);
}

foreach my $data (@data2) {
  my ($hh, $mm, $ss, $expect1, $comment, $expect2) = @$data;

  my $dt = DateTime->new(
        year   => 1964,
        month  => 10,
        day    => 16,
        hour   => $hh,
        minute => $mm,
        second => $ss
      );

  my $result = $baby2->format_datetime($dt);
  is( $result, $expect1, 'format:  ' . $comment);

  my $dt2 = $baby2->parse_datetime($result);
  is ($dt2->hms, $expect2, 'parsing: ' . $comment);
}
