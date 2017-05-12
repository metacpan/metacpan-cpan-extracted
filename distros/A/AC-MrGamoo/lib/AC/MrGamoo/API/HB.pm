# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Dec-21 17:08 (EST)
# Function: respond to heartbeat requests
#
# $Id: HB.pm,v 1.1 2010/11/01 18:41:51 jaw Exp $

package AC::MrGamoo::API::HB;
use AC::MrGamoo::Debug 'hb';
use AC::MrGamoo::Config;
use AC::MrGamoo::Stats;
use AC::MrGamoo::About;
use AC::MrGamoo::MySelf;

use Sys::Hostname;

require 'AC/protobuf/heartbeat.pl';
use strict;

my $HOSTNAME = hostname();

sub handler {
    my $class   = shift;
    my $io      = shift;
    my $proto   = shift;
    my $req     = shift;
    my $content = shift;

    unless( $proto->{want_reply} ){
        $io->shut();
        return;
    }

    my $response = AC::MrGamoo::Protocol->encode_reply( {
        type            => 'heartbeat_request',
        msgid           => $proto->{msgid},
        is_reply        => 1,
    }, {
        status_code	=> 200,
        status_message	=> 'Honky Dory',
        hostname	=> $HOSTNAME,
        subsystem	=> 'mrgamoo',
        environment	=> conf_value('environment'),
        port		=> my_port(),
        timestamp	=> time(),
        sort_metric	=> loadave(),
        server_id	=> my_server_id(),
        process_id	=> $$,
    } );

    debug("sending hb reply");
    $io->write_and_shut( $response );

}



1;
