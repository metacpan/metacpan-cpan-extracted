#!/usr/bin/perl
#
use strict ;

use App::Framework::Lite '+Args(open=none)';
use MyLib ;

# VERSION
our $VERSION = '1.001' ;

	go() ;

#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;
	
	print "Doing something...\n" ;
	
	MyLib->mylib() ;
	
}


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests manual page creation

[OPTIONS]

-n|'name'=s		Test name

Specify a test name. This determines the output filenames (for the test script .ts and menu file .db).

Default action is to use the control file name (without file extension).

-nomacro	Do not create test macro calls

Normally the script automatically inserts a call to 'test_start' at the beginning of the test, and 'test_passed' at the end
of the test. In both cases, the macros are called with the quoted string that is the full 'path' of the test name. 

The test path being the menu names, separated by '::' down to the actual test name

-int=i		An integer

Example of integer option

-float=f	An float

Example of float option

-array=s@	An array

Example of an array option

-hash=s%	A hash

Example of a hash option


[DESCRIPTION]

B<$name> reads the control file to pull together fragments of test script. Creates a single test script file and a test menu.

