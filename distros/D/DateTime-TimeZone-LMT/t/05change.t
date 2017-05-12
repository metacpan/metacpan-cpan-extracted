#!/usr/bin/perl -w
#     t/05change.t - checking modifications of a LMT time zone
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

use File::Spec;
use Test::More;

use lib File::Spec->catdir( File::Spec->curdir, 't' );

use DateTime::TimeZone::LMT;

plan tests => 9;

my $LMT = new DateTime::TimeZone::LMT( longitude => 150 );
my $dt;

is( $LMT->longitude, 150, "We get the correct longitude returned" );

eval { $LMT->longitude(180) };
is( $@, '', "We can change the longitude" );
is( $LMT->offset, '+1200', "And the offset changes");
is( $LMT->longitude, 180, "And get the right response");

is( $LMT->longitude(120), 120, "We get the right response in a set-and-read");

eval { $LMT->name('new name') };
is( $@, '', "We can change the name" );
is( $LMT->name, 'new name', "And the name changes");
is( $LMT->longitude, 120, "But the longitude doesn't");
is( $LMT->offset, '+0800', "Nor does the offset");




