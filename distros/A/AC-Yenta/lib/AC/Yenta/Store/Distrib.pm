# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-01 18:56 (EDT)
# Function: distribute data to other peers
#
# $Id$

package AC::Yenta::Store::Distrib;
use AC::Yenta::Kibitz::Store::Client;
use AC::Yenta::Debug 'distrib';
use AC::Yenta::Config;
use AC::Yenta::Protocol;
use AC::Yenta::Stats;
use AC::Yenta::MySelf;
use AC::Misc;
use AC::DC::Sched;
use strict;

my $MAXHOP      = 10;
my $MAXFARSEE   = 2;
my $MAXNEARSEE  = 3;
my $FARSENDS    = 1;
my $NEARSENDS   = 2;
my $MAXUNDERWAY = 64;

my $msgid = $$;
my @DIST;

AC::DC::Sched->new(
    info	=> 'distribution',
    freq	=> 5,
    func	=> \&AC::Yenta::Store::Distrib::periodic,
   );

sub new {
    my $class = shift;
    my $req   = shift;
    my $cont  = shift;

    return if $req->{hop} >= $MAXHOP;
    return if $req->{expire} < $^T;

    my $sender = $req->{sender};
    my $sendat = AC::Yenta::Status->peer($sender);

    my $me = bless {
        info		=> "$req->{datum}{map}/$req->{datum}{key}/$req->{datum}{version}",
        map		=> $req->{datum}{map},
        req		=> $req,
        content		=> $cont,
        # we tune the distribution algorithm based on where it came from:
        faraway 	=> (my_datacenter() ne $sendat->{datacenter}),

        farseen		=> 0,
        nearseen	=> 0,
        farsend		=> [],
        nearsend	=> [],
        ordershift	=> 4,
    }, $class;

    debug("distributing $me->{info}");
    inc_stat( 'dist_requests' );
    inc_stat( 'dist_requests_faraway' ) if $me->{faraway};


    $me->_init_strategy($sender);

    # RSN - check load
    my $max = conf_value('distrib_max') || $MAXUNDERWAY;
    if( @DIST < $max ){
        $me->_start_next();
    }
    push @DIST, $me;

    return $me;
}

# periodically, go through and restart or expire
sub periodic {

    my @keep;
    my $max = conf_value('distrib_max') || $MAXUNDERWAY;

    my $chance = (@DIST > $max) ? ($max / @DIST) : 1;

    for my $r (@DIST){
        # debug("periodic $r->{info}");
        next if $^T > $r->{req}{expire};

        if( (rand() <= $chance) && (AC::DC::IO->underway() <= 2 * $max) ){
            my $keep = $r->_start_next();
            push @keep, $r if $keep;
        }else{
            push @keep, $r;
        }
    }

    @DIST = @keep;
}

################################################################
# determine distribution strategy
#   - if we recvd it from faraway, we will send it to other datacenters, and randomly in the same datacenter
#   - otherwise we send it in the same datacenter, in an orderly fashion
# RSN - find an strategy with faster convergence + less duplication

sub _init_strategy {
    my $me     = shift;
    my $sender = shift;

    my $here   = my_datacenter();
    my $dcs    = AC::Yenta::Status->datacenters();
    my $sendat = AC::Yenta::Status->peer($sender);
    my(@far, @near);

    for my $dc (keys %$dcs){
        if( $dc eq $here ){
            push @near, grep { $_ ne $sender } $me->_compat_peers_in_dc($dc);
        }else{
            next if $dc eq $sendat->{datacenter};

            push @far, {
                dc	=> $dc,
                id	=> [ $me->_compat_peers_in_dc($dc) ],
            };
        }
    }

    if( $me->{faraway} ){
        $me->{nearsend} = shuffle(\@near);
        $me->{farsend}  = shuffle(\@far);
    }else{
        $me->{nearsend} = _orderly(\@near);
    }
}

# which yentas can do something with the update?
sub _compat_peers_in_dc {
    my $me = shift;
    my $dc = shift;

    my $env = conf_value('environment');
    my $dcs = AC::Yenta::Status->datacenters();
    my $map = $me->{map};
    my @id;

    for my $id (keys %{$dcs->{$dc}}){
        my $pd = AC::Yenta::Status->peer($id);

        next unless $pd->{subsystem}   eq 'yenta';
        next unless $pd->{environment} eq $env;
        next unless grep {$map eq $_} @{ $pd->{map} };
        push @id, $id;
    }
    return @id;
}

