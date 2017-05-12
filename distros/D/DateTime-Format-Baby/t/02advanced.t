#     t/02advanced.t - checking advanced features of the various methods
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

use strict;
use Test::More;
use DateTime::Format::Baby;

my @data = ( [ 16, 29, 28, 'The big hand is on the six and the little hand is on the four',      'a bit before thirty', '04:30:00' ],
             [ 16, 32, 28, 'The big hand is on the six and the little hand is on the five',      'a bit past thirty',   '05:30:00' ],
             [ 16, 34, 28, 'The big hand is on the seven and the little hand is on the five',    'past thirty',         '04:35:00' ],
             [ 16, 58, 28, 'The big hand is on the twelve and the little hand is on the five',   'before the hour',     '05:00:00' ],
             [ 17, 02, 28, 'The big hand is on the twelve and the little hand is on the five',   'just after the hour', '05:00:00' ],
             [ 23, 58, 28, 'The big hand is on the twelve and the little hand is on the twelve', 'around midnight',     '12:00:00' ],
             [ 00, 02, 28, 'The big hand is on the twelve and the little hand is on the twelve', 'around midnight',     '12:00:00' ],
           );

my $baby = DateTime::Format::Baby->new('en');

plan(tests => 2 * @data);

foreach my $data (@data) {
  my ($hh, $mm, $ss, $expect1, $comment, $expect2) = @$data;

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

  my $dt2 = $baby->parse_datetime($result);
  is ($dt2->hms, $expect2, 'parsing: ' . $comment);
}
