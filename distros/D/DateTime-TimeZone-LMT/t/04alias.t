#!/usr/bin/perl -w
#     t/04alias.t - checking alias creation and usage for LMT time zones
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

plan tests => 8;

my $LMT = new DateTime::TimeZone::LMT( longitude => 150 );
my $dt;

eval { $LMT->make_alias() };
is( $@, '', "Can make a TimeZone alias for default name LMT" );

eval { $LMT->make_alias('Longitude') };
is( $@, '', "Can make a TimeZone alias for custom name" );

eval { $dt = DateTime->now( time_zone => 'LMT' ) };
is( $@, '', "Can call DateTime->now with LMT" );

eval { $dt = DateTime->now( time_zone => 'Longitude' ) };
is( $@, '', "Can call DateTime->now with custom name" );

eval { 
	$dt = DateTime->new( 
		year => 2003, month => 10, day => 18, hour => 1, 
		time_zone => 'Longitude', 
	)->set_time_zone( 'Australia/Melbourne' );
};
is( $@, '',       'make sure that we can convert alias to Olson' );
is( $dt->hour, 1, 'make sure that we can convert alias to Olson' );

eval { 
	$dt = DateTime->new( 
		year => 2003, month => 10, day => 18, hour => 1, 
		time_zone => 'Longitude', 
	)->set_time_zone( 'LMT' );
};
is( $@, '',       'make sure that we can convert custom name to LMT' );
is( $dt->hour, 1, 'make sure that we can convert custom name to LMT' );



