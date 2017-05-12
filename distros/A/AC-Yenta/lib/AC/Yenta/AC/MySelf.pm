# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-26 17:23 (EST)
# Function: 
#
# $Id$

package AC::Yenta::AC::MySelf;
use AC::Yenta::Config;
use AC::Yenta::Debug;
use AC::DataCenter;	# provides my_network_info, my_datacenter
use Sys::Hostname;
use strict;

my $SERVERID;

sub init {
    my $class = shift;
    my $port  = shift;	# not used
    my $id    = shift;

    $SERVERID = $id;
    unless( $SERVERID ){
        (my $h = hostname()) =~ s/\.adcopy.*//;
        my $v = conf_value('environment');
        $SERVERID = 'yenta';
        $SERVERID .= '/' . $v unless $v eq 'prod';
        $SERVERID .= '@' . $h;
    }
    verbose("system persistent-id: $SERVERID");
}

sub my_server_id {
    return $SERVERID;
}

1;

