# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-22 15:14 (EST)
# Function: 
#
# $Id: Peers.pm,v 1.1 2010/11/01 18:41:59 jaw Exp $

package AC::MrGamoo::Kibitz::Peers;
use AC::MrGamoo::Debug 'kibitz_peers';
use AC::MrGamoo::About;
use AC::MrGamoo::MySelf;
use AC::MrGamoo::Config;
use AC::DC::Sched;
use AC::Misc;
use AC::Import;
use JSON;
use strict;

our @EXPORT = qw(pick_best_addr_for_peer peer_list_all get_peer_by_id);

my $KEEPDOWN = 300;     # keep data about down servers for how long?
my $KEEPLOST = 600;     # keep data about servers we have not heard about for how long?

my %SCEPTICAL;
my %ALLPEER;
my %MAYBEDOWN;
my $natdom;
my $natinit;

AC::DC::Sched->new(
    info    => 'kibitz status',
    freq    => (conf_value('time_status_kibitz') || 5),
    func    => \&periodic,
   );

################################################################

sub periodic {

    # clean up down or lost peers
    for my $id ( keys %ALLPEER ){
        my $p = $ALLPEER{$id};
        next unless $p;

        next if $p->{status} == 200 && $p->{timestamp} > $^T - $KEEPLOST;
        _maybe_remove( $id );
    }

    _kibitz_with_random_peer();

}

################################################################

sub update_sceptical {
    my $class = shift;
    my $up    = shift;

    return unless _update_ok($up);
    my $id = $up->{server_id};
    return if $ALLPEER{$id};
    debug("recvd update (sceptical) from $id");
    $SCEPTICAL{$id} = $up;
}

sub update {
    my $class = shift;
    my $up    = shift;

    return unless _update_ok($up);
    my $id = $up->{server_id};


    my $previnfo = $ALLPEER{$id};
    # only keep it if it is newer than what we have
    return if $previnfo && $up->{timestamp} <= $previnfo->{timestamp};
    # only keep it if it is relatively fresh
    return unless $up->{timestamp} > $^T - $KEEPDOWN;

    $up->{path} .= ' ' . my_server_id();

    if( $previnfo ){
        verbose("marking peer $id as up") if $up->{status} == 200 && $previnfo->{status} != 200;
    }else{
        verbose("discovered new peer: $id ($up->{hostname})");
    }

    $ALLPEER{$id} = $up;
    delete $SCEPTICAL{$id};

    if( $up->{status} != 200 ){
        _maybe_remove( $id );
        return ;
    }
}

sub seems_ok {
    my $class = shift;
    my $id    = shift;

    delete $MAYBEDOWN{$id};
}

# require 2 failures before declaring it down
sub maybe_down {
    my $class = shift;
    my $id    = shift;
    my $why   = shift;

    if( $MAYBEDOWN{$id} ){
        delete $MAYBEDOWN{$id};
        $class->isdown($id, $why);
        return;
    }

    return $class->isdown($id, $why) unless $ALLPEER{$id};
    return $class->isdown($id, $why) unless $ALLPEER{$id}{status} == 200;

    debug("peer '$id' might be down");
    $MAYBEDOWN{$id} = $ALLPEER{$id};
}

sub isdown {
    my $class = shift;
    my $id    = shift;
    my $why   = shift;

    debug("peer '$id' is down");

    delete $SCEPTICAL{$id} if $SCEPTICAL{$id};
    return unless $ALLPEER{$id};

    verbose("marking peer $id as down $why") if $ALLPEER{$id}{status} == 200;
    $ALLPEER{$id}{timestamp} = $^T;
    $ALLPEER{$id}{status}    = 0;

    _maybe_remove( $id );
}

sub peer_list_all {

    return [ AC::MrGamoo::Kibitz->about_myself(), values %ALLPEER ];
}

sub response {
    return peer_list_all();
}

sub get_peer_by_id {
    my $id = shift;

    return $ALLPEER{$id} if $ALLPEER{$id};
    return AC::MrGamoo::Kibitz->about_myself() if $id eq my_server_id();
    return ;
}

