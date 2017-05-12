# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-02 11:16 (EDT)
# Function: track status of peers
#
# $Id$

package AC::Yenta::Status;
use AC::Yenta::Kibitz::Status;
use AC::Yenta::Debug 'status';
use AC::Yenta::Config;
use AC::Yenta::MySelf;
use AC::Dumper;
use AC::Misc;
use Sys::Hostname;
use JSON;
use Socket;
require 'AC/protobuf/yenta_status.pl';
use strict;

my $KEEPDOWN = 1800;	# keep data about down servers for how long?
my $KEEPLOST = 600;	# keep data about servers we have not heard about for how long?
my $SAVEMAX  = 1800;	# do not save if older than

my $PORT;

our $DATA = bless {
    allpeer	=> {},		# yenta_status
    sceptical	=> {},
    mappeer	=> {},		# {map} => { id => id }
    peermap	=> {},		# {id}  => @map
    datacenter  => {},		# {dc}  => { id => id }
    peertype	=> {},		# {ss}  => { id => id }
};

sub init {
    my $port = shift;

    $PORT = $port;

    AC::DC::Sched->new(
        info	=> 'kibitz status',
        freq	=> (conf_value('time_status_kibitz') || 5),
        func	=> \&periodic,
       );
    AC::DC::Sched->new(
        info	=> 'save status',
        freq	=> (conf_value('time_status_save') || 5),
        func	=> \&save_status,
       );
}

# start up a client every so often
sub periodic {

    # clean up down or lost peers
    for my $id ( keys %{$DATA->{allpeer}} ){
        my $p = $DATA->{allpeer}{$id};
        next unless $p;

        next if $p->{status} == 200 && $p->{timestamp} > $^T - $KEEPLOST;
        _maybe_remove( $id );
    }

    # randomly pick a peer
    my($id, $ip, $port) = _random_peer();
    return unless $id;

    # start a client
    debug("starting status kibitz client to $id");

    my $c = AC::Yenta::Kibitz::Status::Client->new( $ip, $port,
                                            info 	=> "status client: $id",
                                            status_peer	=> $id,
                                           );
    return __PACKAGE__->isdown($id) unless $c;

    $c->start();
}

sub _random_peer {

    my $here  = my_datacenter();

    # sceptical
    my @scept = values %{$DATA->{sceptical}};

    my @all   = map  { $DATA->{allpeer}{$_} } keys %{$DATA->{peertype}{yenta}};
    my @old   = grep { $_->{timestamp} < $^T - $KEEPLOST *.75 } @all;
    my @local = grep { $_->{datacenter} eq $here } @all;	# this datacenter
    my @away  = grep { $_->{datacenter} ne $here } @all;	# not this datacenter

    # first check anything sceptical
    my @peer  = @scept;

    # then (maybe) something about to expire
    @peer = @old  unless @peer || int rand(5);

    # then (maybe) something far away
    @peer = @away unless @peer || int rand(5);

    # then something local
    @peer = @local unless @peer;

    # last resort
    @peer = @all unless @peer;

    # sometimes use the seed, in case there was a network split
    if( @peer && int(rand(@all+1)) ){
        my $p = $peer[ rand(@peer) ];
        debug("using peer $p->{server_id}");
        return ($p->{server_id}, $p->{ip}, undef);
    }

    # seed peer
    my $seed = conf_value('seedpeer');
    my $p = $seed->[ rand(@$seed) ];
    my ($ip, $port) = split /:/, $p;
    $port ||= my_port();

    # don't talk to self. any of my addrs.
    my $ipinfo = my_network_info();
    for my $i (@$ipinfo){
        return if $ip eq $i->{ipa} && $port == $PORT;
    }

    return("seed/$ip:$port", $ip, $port);
}

# server list for save file
sub server_list {
    my $type = shift;

    ($type, my $where) = split m|/|, $type;
    # where - no longer used
    $where ||= my_datacenter();

    my @peer = keys %{ $DATA->{peertype}{$type} };
    return unless @peer;

    # nothing too old
    @peer = grep { $DATA->{allpeer}{$_}{lastup} > $^T - $SAVEMAX } @peer;
    return unless @peer;

    return map { $DATA->{allpeer}{$_} } @peer;
}

