# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 19:21 (EDT)
# Function: storage maps
#
# $Id$

package AC::Yenta::Store::Map;
use AC::Yenta::Store::File;
use AC::Yenta::Store::Merkle;
use AC::Yenta::Debug 'map';
use AC::Yenta::Conf;
use AC::Cache;
use strict;

our @ISA = 'AC::Yenta::Store::Merkle';

my $DEFAULT = 'bdb';
my %BACKEND ;
my $CACHESIZE = 1024;	# gives us ~90% cache hit rate


sub add_backend {
    my $class = shift;
    my $name  = shift;
    my $impl  = shift;

    $BACKEND{$name} = $impl;
}

sub new {
    my $class = shift;
    my $name  = shift;
    my $bkend = shift;
    my $conf  = shift;

    unless( $bkend ){
        # from extension, or default
        my($ext) = $conf->{dbfile} =~ /\.(.+)$/;
        $bkend = $ext if $BACKEND{$ext};
    }

    my $c  = $BACKEND{$bkend || $DEFAULT};
    unless( $c ){
        problem("invalid storage backend: $bkend - ignoring map");
        return ;
    }

    debug("configuring map $name with $c");

    my $db = $c->new( $name, $conf );
    my $fs = AC::Yenta::Store::File->new( $name, $conf );

    my $me = bless {
        name		=> $name,
        conf		=> $conf,
        db		=> $db,
        fs		=> $fs,
        merkle_height	=> 16,
        vers_cache	=> AC::Cache->new( $CACHESIZE ),
    }, $class;

    $me->merkle_init();

    return $me;
}

my($cachechk, $cachemiss, $cacheT);
sub _versget {
    my $me  = shift;
    my $key = shift;

    $cachechk ++;
    my $d = $me->{vers_cache}->fetch( $key );
    return @$d if $d;

    $cachemiss ++;
    my $db = $me->{db};
    my($versions, $foundver) = $db->get($me->{name}, 'vers', $key);
    my @d = split /\s+/, $versions;
    $me->{vers_cache}->store( $key, \@d );
    return @d;
}

sub _versput {
    my $me  = shift;
    my $key = shift;

    my $db = $me->{db};
    $db->put($me->{name}, 'vers', $key, join(' ', @_));
    $me->{vers_cache}->store( $key, \@_ );
}

sub _versdel {
    my $me  = shift;
    my $key = shift;

    $me->{vers_cache}->remove( $key );
}

sub get {
    my $me   = shift;
    my $key  = shift;
    my $ver  = shift;

    my $db = $me->{db};

    my @versions = $me->_versget( $key );
    return unless @versions;
    debug("found ver: @versions");

    if( $ver ){
        $ver = encode_version($ver);
        return unless grep { $_ eq $ver } @versions;
    }else{
        $ver = $versions[0];
    }

    my $vk = $me->vkey($key, $ver);
    my $extver = decode_version($ver);

    my($data, $founddat) = $db->get($me->{name}, 'data', $vk);

    if( wantarray ){
        if( $founddat ){
            my $meta = $db->get($me->{name}, 'meta', $vk);
            my $file = $me->{fs}->get($data) if $data;
            return( $data, $extver, $file, $meta );
        }else{
            # we don't have data, but we have it in history; fake it.
            return (undef, $extver, undef, undef);
        }
    }

    return $data;
}

# someone sent me something, do I want it?
sub want {
    my $me    = shift;
    my $shard = shift;
    my $key   = shift;
    my $ver   = shift;

    my $cf = $me->{conf};
    my $db = $me->{db};
    my $v  = encode_version($ver);

    # data belongs here?
    return if $me->is_sharded() && !$me->is_my_shard($shard);

    my @versions = $me->_versget( $key );

    if( $^T - $cacheT > 60 ){
        debug("cache stats: check: $cachechk, miss: $cachemiss") if $cachechk > 1;
        $cacheT = $^T;
    }

    # I have it?
    return if grep { $_ eq $v } @versions;

    # expired?
    return if $cf->{expire} && ($ver < timet_to_yenta_version($^T - $cf->{expire}));

    # I want everything?
    return 1 unless $cf->{history};

    # I have room for it?
    return 1 if @versions < $cf->{history};

    # I can make room for it?
    return 1 if $v gt $versions[-1];

    # I'll just throw it away.
    return;
}

