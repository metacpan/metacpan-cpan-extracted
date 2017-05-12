# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 19:46 (EDT)
# Function: storage subsystem
#
# $Id$

package AC::Yenta::Store;
use AC::Yenta::Debug 'store';
use AC::Yenta::Config;
use AC::Import;
use AC::Yenta::Store::Map;
use AC::Yenta::Store::Sharded;
use AC::Yenta::Store::Distrib;
use AC::Yenta::Store::AE;
use AC::Yenta::Store::Expire;
use strict;

our @EXPORT = qw(store_get store_put store_want store_get_merkle store_get_internal store_set_internal store_expire store_remove);

my %STORE;


# create maps from config
sub configure {

    my $maps = $AC::Yenta::CONF->{config}{map};

    my %remove = %STORE;
    for my $map (keys %{$maps}){
        debug("configuring map $map");

        my $conf = $maps->{$map};
        my $sharded = $conf->{sharded};
        my $c  = $sharded ? 'AC::Yenta::Store::Sharded' : 'AC::Yenta::Store::Map';
        my $be = $conf->{backend};

        my $m = $c->new( $map, $be, { %$conf, recovery => 1 } );
        $STORE{$map} = $m;
        delete $remove{$map};
    }

    for my $map (keys %remove){
        debug("removing unused map '$map'");
        delete $STORE{$map};
    }
}

sub store_get {
    my $map   = shift;
    my $key   = shift;
    my $ver   = shift;

    my $m = $STORE{$map};
    return unless $m;

    return $m->get($key, $ver);
}

sub store_want {
    my $map   = shift;
    my $shard = shift;
    my $key   = shift;
    my $ver   = shift;

    my $m = $STORE{$map};
    return unless $m;

    return $m->want($shard, $key, $ver);
}

sub store_put {
    my $map   = shift;
    my $shard = shift;
    my $key   = shift;
    my $ver   = shift;
    my $data  = shift;
    my $file  = shift;	# reference
    my $meta  = shift;

    my $m = $STORE{$map};
    return unless $m;

    debug("storing $map/$key/$ver");
    $m->put($shard, $key, $ver, $data, $file, $meta);
}

# NB: only removes local copy temporarily. will be replaced at next AE run
sub store_remove {
    my $map   = shift;
    my $key   = shift;
    my $ver   = shift;

    my $m = $STORE{$map};
    return unless $m;

    return $m->remove($key, $ver);
}


sub store_get_merkle {
    my $map   = shift;
    my $shard = shift;
    my $ver   = shift;
    my $lev   = shift;

    my $m = $STORE{$map};
    return unless $m;

    return $m->get_merkle($shard, $ver, $lev);
}

sub store_get_internal {
    my $map   = shift;
    my $key   = shift;

    my $m = $STORE{$map};
    return unless $m;

    return $m->get_internal($key);
}

sub store_set_internal {
    my $map   = shift;
    my $key   = shift;
    my $val   = shift;

    my $m = $STORE{$map};
    return unless $m;

    $m->set_internal($key, $val);
}

sub store_expire {
    my $map  = shift;
    my $max  = shift;	# all versions before this

    my $m = $STORE{$map};
    return unless $m;

    $m->expire($max);
}

sub store_normalize_version {
    my $map = shift;

    my $m = $STORE{$map};
    return unless $m;

    $m->normalize_version(@_);
}

sub store_version_max {
    my $map = shift;

    my $m = $STORE{$map};
    return unless $m;

    $m->version_max(@_);
}

sub store_merkle_scrub {
    my $map = shift;

    my $m = $STORE{$map};
    return unless $m;

    $m->merkle_scrub(@_);
}

1;