# save a list of peers, in case I crash, and for others to use
sub save_status {

    my $save = conf_value('savestatus');
    my $here = my_datacenter();

    # also save locally running services
    my @mon  = AC::Yenta::Monitor::export();

    for my $s ( @$save ){
        my $file  = $s->{file};
        my $types = $s->{type};

        my @peer;
        for my $type (@$types){
            push @peer, server_list($type);

            for my $m (@mon){
                push @peer, $m if $m->{subsystem} eq $type;
            }
        }

        next unless @peer;

        debug("saving peer status file");
        unless( open(FILE, ">$file.tmp") ){
            problem("cannot open save file '$file.tmp': $!");
            return;
        }

        for my $pd (@peer){
            # only save best addr in save file
            my($ip, $port) = AC::Yenta::IO::TCP::Client->use_addr_port( $pd->{ip} );

            my $data = {
                id		=> $pd->{server_id},
                addr		=> $ip,
                port		=> int($port),
                status		=> int($pd->{status}),
                subsystem	=> $pd->{subsystem},
                environment	=> $pd->{environment},
                sort_metric	=> int($pd->{sort_metric}),
                capacity_metric => int($pd->{capacity_metric}),
                datacenter	=> $pd->{datacenter},
                is_local	=> ($here eq $pd->{datacenter} ? 1 : 0),
            };
            if( $pd->{subsystem} eq 'yenta' ){
                $data->{map} = $pd->{map};
            }

            print FILE encode_json( $data ), "\n";
        }

        close FILE;
        unless( rename("$file.tmp", $file) ){
            problem("cannot rename save file '$file': $!");
        }

    }
}

################################################################
# diagnostic reports
sub report {

    my $res;

    for my $v (AC::Yenta::Kibitz::Status::_myself(), AC::Yenta::Monitor::export(), values %{$DATA->{allpeer}} ){
        my $id = sprintf '%-28s', $v->{server_id};
        my $metric = int( $v->{sort_metric} );
        $res .= "$id $v->{hostname}\t$v->{datacenter}\t$v->{subsystem}\t$v->{environment}\t$v->{status}\t$metric\n";
    }

    return $res;
}

sub report_long {

    my $res;

    for my $v (AC::Yenta::Kibitz::Status::_myself(), AC::Yenta::Monitor::export(), values %{$DATA->{allpeer}} ){
        $res .= dumper( $v ) . "\n\n";
    }
    return $res;
}
################################################################

sub my_port { $PORT }


sub my_instance_id {
    my $class = shift;
    return my_server_id() . sprintf('/%04x', $$);
}

sub peer {
    my $class = shift;
    my $id    = shift;

    return $DATA->{allpeer}{$id};
}

sub allpeers {
    my $class = shift;

    # idown sets status to 0 (below), skip such
    return grep { $_->{status} } values %{$DATA->{allpeer}};
}

sub mappeers {
    my $class = shift;
    my $map   = shift;

    return keys %{ $DATA->{mappeer}{$map} };
}

sub datacenters {
    my $class = shift;

    return $DATA->{datacenter};
}
################################################################

sub _remove {
    my $id = shift;

    my $ss = $DATA->{allpeer}{$id}{subsystem};
    delete $DATA->{peertype}{$ss}{$id} if $ss;

    my $dc = $DATA->{allpeer}{$id}{datacenter};
    delete $DATA->{datacenter}{$dc}{$id} if $dc;

    verbose("deleting peer: $id");
    delete $DATA->{allpeer}{$id};

    # remove map info
    for my $map ( @{$DATA->{peermap}{$id}} ){
        delete $DATA->{mappeer}{$map}{$id};
    }
    delete $DATA->{peermap}{$id};

    # delete its monitored items
    for my $p (keys %{$DATA->{allpeer}}){
        next unless $DATA->{allpeer}{$p}{via} eq $id;
        _remove($p);
    }
}

sub _maybe_remove {
    my $id = shift;

    my $d = $DATA->{allpeer}{$id};

    if( ($^T - $d->{lastup} > $KEEPDOWN) || ($^T - $d->{timestamp} > $KEEPLOST) ){

        _remove($id);
    }
}

