# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 12:40 (EST)
# Function: update our knowledge about a remote task
#
# $Id: XferStatus.pm,v 1.1 2010/11/01 18:41:54 jaw Exp $

package AC::MrGamoo::API::XferStatus;
use AC::MrGamoo::Debug 'api_job';
use AC::MrGamoo::Config;
use AC::MrGamoo::Protocol;

use AC::MrGamoo::API::Simple;

use strict;

sub handler {
    my $class   = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;


    debug("updating xfer status $req->{jobid}/$req->{copyid}");

    my $r = AC::MrGamoo::Job->xfer_status( %$req );

    if( $r ){
        reply( 200, 'OK', $io, $proto, $req );
    }else{
        reply( 500, 'Error', $io, $proto, $req );
    }
}

1;
