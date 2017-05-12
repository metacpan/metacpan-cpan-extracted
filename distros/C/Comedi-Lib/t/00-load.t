#!perl -T
# 
# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#

use Test::More tests => 1;

BEGIN {
	use_ok( 'Comedi::Lib' );
}

diag( "Testing Comedi::Lib $Comedi::Lib::VERSION, Perl $], $^X" );
