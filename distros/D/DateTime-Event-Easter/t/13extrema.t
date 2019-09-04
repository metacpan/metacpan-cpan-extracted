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

use DateTime::Event::Easter;

# Source: the table on page 149 of "La saga des calendriers", by Jean Lefort,
# published by "Pour la Science", ISBN 2-90929-003-5
#
# Note that there are a few mistakes in this table. For example, the entry
# for 1758 is a black printed 26 and the entry for 2236 is a black printed 27,
# which translate as 1758-04-26 and 2236-04-27, while actually the easter dates
# for those two years are 1758-03-26 and 2236-03-27 (black ink means April, blue
# ink means March in this table).
my @data = (
    [ qw< 1693   1693-01-01   1693-03-22   1693-11-27 > ], 
    [ qw< 1818   1818-01-01   1818-03-22   1818-11-27 > ], 
    [ qw< 2353   2353-01-01   2353-03-22   2353-11-27 > ], 
    [ qw< 2437   2437-01-01   2437-03-22   2437-11-27 > ], 
    [ qw< 2505   2505-01-01   2505-03-22   2505-11-27 > ], 
    [ qw< 1666   1666-02-04   1666-04-25   1666-12-31 > ], 
    [ qw< 1734   1734-02-04   1734-04-25   1734-12-31 > ], 
    [ qw< 1886   1886-02-04   1886-04-25   1886-12-31 > ], 
    [ qw< 1943   1943-02-04   1943-04-25   1943-12-31 > ], 
    [ qw< 2038   2038-02-04   2038-04-25   2038-12-31 > ], 
    [ qw< 2190   2190-02-04   2190-04-25   2190-12-31 > ], 
    [ qw< 2258   2258-02-04   2258-04-25   2258-12-31 > ], 
    [ qw< 2326   2326-02-04   2326-04-25   2326-12-31 > ], 
    [ qw< 2410   2410-02-04   2410-04-25   2410-12-31 > ], 
  );

plan(tests => 3 * @data);

my $easter      = DateTime::Event::Easter->new();
my $january_one = DateTime::Event::Easter->new(day =>  -80);
my $december_31 = DateTime::Event::Easter->new(day =>  250);

foreach (@data) {
  my ($y, $jan, $eas, $dec) = @$_;
  my $ref = DateTime->new(year => $y - 1, month => 12, day => 31);
  is($january_one->following($ref)->ymd, $jan, "Correct -80 offset for $y");
  is($easter     ->following($ref)->ymd, $eas, "Correct easter     for $y");
  is($december_31->following($ref)->ymd, $dec, "Correct 250 offset for $y");
}