sub _start_far {
    my $me  = shift;

    my $d = shift @{ $me->{farsend} };
    return unless $d;

    # randomly pick one server in chosen dc
    my @id = grep {
        my $x = AC::Yenta::Status->peer($_);
        ($x->{status} == 200) ? 1 : 0;
    } @{$d->{id}};
    return unless @id;

    my $id = $id[ rand(@id) ];
    debug("sending $me->{info} to far site $id in $d->{dc}");
    $me->_start_peer( $id, 1 );
    inc_stat('dist_send_far');
    inc_stat('dist_send_total');
    return 1;
}

sub _start_near {
    my $me  = shift;

    my $id = shift @{ $me->{nearsend} };
    return unless $id;
    debug("sending $me->{info} to nearby site $id");
    $me->_start_peer( $id, 0 );
    inc_stat('dist_send_near');
    inc_stat('dist_send_total');
    return 1;
}

sub _start_next {
    my $me  = shift;

    my $sent;

    # pick next peers
    # start clients

    if( $me->{faraway} ){
        if( $me->{farseen} < $MAXFARSEE ){
            for (1 .. $FARSENDS){
                $sent ++ if $me->_start_far();
            }
        }
        if( $me->{nearseen} < $MAXNEARSEE ){
            for (1 .. $NEARSENDS){
                $sent ++ if $me->_start_near();
            }
        }
    }else{
        $sent ++ if $me->_start_near();
    }

    return $sent;
}

sub _start_one {
    my $me  = shift;
    my $far = shift;

    if( $far ){
        return if $me->{farseen}  >= $MAXFARSEE;
        $me->_start_far();
    }else{
        return if $me->{nearseen} >= $MAXNEARSEE;
        $me->_start_near();
    }
}

sub _start_peer {
    my $me  = shift;
    my $id  = shift;
    my $far = shift;

    my $pd   = AC::Yenta::Status->peer($id);
    my $addr = $pd->{ip};	# array of nat ip info

    my $enc = use_encryption($pd);
    my $ect = '';
    my $proto = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    $ect = $enc ? $proto->encrypt(undef, ${$me->{content}}) : ${$me->{content}} if $me->{content};

    # build request
    my $request = $proto->encode_request( {
        type		  => 'yenta_distrib',
        msgidno		  => $msgid++,
        want_reply	  => 1,
        data_encrypted	  => $enc,
        content_encrypted => $enc,
    }, {
        sender		  => AC::Yenta::Status->my_server_id(),
        hop		  => $me->{req}{hop} + 1,
        expire		  => $me->{req}{expire},
        datum		  => $me->{req}{datum},
    }, \$ect );

    # connect + send
    my $io = AC::Yenta::Kibitz::Store::Client->new($addr, undef,
                                                   $request . $ect,
                                                   info => "distrib $me->{info} to $id",
                                                  );

    if( $io ){
        $io->set_callback('load',  \&_onload,  $me, $id, $far);
        $io->set_callback('error', \&_onerror, $me, $id, $far);
        $io->start();
    }else{
        debug("start client failed");
    }
}

sub _onload {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;
    my $id  = shift;
    my $far = shift;

    debug("dist finish $me->{info} with $id => $evt->{data}{haveit}");

    if( $evt->{data}{haveit} ){
        if( $far ){
            $me->{farseen}  ++;
            inc_stat('dist_send_far_seen');
        }else{
            $me->{nearseen} ++;
            inc_stat('dist_send_near_seen');
        }
    }

    if( !$me->{faraway} && !$far ){
        # orderly distribution. hop away.
        if( $evt->{data}{haveit} ){
            shift @{$me->{nearsend}};
        }else{
            my $n = $me->{ordershift};
            $n = @{$me->{nearsend}} / 2 if $n > @{$me->{nearsend}} / 2;
            shift @{$me->{nearsend}} for (1 .. $n);
            $me->{ordershift} *= 2;
        }
    }

    $me->_start_one($far);
}

sub _onerror {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;
    my $id  = shift;
    my $far = shift;

    verbose("error distributing $me->{info} to $id");
    # don't need to track anything

    $me->_start_one($far);
}

sub _orderly {
    my $peers = shift;

    my $myself = AC::Yenta::Status->my_server_id();
    my @p = sort {$a cmp $b} @$peers;

    my @left  = grep { $_ lt $myself } @p;
    my @right = grep { $_ gt $myself } @p;

    @p = (@right, @left);
    return \@p;
}

1;
