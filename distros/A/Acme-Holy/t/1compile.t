# $Id: 1compile.t,v 1.2 2003/06/16 02:09:01 ian Exp $

# compile.t
#
# Ensure the module compiles.

use strict;
use Test::More tests => 2;

# make sure the module compiles
BEGIN { use_ok( 'Acme::Holy' ) }

# make sure holy() is in the current namespace
{
	no strict 'refs';

	ok( ref( *{ 'main::holy' }{ CODE } ) eq 'CODE' , "holy() imported" );
}
