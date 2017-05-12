#!/usr/bin/perl -w
#     t/02basic.t - checking time zone creation and usage
#     Test script for DateTime::TimeZone::LMT
#     Copyright (C) 2003, 2016 Rick Measham and Jean Forget
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
use warnings;
use File::Spec;
use Test::More;
use DateTime;

use lib File::Spec->catdir( File::Spec->curdir, 't' );

use DateTime::TimeZone::LMT;

plan tests => 9 * 13;

my $date_jan = DateTime->new(year => 2016, month => 1, day => 1);
my $date_jul = DateTime->new(year => 2016, month => 7, day => 1);

for (my $long=0; $long <= 360; $long+=30) {
  my $tz = DateTime::TimeZone::LMT->new( 
    longitude => $long-180, 
  );
  isa_ok( $tz, 'DateTime::TimeZone::LMT' );
  is( $tz->longitude,                      $long-180, 'Longitude is remembered' );
  is( $tz->is_floating,                    0,         'should not be floating' );
  is( $tz->is_utc,                         0,         'should not be UTC' );
  is( $tz->is_olson,                       0,         'should not be based on Olson database' );
  is( $tz->category,                       'Solar',   'should be based on sun movement, more or less' );
  is( $tz->short_name_for_datetime,        'LMT',     'short name' );
  is( $tz->is_dst_for_datetime($date_jan), 0,         'no DST in January' );
  is( $tz->is_dst_for_datetime($date_jul), 0,         'no DST in July' );
}
