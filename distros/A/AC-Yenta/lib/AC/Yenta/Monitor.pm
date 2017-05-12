# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-May-12 11:03 (EDT)
# Function: monitor related processes
#
# $Id$

# we periodically check the heartbeats of various processes (dancrs, scriblers, ...)
# and kibitz their info around the network

package AC::Yenta::Monitor;
use AC::Yenta::Debug 'monitor';
use AC::Yenta::Config;
use AC::Yenta::Monitor::Client;
use AC::Misc;
use AC::Yenta::MySelf;

use Sys::Hostname;
use Socket;
use strict;

require 'AC/protobuf/yenta_status.pl';
require 'AC/protobuf/heartbeat.pl';

my $FREQ	= 2;
my $OLD_DOWN	= 30;
my $OLD_KEEP	= 1800;

my %MON;	# by 'id' (from config file)

sub init {

    AC::DC::Sched->new(
        info	=> 'monitor',
        freq	=> $FREQ,
        func	=> \&periodic,
       );
}

sub periodic {

    my $mon = conf_value('monitor');

    # clean up old data
    for my $id (keys %MON){
        isdown($id, 0) if $MON{$id}{lastup} < $^T - $OLD_DOWN;
    }

    # start monitoring (send heartbeat request)
    for my $m (@$mon){
        my $ip   = $m->{ipa};
        my $port = $m->{port};
        my $id   = "$ip:$port";
        debug("start monitoring $id");

        my $ok = AC::Yenta::Monitor::Client->new( $ip, $port,
                                                info 		=> "monitor client: $id",
                                                monitor_peer	=> $id,
                                               );

        isdown($id, 0) unless $ok;
    }
}

# data for kibitzing around
# array of ACPYentaStatus
sub export {

    my @d;
    my $here = my_datacenter();
    my $self = my_server_id();

    for my $v (values %MON){

        push @d, {
            id			=> $v->{id},	# from config, typically localhost:port
            datacenter		=> $here,
            via			=> $self,
            hostname		=> $v->{hostname},
            subsystem		=> $v->{subsystem},
            environment		=> $v->{environment},
            status		=> $v->{status_code},
            timestamp		=> $v->{timestamp},
            lastup		=> $v->{lastup},
            sort_metric		=> $v->{sort_metric},
            capacity_metric	=> $v->{capacity_metric},
            server_id		=> $v->{server_id},
            instance_id 	=> $v->{server_id},
            ip			=> $v->{ip},
            path		=> '.',
        };
    }
    return @d;
}

sub isdown {
    my $id   = shift;
    my $code = shift;

    my $d = $MON{$id};
    return unless $d;

    # require 2 polls to fail
    return unless $^T - $d->{lastup} >= 2 * $FREQ;

    $code = 0 if $code == 200;
    $d->{status_code} = $code || 0;
    $d->{timestamp}   = $^T;

    debug("monitor $id is down");

    if( $d->{lastup} < $^T - $OLD_KEEP ){
        debug("monitor $id down too long. removing from report");
        delete $MON{$id};
    }
}

sub update {
    my $id = shift;
    my $gb = shift;	# ACPHeartbeat

    my $up;
    eval {
        $up = ACPHeartBeat->decode( $gb );
        $up->{id} = $id;
    };
    if(my $e = $@){
        problem("cannot decode hb data: $e");
        return isdown($id, 0);
    }
    unless( $up->{status_code} == 200 ){
        return isdown($id, $up->{status_code});
    }
    return isdown($id, 0) unless $^T - $up->{timestamp} < $OLD_DOWN;

    debug("monitor $id is up");
    $up->{lastup} = $^T;
    $up->{downcount} = 0;

    _hb_ip_info( $up, $MON{$id} );
    $MON{$id} = $up;
}

sub _hb_ip_info {
    my $up  = shift;
    my $old = shift;

    my $ip;

    $ip = $old->{ip} if ($old->{process_id} == $up->{process_id}) && ($old->{server_id} eq $up->{server_id});

    unless( $ip ){
        my $port = $up->{port};
        unless( $port ){
            # use monitored port (id is from config)
            (undef, $port) = split /:/, $up->{id};
        }

        if( $up->{ip} ){
            $ip = [ { ipv4 => $up->{ip}, port => $port, natdom => undef } ];
        }else{
            my $mynat = my_network_info();

            for my $i ( @$mynat ){
                push @$ip, { ipv4 => $i->{ipi}, port => $port, natdom => $i->{natdom} };
            }
        }
    }

    $up->{ip} = $ip;
}

1;