sub report {

    my $all = peer_list_all();
    my $txt;
    for my $p (@$all){
        my $lu = $^T - $p->{lastup};
        my $lh = $^T - $p->{timestamp};

        $txt .= sprintf("%-30s %s %s %s %3d %7.2f %d %d\n",
                        $p->{server_id}, $p->{subsystem}, $p->{environment},
                        $p->{datacenter}, $p->{status}, $p->{sort_metric},
                        $lu, $lh,
                        );
    }
    return $txt;
}

sub report_json {

    my $all = peer_list_all();
    my @fields = qw(hostname environment subsystem datacenter server_id status sort_metric);

    return encode_json( [ map {
        my %x;
        @x{@fields} = @{$_}{@fields};
        $x{ip} = [
            map { {
                ipv4	=> inet_itoa($_->{ipv4}),
                port	=> $_->{port},
                natdom	=> $_->{natdom},
            } } @{$_->{ip}}
           ];
        \%x;
    } @$all ] ) . "\n";
}

################################################################

sub _update_ok {
    my $up = shift;

    my $myself = my_server_id();
    return if $up->{via} eq $myself;
    return if $up->{server_id} eq $myself;
    return if $up->{environment} ne conf_value('environment');
    return if $up->{subsystem}   ne 'mrgamoo';
    return 1;
}

sub _remove {
    my $id = shift;

    my $d = $ALLPEER{$id};
    my $lu = $^T - $d->{lastup};
    my $lh = $^T - $d->{timestamp};
    verbose("deleting peer: $id ($lu, $lh)");
    delete $ALLPEER{$id};
}

sub _maybe_remove {
    my $id = shift;

    my $d = $ALLPEER{$id};

    if( ($^T - $d->{lastup} > $KEEPDOWN) || ($^T - $d->{timestamp} > $KEEPLOST) ){
        _remove($id);
    }
}

################################################################

# pick best ip addr from array (ACPIPPort)
sub pick_best_addr_for_peer {
    my $ipinfo = shift;

    _nat_init() unless $natinit;

    my $public;
    my $private;

    for my $i ( @$ipinfo ){
        $public  = $i unless $i->{natdom};
        $private = $i if $i->{natdom} eq $natdom;
    }

    # prefer private addr if available (cheaper)
    my $prefer = $private || $public;
    return unless $prefer;

    return ( inet_itoa($prefer->{ipv4}), $prefer->{port} );
}

sub _nat_init {

    # determine my local NAT domain
    my $nat = my_network_info();

    for my $i (@$nat){
        $natdom ||= $i->{natdom};
    }
    $natinit = 1;
}


################################################################

sub _random_peer {

    my @peer;

    # might be down? try again.
    @peer = values %MAYBEDOWN;

    # sceptical
    @peer = values %SCEPTICAL unless @peer;

    # known peer
    unless(@peer){
        @peer = values %ALLPEER;
        # sometimes, randomly, use the seed peers
        @peer = () unless int rand(@peer+1);
    }

    if( @peer ){
        my $p = $peer[ rand(@peer) ];
        debug("using peer $p->{server_id}");
        return ($p->{server_id}, pick_best_addr_for_peer($p->{ip}));
    }

    # seed peer
    my $seed = conf_value('seedpeer');
    my $p = $seed->[ rand(@$seed) ];
    my ($ip, $port) = split /:/, $p;
    $port ||= my_port();

    # don't talk to self. any of my addrs.
    my $ipinfo = my_network_info();
    for my $i (@$ipinfo){
        return if $ip eq $i->{ipa} && $port == my_port();
    }

    debug("using seedpeer");
    return("seed/$ip:$port", $ip, $port);
}

sub _kibitz_with_random_peer {

    my( $id, $addr, $port ) = _random_peer();
    return unless $id;
    debug("starting status kibitz client to $id");

    my $ok = AC::MrGamoo::Kibitz::Client->new( $addr, $port,
                                            info        => "status client: $id",
                                            status_peer => $id,
                                           );
    __PACKAGE__->maybe_down($id, 'connect') unless $ok;
}

1;
