# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-19 18:18 (EST)
# Function: 
#
# $Id: Chk.pm,v 1.1 2010/11/01 18:41:50 jaw Exp $

package AC::MrGamoo::API::Chk;
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

    my $file = filename($req->{filename});

    if( $file && -f $file ){
        reply( 500, 'Error', $io, $proto, $req );
    }else{
        reply( 200, 'OK', $io, $proto, $req );
    }
}

1;
