# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-18 18:10 (EST)
# Function: info about myself - default implementation
#
# $Id: MySelf.pm,v 1.1 2010/11/01 18:41:54 jaw Exp $

package AC::MrGamoo::Default::MySelf;
use AC::MrGamoo::Config;
use AC::MrGamoo::Debug;
use Sys::Hostname;
use Socket;
use strict;


my $SERVERID;
my $MYIP = inet_ntoa(scalar gethostbyname(hostname()));
die "cannot determine my IP addr.\nsee 'class_myself' in the documentation\n" unless $MYIP;

sub init {
    my $class = shift;
    my $port  = shift;	# not used
    my $id    = shift;

    $SERVERID = $id;
    unless( $SERVERID ){
        $SERVERID = 'mrm/' . conf_value('environment') . '@' . hostname();
    }
    verbose("system persistent-id: $SERVERID");
}

sub my_server_id {
    return $SERVERID;
}

sub my_network_info {
    return [ { ipa => $MYIP } ];
}

sub my_datacenter {
    return 'default';
}

1;
