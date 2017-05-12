#!/usr/bin/perl
#
use strict ;
use App::Framework '::Filter' ;

# VERSION
our $VERSION = '1.00' ;

	## Create app
	go() ;


#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href, $state_href, $line) = @_ ;

	$state_href->{output} = uc $line ;
}


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests file filter extension

[DESCRIPTION]

B<$name> does some stuff.

