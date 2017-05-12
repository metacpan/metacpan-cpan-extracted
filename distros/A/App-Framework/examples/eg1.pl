#!/usr/bin/perl
#
use strict ;

use App::Framework ;

# VERSION
our $VERSION = '1.002' ;


	# Create application and run it
	App::Framework->new()->go() ;

#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;
	
	# Get source/dest dirs
	my ($src_dir, $backup_dir) = $app->args();
	
	# options
	my %opts = $app->options() ;

	if ($opts{array})
	{
		$app->prt_data("Array option=", $opts{array}) ;
	}
	if ($opts{hash})
	{
		$app->prt_data("Hash option=", $opts{hash}) ;
	}

	
	# do something useful....
	
}


#=================================================================================
# LOCAL SUBROUTINES
#=================================================================================

#=================================================================================
# SETUP
#=================================================================================
__DATA__


[HISTORY]

28-May-08    SDP        New

[SUMMARY]

An example of using the application framework with named arguments

[ARGS]

* src_dir=d 		Source directory

* backup_dir=d		Backup directory

[OPTIONS]

-database=s	Database name [default=test]

Specify the database name to use

-int=i		An integer

Example of integer option

-float=f	An float

Example of float option

-array=s@	An array

Example of an array option

-hash=s%	A hash

Example of a hash option


-log=s		Override the log [default=tmp.log]

Example of replacing the default log option


[DESCRIPTION]

B<$name> expects a source directory and destination directory to be specified. If not, then
an error message is created and the application aborted.

