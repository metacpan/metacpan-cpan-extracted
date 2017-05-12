# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 12:11 (EST)
# Function: 
#
# $Id: TaskCreate.pm,v 1.3 2011/01/10 15:23:00 jaw Exp $

package AC::MrGamoo::API::TaskCreate;
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

    debug("new task $req->{jobid}/$req->{taskid}");
    my $x = AC::MrGamoo::Task->new( %$req );
    my $r = $x ? $x->start() : undef;

    if( $r ){
        reply( 200, 'OK', $io, $proto, $req );
    }else{
        reply( 500, 'Error', $io, $proto, $req );
    }
}

1;
