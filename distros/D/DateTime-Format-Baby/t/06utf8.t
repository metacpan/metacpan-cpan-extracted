#     t/05utf8.t - checking the UTF-8 strings
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

use utf8;
use strict;
use Test::More;
use DateTime::Format::Baby;

my @data = ( [ 16, 29, 28, 'Der große Zeiger ist auf der Sechs und der kleine Zeiger ist auf der Vier',  73, 'a bit before thirty', '04:30:00' ],
             [ 16, 32, 28, 'Der große Zeiger ist auf der Sechs und der kleine Zeiger ist auf der Fünf',  73, 'a bit past thirty',   '05:30:00' ],
             [ 16, 34, 28, 'Der große Zeiger ist auf der Sieben und der kleine Zeiger ist auf der Fünf', 74, 'past thirty',         '04:35:00' ],
             [ 16, 58, 28, 'Der große Zeiger ist auf der Zwölf und der kleine Zeiger ist auf der Fünf',  73, 'before the hour',     '05:00:00' ],
             [ 17, 02, 28, 'Der große Zeiger ist auf der Zwölf und der kleine Zeiger ist auf der Fünf',  73, 'just after the hour', '05:00:00' ],
             [ 23, 58, 28, 'Der große Zeiger ist auf der Zwölf und der kleine Zeiger ist auf der Zwölf', 74, 'around midnight',     '12:00:00' ],
             [ 00, 02, 28, 'Der große Zeiger ist auf der Zwölf und der kleine Zeiger ist auf der Zwölf', 74, 'around midnight',     '12:00:00' ],
           );

plan(tests => 3 * @data);

my $baby = DateTime::Format::Baby->new(language => 'de');

foreach my $data (@data) {
  my ($hh, $mm, $ss, $expect1, $length, $comment, $expect2) = @$data;

  my $dt = DateTime->new(
        year   => 1964,
        month  => 10,
        day    => 16,
        hour   => $hh,
        minute => $mm,
        second => $ss
      );

  my $result = $baby->format_datetime($dt);
  is( $result, $expect1, 'format:  ' . $comment);
  is( length($result), $length, "length: $comment");

  my $dt2 = $baby->parse_datetime($result);
  is ($dt2->hms, $expect2, 'parsing: ' . $comment);
}
