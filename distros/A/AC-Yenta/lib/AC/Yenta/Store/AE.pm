# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-03 10:05 (EDT)
# Function: Anti-Entropy (find missing/stale data, and sync up)
#
# $Id$

package AC::Yenta::Store::AE;
use AC::Yenta::Store;
use AC::Yenta::Config;
use AC::Yenta::Debug 'ae';
use AC::Yenta::Stats;
use AC::Yenta::Conf;
use AC::Yenta::MySelf;
use AC::Yenta::Protocol;
use AC::DC::Sched;
use AC::Misc;
use Socket;
use strict;

my $MAXGET     = 32;	# maximum number of records per fetch
my $MAXFILES   = 4;	# maximum number of files per fetch
my $MAXFETCH   = 32;	# maximum number of simultaneous fetches
my $MAXMISSING = 10;	# maximum number of missing records to be considered up to date
my $MAXLOAD    = 0.5;	# do not run if load average is too high
my $EXPIRE     = 300;	# expire hung job after this long
my $TOONEW     = 60;	# don't consider things missing if they are less than this old

my $msgid      = $$;
my %DONE;		# maps which have finished
my @AE;			# normally, just one

AC::DC::Sched->new(
    info	=> 'anti-entropy',
    freq	=> 60,
    func	=> \&AC::Yenta::Store::AE::periodic,
   );

sub new {
    my $class = shift;

    my $me = bless {
        badnode		=> [ {version => 0, shard => 0, level => 0} ],
        cache		=> {},
        kvneed		=> [],
        kvneedorig	=> [],
        kvfetching	=> 0,
        missing		=> 0,
    }, $class;

    debug("new ae");
    $me->_pick_map()  || return;

    AC::Yenta::Store::store_set_internal($me->{map}, 'ae_last_start', $^T);
    $me->_init_peer() || return;

    debug("checking $me->{map} with $me->{peer}{id}");
    inc_stat('ae_runs');
    $me->_next_step();

    push @AE, $me;
    return $me;
}

sub periodic {
    # kill dead sessions, start new ones

    my @keep;
    for my $ae (@AE){
        if( $ae->{timestamp} + $EXPIRE > $^T ){
            push @keep, $ae;
        }
    }
    @AE = @keep;

    return if @AE;
    return if loadave() > (conf_value('ae_maxload') || $MAXLOAD);
    __PACKAGE__->new();
}

# we are up to date if we have AE'ed every map at least once since starting
sub up_to_date {
    my $class = shift;

    my $maps = conf_value('map');
    for my $m (keys %$maps){
        return 0 unless $DONE{$m};
    }
    return 1;
}

################################################################

# find most stale map
sub _pick_map {
    my $me = shift;

    my $maps = conf_value('map');
    my(@best, $bestv);
    for my $m (keys %$maps){
        my $lt = AC::Yenta::Store::store_get_internal($m, 'ae_last_start');
        if( !@best || $lt < $bestv ){
            @best = $m;
            $bestv = $lt;
        }elsif( $lt == $bestv ){
            push @best, $m;
        }
    }

    return unless @best;

    my $map = $best[ rand(@best) ];
    $me->{map} = $map;

    # is this a data or file map?
    # adjust accordingly
    my $cf = conf_map( $map );
    $me->{has_files} = 1 if $cf->{basedir};
    $me->{maxget} = $me->{has_files} ? $MAXFILES : $MAXGET;
    $me->{expire} = $cf->{expire};

    return 1;
}

sub _init_peer {
    my $me = shift;

    my $here = my_datacenter();
    my @peer = AC::Yenta::Status->mappeers( $me->{map} );
    my $env  = conf_value('environment');

    my(@near, @far, @ood);

    for my $p (@peer){
        my $d = AC::Yenta::Status->peer($p);
        next unless $d->{environment} eq $env;
        next unless $d->{status}      == 200;

        if( $d->{uptodate} ){
            if( $d->{datacenter} eq $here ){
                push @near, $d;
            }else{
                push @far, $d;
            }
        }else{
            push @ood, $d;
        }
    }

    $me->{peers_near} = \@near if @near;
    $me->{peers_far}  = \@far  if @far;
    $me->{peers_ood}  = \@ood  if @ood;

    my $peer = $me->_pick_peer();
    return unless $peer;
    $me->{peer} = $peer;
    return 1;

}

sub _pick_peer {
    my $me = shift;

    my @peer;
    if( $me->{peers_near} && $me->{peers_far} ){
        # prefer close peers, usually
        if( int(rand(8)) ){
            @peer = @{$me->{peers_near}};
        }else{
            @peer = @{$me->{peers_far}};
        }
    }elsif( $me->{peers_near} ){
        @peer = @{$me->{peers_near}};
    }elsif( $me->{peers_far} ){
        @peer = @{$me->{peers_far}};
    }elsif( $me->{peers_ood} ){
        # only use out-of-date peers as a last resort
        # NB: if we never used ood peers, we'd have a bootstrap deadlock
        @peer = @{$me->{peers_ood}};
    }

    return unless @peer;
    my $peer = $peer[ rand(@peer) ];

    return $peer;
}

