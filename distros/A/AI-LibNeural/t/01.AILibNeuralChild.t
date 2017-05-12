#
# $Header$
#
# this is based off of code that i based off of other modules i've found in the
# distant past. if you are the original author and you recognize this code let
# me know and you'll be credited
#
# Copyright (C) 2003 by Ross McFarland
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
# 
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the 
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307  USA.
#

#########################
use strict;

use Test::More tests => 31;
BEGIN { use_ok('AI::LibNeural', ':all') };
#########################

package AI::LibNeural::Child;

our @ISA = qw(AI::LibNeural);

package main;

my $nn;
ok( $nn = AI::LibNeural::Child->new( 2, 4, 1 ) );
ok( $nn =~ m/AI::LibNeural::Child=SCALAR(.*)/ );
ok( ALL == 0 );
ok( INPUT == 1 );
ok( HIDDEN == 2 );
ok( OUTPUT == 3 );
ok( $nn->get_layersize(ALL) == 7 );
ok( $nn->get_layersize(INPUT) == 2 );
ok( $nn->get_layersize(HIDDEN) == 4 );
ok( $nn->get_layersize(OUTPUT) == 1 );
for( my $i = 0; $i < 20; $i++ )
{
	$nn->train( [ 0, 0 ], [ 0.05 ], 0.0000000005, 0.2 );
	$nn->train( [ 0, 1 ], [ 0.05 ], 0.0000000005, 0.2 );
	$nn->train( [ 1, 0 ], [ 0.05 ], 0.0000000005, 0.2 );
	$nn->train( [ 1, 1 ], [ 0.95 ], 0.0000000005, 0.2 );
}
ok(1);
ok( $nn->run( [ 0, 0 ] ) < 0.5 );
ok( $nn->run( [ 0, 1 ] ) < 0.5 );
ok( $nn->run( [ 1, 0 ] ) < 0.5 );
ok( $nn->run( [ 1, 1 ] ) > 0.5 );
ok( $nn->save('test.mem') );

$nn = undef;
ok( $nn = AI::LibNeural::Child->new() );
ok( $nn =~ m/AI::LibNeural::Child=SCALAR(.*)/ );
ok( $nn->load('test.mem') );
ok( $nn->run( [ 0, 0 ] ) < 0.5 );
ok( $nn->run( [ 0, 1 ] ) < 0.5 );
ok( $nn->run( [ 1, 0 ] ) < 0.5 );
ok( $nn->run( [ 1, 1 ] ) > 0.5 );

$nn = undef;
ok( $nn = AI::LibNeural::Child->new('test.mem') );
ok( $nn =~ m/AI::LibNeural::Child=SCALAR(.*)/ );
ok( $nn->run( [ 0, 0 ] ) < 0.5 );
ok( $nn->run( [ 0, 1 ] ) < 0.5 );
ok( $nn->run( [ 1, 0 ] ) < 0.5 );
ok( $nn->run( [ 1, 1 ] ) > 0.5 );
unlink('test.mem') if( -e 'test.mem' );

ok(1)
