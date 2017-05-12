#!/usr/bin/perl
#
use strict ;
use Test::More tests => 2;

use App::Framework ;

diag( "Testing include path" );

	eval{
		require MyApp ;
	} ;
	if ($@)
	{
		fail("Loading module : $@") ;
	}
	else
	{
		pass("Loading module") ;
	}

	eval{
		require MyAppLib ;
	} ;
	if ($@)
	{
		fail("Loading lib module : $@") ;
	}
	else
	{
		pass("Loading lib module") ;
	}


#sub diag
#{
#	print "$_[0]\n" ;
#}	
#sub fail
#{
#	print "FAIL: $_[0]\n" ;
#}	
#sub pass
#{
#	print "PASS: $_[0]\n" ;
#}	