################################################################

sub _finished {
    my $me = shift;

    debug("finished $me->{map}");
    $DONE{$me->{map}} = $^T if $me->{missing} < $MAXMISSING;
    AC::Yenta::Store::store_set_internal($me->{map}, 'ae_last_finish', $^T);
    @AE = grep{ $_ != $me } @AE;
}

sub _next_step {
    my $me = shift;

    $me->{timestamp} = $^T;

    if( $me->{kvfetching} < $MAXFETCH ){
        # any missing data?
        if( @{$me->{kvneedorig}} || @{$me->{kvneed}} ){
            debug("starting nextgetkv ($me->{kvfetching})");
            $me->_next_get_kv();
        }
    }

    # check nodes?
    if( @{$me->{badnode}} ){
        $me->_start_check();
        return;
    }

    $me->_finished();
}

################################################################

sub _start_check {
    my $me = shift;

    my $node = shift @{$me->{badnode}};
    debug("checking next node: $me->{map} $node->{level}/$node->{version}");
    inc_stat('ae_check_node');

    my $enc     = use_encryption($me->{peer});
    my $proto   = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    my $request = $proto->encode_request( {
        type		=> 'yenta_check',
        msgidno		=> $msgid++,
        want_reply	=> 1,
        data_encrypted	=> $enc,
    }, {
        map		=> $me->{map},
        level		=> $node->{level},
        version		=> $node->{version},
        shard		=> $node->{shard},
    } );

    # connect + send
    my $io = AC::Yenta::Kibitz::Store::Client->new(
        $me->{peer}{ip}, undef,
        $request,
        info => "AE node $node->{level}/$node->{version} with $me->{peer}{id}" );

    if( $io ){
        $io->set_callback('load',  \&_check_load,  $me);
        $io->set_callback('error', \&_check_error, $me);
        $io->start();
    }

}

sub _check_load {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;


    debug("check results");
    $evt->{data} ||= {};

    # determine highest level returned

    my @keydata;
    my @nodedata;
    my $maxlev = 0;

    for my $d ( @{ $evt->{data}{check} }){
        debug("recvd result for $d->{map} $d->{level}/$d->{shard}/$d->{version} $d->{key}");

        if( $d->{key} ){
            push @keydata, $d;
            next;
        }
        next if $d->{level} < $maxlev;

        if( $d->{level} > $maxlev ){
            @nodedata = ();
            $maxlev   = $d->{level};
        }
        push @nodedata, $d;
    }

    if( @keydata ){
        $me->_check_result_keys( \@keydata );
    }elsif( @nodedata ){
        $me->_check_result_nodes( $maxlev, \@nodedata );
    }

    $me->_next_step();
}

sub _check_error {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;

    verbose("AE check error with $me->{peer}{id} map $me->{map} ($io->{info})");
    $me->_next_step();
}

sub _check_result_keys {
    my $me  = shift;
    my $chk = shift;

    my %vscnt;
    my %vsadd;

    for my $d (@$chk){
        inc_stat('ae_check_key');
        my $vsk = "$d->{version} $d->{shard}";
        $vscnt{ $vsk } ++;

        next unless AC::Yenta::Store::store_want( $me->{map}, $d->{shard}, $d->{key}, $d->{version} );

        debug("missing data $d->{map}/$d->{key}/$d->{shard}/$d->{version}");
        push @{$me->{kvneed}}, { key => $d->{key}, version => $d->{version}, shard => $d->{shard} };
        inc_stat('ae_key_missing');
        $me->{missing} ++;
        $vsadd{ $vsk } ++;
    }
}

sub _is_expired {
    my $me  = shift;
    my $map = shift;
    my $lev = shift;
    my $ver = shift;

    return unless $me->{expire};

    my $vmx = AC::Yenta::Store::store_version_max( $map, $ver, $lev );
    return unless defined $vmx;

    if( $vmx < timet_to_yenta_version($^T - $me->{expire} + $TOONEW) ){
        debug("skipping expired $lev/$ver - $vmx");
        return 1;
    }

    return;
}

