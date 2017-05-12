# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Aug-10 12:38 (EDT)
# Function: choose best IP addr to use in NAT/cloud env
#
# $Id$

package AC::Yenta::IO::TCP::Client;
our @ISA = 'AC::DC::IO::TCP::Client';

use AC::Yenta::MySelf;
use AC::Misc;
use strict;

my $inited;
my $natdom;

sub use_addr_port {
    my $class = shift;
    my $addr  = shift;
    my $port  = shift;

    # is addr + port => return
    return ($addr, $port) unless ref $addr;

    # addr is array of nat ip info (ACPIPPort)

    _init() unless $inited;

    my $public;
    my $private;

    for my $i ( @$addr ){
        # skip unreachable networks
        my $ok = AC::Yenta::NetMon::status_dom( $i->{natdom} );
        next unless $ok == 200;
        $public  = $i unless $i->{natdom};
        $private = $i if $i->{natdom} eq $natdom;
    }

    # prefer private addr if available (cheaper)
    my $prefer = $private || $public;
    return unless $prefer;

    return ( inet_itoa($prefer->{ipv4}), ($prefer->{port} || $port) );
}

sub _init {

    # determine my local NAT domain
    my $nat = my_network_info();

    for my $i (@$nat){
        $natdom ||= $i->{natdom};
    }
    $inited = 1;
}

1;
