# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 12:25 (EST)
# Function: 
#
# $Id: TaskAbort.pm,v 1.1 2010/11/01 18:41:53 jaw Exp $

package AC::MrGamoo::API::TaskAbort;
use AC::MrGamoo::Debug 'api_task';
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


    debug("abort task $req->{jobid}/$req->{taskid}");

    my $r = AC::MrGamoo::Task->abort( jobid => $req->{jobid}, taskid => $req->{taskid} );

    if( $r ){
        reply( 200, 'OK', $io, $proto, $req );
    }else{
        reply( 500, 'Error', $io, $proto, $req );
    }
}

1;
