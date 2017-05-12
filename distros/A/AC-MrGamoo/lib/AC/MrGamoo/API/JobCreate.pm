# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 12:11 (EST)
# Function: 
#
# $Id: JobCreate.pm,v 1.1 2010/11/01 18:41:52 jaw Exp $

package AC::MrGamoo::API::JobCreate;
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

    debug("new job $req->{jobid}");

    if( $req->{console} =~ /^:/ ){
        # fill in ip addr
        $req->{console} = $io->{from_ip} . $req->{console};
    }

    my $x = AC::MrGamoo::Job->new( %$req );
    my $r = $x ? $x->start() : undef;

    if( $r ){
        reply( 200, 'OK', $io, $proto, $req );
    }else{
        reply( 500, 'Error', $io, $proto, $req );
    }
}

1;
