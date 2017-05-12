# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.



package DBR::Admin::Utility;
use Exporter; 

use lib '/drj/tools/perl-dbr/lib';
use DBR;
use DBR::Util::Logger;   # Any object that implements log, logErr, logDebug, logDebug2 and logDebug3 will do
use DBR::Util::Operator; # Imports operator functions
use DBR::Admin::Exception;

#############
# globals here
@ISA = qw(Exporter);
@EXPORT = qw( 

            );

use strict;


#############
# local globals here

my $dbr;
my $conf;

############
sub get_dbrh {

    if (!$conf) {
	$conf = shift;
    }

    if (!$conf) {
	die "No conf file passed in at run time";
    }


    
    if (!defined $dbr) {
	get_dbr();
    }

    my $dbrh = $dbr->connect('dbrconf') ||
      throw DrException(
			message => "failed to connect to dbrconf: $!",
		       );



    return ($dbrh);

}

#################
sub get_dbr {

    
    if (!defined($dbr)) {



	my $logger = new DBR::Util::Logger(
					   -logpath => '/tmp/dbr_example.log',
					   -logLevel => 'debug3'
					  );

	$dbr = new DBR(
			  -logger => $logger,
			  -conf => $conf,

		   );
    }

    return $dbr;

}


1;
