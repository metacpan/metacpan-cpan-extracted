# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Test script for DateTime::Event::Sunrise
#     Copyright (C) 2003, 2004, 2013 Ron Hill and Jean Forget
#
#     This program is distributed under the same terms as Perl 5.16.3:
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
#     Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#
use strict;
use POSIX qw(floor ceil);
use Test::More;
use DateTime;
use DateTime::Duration;
use DateTime::Span;
use DateTime::SpanSet;
use DateTime::Event::Sunrise;

my $fudge = 2;
plan tests => 2;
my $dt = DateTime->new( year   => 2015,
                        month  =>   11,
                        day    =>   27,
                         );
my $dt2 = DateTime->new( year   => 2015,
                         month  =>   11,
                         day    =>   27,
                          );

my $sunrise = DateTime::Event::Sunrise ->sunrise(
                     longitude  =>'177',
                     latitude   => '-37.66667',
                     altitude   => 6,
                     precise    => 1,
);
my $sunset = DateTime::Event::Sunrise ->sunset(
                     longitude  =>'177',
                     latitude   => '-37.66667',
                     altitude   => 6,
                     precise    => 1,
                     );

my $tmp_rise = $sunrise->current($dt2);
my $tmp_set  = $sunset->current($dt);

is ($tmp_rise->datetime, '2015-11-26T17:21:45', 'current sunrise');
is ($tmp_set->datetime,  '2015-11-27T06:33:22', 'current sunset');