sub isdown {
    my $class = shift;
    my $id    = shift;

    debug("marking peer '$id' as down");

    if( ! $DATA->{allpeer}{$id} ){
        return unless $DATA->{sceptical}{$id};
        # we know it is down, and want to kibbitz this fact
        $DATA->{allpeer}{$id} = $DATA->{sceptical}{$id};
    }

    delete $DATA->{sceptical}{$id};

    if( $DATA->{allpeer}{$id} ){
        $DATA->{allpeer}{$id}{timestamp} = $^T;
        $DATA->{allpeer}{$id}{status}    = 0;
        $DATA->{allpeer}{$id}{path}      = my_server_id();
    }
    _maybe_remove( $id );
}

################################################################

sub _env_ok {
    my $class = shift;
    my $id    = shift;
    my $up    = shift;

    # if( $up->{environment} ne conf_value('environment') ){
    #     verbose("ignoring update from $id - wrong env: $up->{environment}");
    #     return;
    # }
    return 1;
}

sub update_sceptical {
    my $class = shift;
    my $id    = shift;	# ->server_id
    my $up    = shift;
    my $io    = shift;

    return unless $class->_env_ok($id, $up);

    if( $DATA->{allpeer}{$id} ){
        # already known
        delete $DATA->{sceptical}{$id};
        return;
    }

    debug("rcvd update (sceptical) about $id from $io->{peerip}");

    # only accept updates from the server itself
    # no 3rd party updates. no misconfigured serevrs.
    problem("server misconfigured $id != $io->{peerip}")
      unless grep { inet_atoi($io->{peerip}) == $_->{ipv4}  } @{$up->{ip}};

    $up->{id} = $id;
    delete $up->{lastup};
    $DATA->{sceptical}{$id} = $up;
}

sub update {
    my $class = shift;
    my $id    = shift;	# -> server_id
    my $up    = shift;

    return unless $class->_env_ok($id, $up);

    # only keep it if it is relatively fresh, and valid
    return unless $up->{timestamp} > $^T - $KEEPLOST;
    return unless $up->{status};

    delete $DATA->{sceptical}{$id};

    $up->{id} = $id;
    my $previnfo = $DATA->{allpeer}{$id};
    verbose("discovered new peer: $id ($up->{hostname})") unless $previnfo;

    # only keep it if it is newer than what we have
    return if $previnfo && $up->{timestamp} <= $previnfo->{timestamp};

    $up->{path} .= ' ' . my_server_id();

    # debug("updating $id => $up->{status} => " . dumper($up));
    debug("updating $id => $up->{status}");

    $DATA->{allpeer}{$id} = $up;

    if( $up->{status} != 200 ){
        _maybe_remove( $id );
        return ;
    }

    # update datacenter info
    unless( $DATA->{datacenter}{$up->{datacenter}}{$id} ){
        my $pdc = $previnfo->{datacenter};
        delete $DATA->{datacenter}{$pdc}{$id} if $pdc;
        $DATA->{datacenter}{$up->{datacenter}}{$id} = $id;
    }

    # update subsystem info
    unless( $DATA->{peertype}{$up->{subsystem}}{$id} ){
        my $ss = $previnfo->{subsystem};
        delete $DATA->{peertype}{$ss}{$id} if $ss;
        $DATA->{peertype}{$up->{subsystem}}{$id} = $id;
    }

    # update map info
    $DATA->{peermap}{$id} ||= [];
    $up->{map} ||= [];
    my @curmap = @{$DATA->{peermap}{$id}};
    my @newmap = sort @{$up->{map}};

    return if "@curmap" eq "@newmap";		# unchanged

    # what do we need to add/remove
    my (%remove, %add);
    @remove{@curmap} = @curmap;
    @add{@newmap}    = @newmap;
    delete $remove{$_} for @newmap;
    delete $add{$_}    for @curmap;

    for my $map (keys %remove){
        debug("removing $map from $id");
        delete $DATA->{mappeer}{$map}{$id};
    }
    for my $map (keys %add){
        debug("adding $map to $id");
        $DATA->{mappeer}{$map}{$id} = $id;
    }
    $DATA->{peermap}{$id} = \@newmap;
}