sub _check_result_nodes {
    my $me  = shift;
    my $lev = shift;
    my $chk = shift;

    # determine all of the base versions of the recvd data
    my %ver;
    for my $d (@$chk){
        my($shard, $ver) = AC::Yenta::Store::store_normalize_version( $d->{map}, $d->{shard}, $d->{version}, $lev - 1);
        $ver{"$ver $shard"} = { ver => $ver, shard => $shard };
    }

    # get all of our merkle data for these versions
    my %merkle;
    my $t_new = timet_to_yenta_version($^T - $TOONEW);

    for my $d (values %ver){
        next if $d->{ver} > $t_new;				# too new, ignore
        next if $me->_is_expired($me->{map}, $lev, $d->{ver});
        # RSN - skip unwanted shards
        my $ms = AC::Yenta::Store::store_get_merkle($me->{map}, $d->{shard}, $d->{ver}, $lev - 1);
        for my $m (@$ms){
            # debug("my hash $me->{map} $m->{level}/$m->{shard}/$m->{version} => $m->{hash}");
            $merkle{"$m->{version} $m->{shard}"} = $m->{hash};
        }
    }

    # compare (don't bother with things that are too new (the data may still be en route))
    for my $d (@$chk){
        next if $d->{version} > $t_new;				# too new, ignore
        next if $me->_is_expired($me->{map}, $lev, $d->{version});
        # RSN - skip unwanted shards
        my $hash = $merkle{"$d->{version} $d->{shard}"};

        if( $d->{hash} eq $hash ){
            debug("check $d->{level}/$d->{shard}/$d->{version}: $d->{hash} => match");
            next;
        }else{
            debug("check $d->{level}/$d->{shard}/$d->{version}: $d->{hash} != $hash");
        }

        # stick them at the front
        unshift @{$me->{badnode}}, { version => $d->{version}, shard => $d->{shard}, level => $lev };
    }
}

################################################################
# we try to spread the load out by picking a random peer to fetch from
# if that peer does not have the data, we retry using the original peer
# (the one that said it has the data)

sub _next_get_kv {
    my $me = shift;

    return $me->_start_get_kv_orig() if @{$me->{kvneedorig}};
    return $me->_start_get_kv_any()  if @{$me->{kvneed}};
}

sub _start_get_kv_any {
    my $me = shift;

    my @get = splice @{$me->{kvneed}}, 0, $me->{maxget}, ();

    # pick a peer
    my $peer = $me->_pick_peer();
    debug("getting kv data from peer $peer->{id}");
    $me->_start_get_kv( $peer, 1, \@get);
}

sub _start_get_kv_orig {
    my $me = shift;

    my @get = splice @{$me->{kvneedorig}}, 0, $me->{maxget}, ();

    debug("getting kv data from current peer");
    $me->_start_get_kv( $me->{peer}, 0, \@get);
}

sub _start_get_kv {
    my $me    = shift;
    my $peer  = shift;
    my $retry = shift;
    my $get   = shift;

    # insert map into request
    $_->{map} = $me->{map} for @$get;

    # for (@$get){ debug("requesting $_->{key}/$_->{version}") }

    my $enc   = use_encryption($peer);
    my $proto = AC::Yenta::Protocol->new( secret => conf_value('secret') );

    # build request
    my $request = $proto->encode_request( {
        type		  => 'yenta_get',
        msgidno		  => $msgid++,
        want_reply	  => 1,
        data_encrypted	  => $enc,
    }, {
        data		  => $get,
    } );

    # connect + send
    debug("sending to $peer->{id}");
    my $io = AC::Yenta::Kibitz::Store::Client->new($peer->{ip}, undef, $request,
                                                  info => "AE getkv from $peer->{id}" );

    if( $io ){
        $me->{kvfetching} ++;
        $io->set_callback('load',  \&_getkv_load,  $me, $retry, $get);
        $io->set_callback('error', \&_getkv_error, $me, $retry, $get);
        $io->start();
    }
}

sub _getkv_load {
    my $io    = shift;
    my $evt   = shift;
    my $me    = shift;
    my $retry = shift;
    my $get   = shift;

    $me->{kvfetching} --;
    $evt->{data} ||= {};

    debug("got kv data results");

    my %need = map {
        ( "$_->{key}/$_->{version}" => $_ )
    } @$get;

    for my $d ( @{$evt->{data}{data}}){
        debug("got $d->{map}/$d->{key}/$d->{version}");
        next unless $d->{key} && $d->{version};		# not found

        delete $need{ "$d->{key}/$d->{version}" };
        my $file = $evt->{content};
        $file = \ $d->{file} if $d->{file};

        AC::Yenta::Store::store_put( $d->{map}, $d->{shard}, $d->{key}, $d->{version},
                                     $d->{value}, $file, $d->{meta} );

    }

    push @{$me->{kvneedorig}}, (values %need) if $retry;

    $me->_next_get_kv();

}

sub _getkv_error {
    my $io    = shift;
    my $evt   = shift;
    my $me    = shift;
    my $retry = shift;
    my $get   = shift;

    $me->{kvfetching} --;

    if( $retry ){
        push @{$me->{kvneedorig}}, @$get;
    }

    $me->_next_get_kv();
}

1;
