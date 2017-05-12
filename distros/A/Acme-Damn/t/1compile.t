#!/usr/bin/perl -w
# $Id: 1compile.t,v 1.1 2003-06-08 13:20:13 ian Exp $

# compile.t
#
# Ensure the module compiles.

use strict;
use Test::More tests => 2;

# make sure the module compiles
BEGIN { use_ok( 'Acme::Damn' ) }

# make sure damn() is in the current namespace
{
	no strict 'refs';

	ok( ref( *{ 'main::damn' }{ CODE } ) eq 'CODE' , "Yep" );
}
