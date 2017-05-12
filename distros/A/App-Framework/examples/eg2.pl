#!/usr/bin/perl
#
use strict ;

use App::Framework '+Config' ;

# VERSION
our $VERSION = '1.000' ;


	# Create application and run it
	App::Framework->new(
		'feature_config' => {
			'options'	=> {
				'debug'		=> 0,
			},
			'config'	=> {
				## Set to >0 to debug configuration processing
				'debug'		=> 0,
			},
		}
	)->go() ;



#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href, $args_aref) = @_ ;
	
	# do something useful....
	print "I'm in the app...\n" ;
	
	## Get the global settings
	my @global = $app->feature('Config')->get_array() ; # globals as an array..
	my %global = $app->feature('Config')->get_hash() ; # globals as a hash....
	$app->prt_data("Global: array=", \@global, " hash=", \%global) ;
	
	## get the specific array
	my @inst = $app->feature('Config')->get_array('instance') ;
	$app->prt_data("Inst",\@inst) ;
	
	## Do it again but use the config object
	my $cfg = $app->feature('Config') ;
	my @inst2 = $cfg->get_array('instance') ;
	$app->prt_data("Inst",\@inst2) ;
	
	## Do it again but use the config object
	my $cfg2 = $app->config ;
	my @inst3 = $cfg2->get_array('instance') ;
	$app->prt_data("Inst",\@inst3) ;
	
	
	## Finish by showing modified usage - i.e. reading config adds the globals to the options shown below....
	$app->usage() ;
}


#=================================================================================
# LOCAL SUBROUTINES
#=================================================================================

#=================================================================================
# SETUP
#=================================================================================
__DATA__


[SUMMARY]

An example of using the application framework with config file


[OPTIONS]

-int=i		An integer

Example of integer option

-float=f	An float

Example of float option

-string=s	A string [default=hello world]

Example of string option

-array=s@	An array

Example of an array option

-hash=s%	A hash

Example of a hash option


[DESCRIPTION]

B<$name> test out config file use.

