# --8<--8<--8<--8<--
#
# Copyright (C) 2006 Smithsonian Astrophysical Observatory
#
# This file is part of CIAO-Lib-Param
#
# CIAO-Lib-Param is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# CIAO-Lib-Param is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the 
#       Free Software Foundation, Inc. 
#       51 Franklin Street, Fifth Floor
#       Boston, MA  02110-1301, USA
#
# -->8-->8-->8-->8--

use Test::More tests => 14;

use File::Path;
BEGIN { use_ok('CIAO::Lib::Param') };

use strict;
use warnings;

rmtree('tmp');
$ENV{PFILES} = "tmp;param";
mkdir( 'tmp', 0755 );

our $pf;
our $value;

eval { 
     $pf = CIAO::Lib::Param->new( "surface_intercept", "rH" );
};
ok( !$@, "new" )
  or diag($@);

# make sure boolean transformations in get() work like in getb()
ok( 1 == $pf->getb( 'onlygoodrays' ), "getb: true" );
ok( 1 == $pf->get( 'onlygoodrays' ),  "get boolean: true" );
ok( 0 == $pf->getb( 'help' ), "getb: false" );
ok( 0 == $pf->get( 'help' ),  "get boolean: false" );

# now try different ways of setting booleans. Since the parameter file
# has been opened in non-prompt mode (H), we'll get croaks on error

eval { 
     $pf->set('help', 'frob');
};
ok( $@,  "set boolean: bad string" );

eval { 
     $pf->set('help', 'yes');
};
ok( !$@ && 1 == $pf->get('help'),  'set: yes' );

eval { 
     $pf->set('help', 'no');
};
ok( !$@ && 0 == $pf->get('help'),  'set: no' );


# now try boolean numerics to test automatic conversion
$pf->set( 'help', 'yes' );
eval {
     $pf->set('help', 0 );
};
ok( !$@ && 0 == $pf->get('help'),  'set: 0' );

$pf->set( 'help', 'no' );
eval {
     $pf->set('help', 1 );
};
ok( !$@ && 1 == $pf->get('help'),  'set: 1' );

$pf->set( 'help', 'yes' );
eval {
    no warnings;
    $pf->set('help', undef );
};
ok( !$@ && 0 == $pf->get('help'),  'set: undef' );


# check if Perl yes/no values are handled correctly.
# these are used by the get method

$pf->set('help', 0 );
$value = $pf->get( 'help' );
$pf->set('help', 1 );
$pf->set( 'help', $value );
ok( 0 == $pf->get('help'),  'set: get(no)' );

$pf->set('help', 1 );
$value = $pf->get( 'help' );
$pf->set('help', 0 );
$pf->set( 'help', $value );
ok( 1 == $pf->get('help'),  'set: get(yes)' );

