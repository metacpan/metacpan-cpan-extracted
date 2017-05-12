# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-22 14:58 (EST)
# Function: 
#
# $Id: Kibitz.pm,v 1.2 2010/12/17 20:52:09 jaw Exp $

package AC::MrGamoo::Kibitz;
use AC::MrGamoo::About;
use AC::MrGamoo::MySelf;
use AC::MrGamoo::Stats;
use AC::MrGamoo::Config;
use AC::MrGamoo::Kibitz::Peers;
use AC::MrGamoo::Kibitz::Server;
use AC::MrGamoo::Kibitz::Client;
use AC::Misc;
use Sys::Hostname;
use strict;

my $STARTDELAY = 60;
my $STARTTIME  = $^T;
my $HOSTNAME   = hostname();
my $ipinfo;

sub about_myself {

    unless( $ipinfo ){
        my $natinfo = my_network_info();
        for my $i ( @$natinfo ){
            push @$ipinfo, { ipv4 => inet_atoi($i->{ipa}), port => my_port(), natdom => $i->{natdom} };
        }
    }

    my $status = ($^T > $STARTTIME + $STARTDELAY) ? 200 : 102;

    return {
        hostname        => $HOSTNAME,
        datacenter      => my_datacenter(),
        subsystem       => 'mrgamoo',
        environment     => conf_value('environment'),
        via             => my_server_id(),
        server_id       => my_server_id(),
        path            => '.',
        status          => $status,
        timestamp       => $^T,
        lastup          => $^T,
        ip              => $ipinfo,
        sort_metric     => loadave() * 1000,
    };

}


1;
