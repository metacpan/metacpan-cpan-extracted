# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 12:40 (EST)
# Function: update our knowledge about a remote task
#
# $Id: TaskStatus.pm,v 1.1 2010/11/01 18:41:53 jaw Exp $

package AC::MrGamoo::API::TaskStatus;
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


    debug("updating task status $req->{jobid}/$req->{taskid}");

    my $r = AC::MrGamoo::Job->task_status( %$req );

    if( $r ){
        reply( 200, 'OK', $io, $proto, $req );
    }else{
        reply( 500, 'Error', $io, $proto, $req );
    }
}

1;
