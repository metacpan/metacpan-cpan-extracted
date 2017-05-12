# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 12:35 (EST)
# Function: 
#
# $Id: Del.pm,v 1.1 2010/11/01 18:41:51 jaw Exp $

package AC::MrGamoo::API::Del;
use AC::MrGamoo::Debug 'api_del';
use AC::MrGamoo::API::Simple;
use AC::MrGamoo::Scriblr;
use strict;

sub handler {
    my $class   = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;

    # validate filename
    my $file = filename($req->{filename});
    debug("deleting file $file");

    if( $file && -f $file ){
        unlink $file;
    }

    if( -f $file ){
        reply( 500, 'Error', $io, $proto, $req );
    }else{
        reply( 200, 'OK', $io, $proto, $req );
    }
}

1;
