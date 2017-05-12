#!/usr/bin/perl -w
#     t/03datetime.t - checking datetime objects linked to a LMT time zone
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

plan tests => 29;

my $LMT = DateTime::TimeZone::LMT->new( longitude => 150 );
my $LMT_named = DateTime::TimeZone::LMT->new( longitude => 150, name => 'LMT' );
my $dt;

eval { $dt = DateTime->now( time_zone => $LMT ) };
is( $@, '', "Can call DateTime->now with LMT" );

eval { $dt->add( years => 50 ) };
is( $@, '', "Can add 50 years" );

eval { $dt->subtract( years => 400 ) };
is( $@, '', "Can subtract 400 years" );

eval { $dt = DateTime->new( year => 2000, month => 6, hour => 1, time_zone => $LMT ) };
is( $@, '',       'make sure that local time is always respected' );
is( $dt->hour, 1, 'make sure that local time is always respected' );

eval { $dt = DateTime->new( year => 2000, month => 12, hour => 1, time_zone => $LMT ) };
is( $@, '',       'make sure that local time is always respected' );
is( $dt->hour, 1, 'make sure that local time is always respected' );

eval { 
	$dt = DateTime->new( 
		year => 2003, month => 10, day => 18, hour => 1, 
		time_zone => 'Australia/Melbourne', 
	)->set_time_zone( $LMT );
};
is( $@, '',       'make sure that we can convert to LMT' );
is( $dt->hour, 1, 'make sure that we can convert to LMT' );

my $melb = DateTime::TimeZone->new(name => 'Australia/Melbourne');

eval { 
        $dt = DateTime->new( 
                year => 2003, month => 10, day => 18, hour => 1, 
                time_zone => $LMT, 
        )->set_time_zone( $melb );
};
is( $@, '',       'make sure that we can convert from LMT (object) to Olson (object)' );
is( $dt->hour, 1, 'make sure that we can convert from LMT (object) to Olson (object)' );

eval { 
	$dt = DateTime->new( 
		year => 2003, month => 10, day => 18, hour => 1, 
		time_zone => $LMT, 
	)->set_time_zone( 'Australia/Melbourne' );
};
is( $@, '',       'make sure that we can convert from LMT (object) to Olson (name)' );
is( $dt->hour, 1, 'make sure that we can convert from LMT (object) to Olson (name)' );

eval { 
        $dt = DateTime->new( 
                year => 2003, month => 10, day => 18, hour => 1, 
                time_zone => 'LMT', 
        )->set_time_zone( $melb );
};
is( $@, '',       'make sure that we can convert from LMT (name) to Olson (object)' );
is( $dt->hour, 1, 'make sure that we can convert from LMT (name) to Olson (object)' );

eval { 
        $dt = DateTime->new( 
                year => 2003, month => 10, day => 18, hour => 1, 
                time_zone => 'LMT', 
        )->set_time_zone( 'Australia/Melbourne' );
};
is( $@, '',       'make sure that we can convert from LMT (name) to Olson (name)' );
is( $dt->hour, 1, 'make sure that we can convert from LMT (name) to Olson (name)' );

my $float = DateTime::TimeZone->new(name => 'floating');

eval { 
        $dt = DateTime->new( 
                year => 2003, month => 10, day => 18, hour => 1, 
                time_zone => $LMT, 
        )->set_time_zone( $float );
};
is( $@, '',       'make sure that we can convert from LMT (object) to Floating (object)' );
is( $dt->hour, 1, 'make sure that we can convert from LMT (object) to Floating (object)' );

eval { 
	$dt = DateTime->new( 
		year => 2003, month => 10, day => 18, hour => 1, 
		time_zone => $LMT, 
	)->set_time_zone( 'floating' );
};
is( $@, '',       'make sure that we can convert from LMT (object) to Floating (name)' );
is( $dt->hour, 1, 'make sure that we can convert from LMT (object) to Floating (name)' );

eval { 
        $dt = DateTime->new( 
                year => 2003, month => 10, day => 18, hour => 1, 
                time_zone => 'LMT', 
        )->set_time_zone( $float );
};
is( $@, '',       'make sure that we can convert from LMT (name) to Floating (object)' );
is( $dt->hour, 1, 'make sure that we can convert from LMT (name) to Floating (object)' );

eval { 
        $dt = DateTime->new( 
                year => 2003, month => 10, day => 18, hour => 1, 
                time_zone => 'LMT', 
        )->set_time_zone( 'floating' );
};
is( $@, '',       'make sure that we can convert from LMT (name) to Floating (name)' );
is( $dt->hour, 1, 'make sure that we can convert from LMT (name) to Floating (name)' );

eval { 
	$dt = DateTime->new( 
		year => 2003, month => 10, day => 18, hour => 1, 
		time_zone => $LMT, 
	)
	->set_time_zone( 'floating' )
	->set_time_zone( 'Australia/Melbourne' );
};
is( $@, '',       'make sure that we can convert from LMT to Floating to Olson' );
is( $dt->hour, 1, 'make sure that we can convert from LMT to Floating to Olson' );

eval { 
	$dt = DateTime->new( 
		year => 2003, month => 10, day => 18, hour => 1, 
		time_zone => $LMT, 
	)->set_time_zone( 'UTC' );
};
is( $@, '',        'make sure that we can convert from LMT to UTC' );
is( $dt->hour, 15, 'make sure that we can convert from LMT to UTC' );