sub put {
    my $me    = shift;
    my $shard = shift;
    my $key   = shift;
    my $ver   = shift;
    my $data  = shift;
    my $file  = shift;	# reference
    my $meta  = shift;

    my $cf = $me->{conf};
    my $db = $me->{db};
    my $v  = encode_version($ver);
    my $vk = $me->vkey($key, $v);

    debug("storing $vk");

    # get version history
    my @deletehist;
    my %deletedata;
    my @versions = $me->_versget( $key );

    return if grep { $_ eq $v } @versions;	# dupe!

    # is this the newest version? should we save this data?
    if( !@versions || ($v gt $versions[0]) || $cf->{keepold} ){

        # save file; data is filename
        if( $file ){
            my $r = $me->{fs}->put($data, $file);
            return unless $r;
        }
        # put meta + data
        $db->put($me->{name}, 'meta', $vk, $meta) if length $meta;
        $db->put($me->{name}, 'data', $vk, $data);

        unless( $cf->{keepold} ){
            # unless we are keeping old data, remove previous version
            $deletedata{$versions[0]} = 1 if @versions;
        }
    }

    # add new version to list. newest 1st
    @versions = sort {$b cmp $a} (@versions, $v);
    if( $cf->{history} && @versions > $cf->{history} ){
        # trim list
        my @rm = splice @versions, $cf->{history}, @versions, ();
        push @deletehist, (map { ({version => decode_version($_), key => $key, shard => $shard}) } @rm);
        $deletedata{$_} = 1 for @_;
    }
    if( $me->is_sharded() ){
        # QQQ - shard changed?
        $db->put($me->{name}, 'shard', $key, encode_shard($shard || 0));
    }

    my $dd = join(' ', map { $_->{version} } @deletehist);
    debug("version list: @versions [delete: $dd]");

    $me->_versput( $key, @versions );

    # update merkles
    $me->merkle( { shard => $shard, key => $key, version => $ver }, @deletehist);

    # delete old data
    for my $rm (keys %deletedata){
        debug("removing old version $key/$rm");
        my $rmvk = $me->vkey($key, $rm);
        $db->del($me->{name}, 'data', $rmvk);
        $db->del($me->{name}, 'meta', $rmvk);
    }

    $db->sync();

    return 1;
}

sub remove {
    my $me  = shift;
    my $key = shift;
    my $ver = shift;

    my $shard = $me->_remove( $key, $ver );
    $me->merkle( undef, { shard => decode_shard($shard), key => $key, version => $ver } );
    $me->{db}->sync();

    return 1;
}

# NB: does not update merkle tree
sub _remove {
    my $me  = shift;
    my $key = shift;
    my $ver = shift;

    my $db = $me->{db};
    my $v  = encode_version($ver);

    my $cshard   = $db->get($me->{name}, 'shard', $key);
    my @versions = grep { $_ ne $v } $me->_versget( $key );

    debug("new ver list: @versions");

    if( @versions ){
        $me->_versput( $key, @versions );
    }else{
        $db->del($me->{name}, 'vers',  $key);
        $db->del($me->{name}, 'shard', $key);
        $me->_versdel( $key );
    }

    my $vk = $me->vkey($key, $ver);
    $db->del($me->{name}, 'data', $vk);
    $db->del($me->{name}, 'meta', $vk);

    return $cshard;
}

################################################################

sub range {
    my $me    = shift;
    my $start = shift;
    my $end   = shift;

    my $db = $me->{db};
    return $db->range($me->{name}, 'vers', $start, $end);
}

################################################################

sub get_internal {
    my $me  = shift;
    my $key = shift;

    my($d, $found) = $me->{db}->get($me->{name}, 'internal', $key);
    return $d;
}

sub set_internal {
    my $me  = shift;
    my $key = shift;
    my $val = shift;

    $me->{db}->put($me->{name}, 'internal', $key, $val);
}

################################################################

sub expire {
    my $me     = shift;
    my $expire = shift;

    debug("expiring $me->{name}");

    my $db = $me->{db};

    # walk merkle tree, find all k/v to remove
    my @delete;

    my @walk = { level => 0, version => 0, shard => 0 };
    while(@walk){
        my @next;
        for my $node (@walk){
            my $res = $me->get_merkle( $node->{shard}, $node->{version}, $node->{level} );

            for my $r (@$res){
                next if $r->{version} > $expire;
                if( $r->{key} ){
                    push @delete, { key => $r->{key}, version => $r->{version}, shard => $r->{shard} };
                }else{
                    push @next, $r;
                }
            }
        }
        @walk = @next;
    }

    # remove k/v
    for my $r (@delete){
        debug("expiring $r->{key}/$r->{version}");
        $me->_remove( $r->{key}, $r->{version} );
    }

    # update merkle
    $me->merkle(undef, @delete);

    $db->sync();
}

################################################################

sub vkey {
    my $me = shift;
    my $k  = shift;
    my $v  = shift;

    return "$v/$k";
}

################################################################

sub is_sharded {
    return 0;
}

sub is_my_shard {
    return 1;
}


1;

=head1 NAME

AC::Yenta::Store::Map - persistent storage for yenta maps

=head1 SYNOPSIS

  your code:

    AC::Yenta::Store::Map->add_backend( postgres => 'Local::Yenta::Postgres' );

  your config:

    map mappyfoo {
        backend     postgres
        # ...
    }

=cut

