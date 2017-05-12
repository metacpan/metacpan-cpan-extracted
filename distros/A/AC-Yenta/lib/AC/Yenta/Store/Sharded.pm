# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jun-07 17:34 (EDT)
# Function: consistently-hashed shards (unfinished)
#
# $Id$


package AC::Yenta::Store::Sharded;
use AC::Yenta::Debug 'map';
use AC::Yenta::Config;
use strict;

our @ISA = 'AC::Yenta::Store::Map';

# using too large a size, makes the tree heavy at the top, thin at the bottom
# taking up more space, and slowing down AE
my $SHARDLEN = 5;

sub new {
    my $class = shift;
    my $name  = shift;
    my $bend  = shift;
    my $conf  = shift;

    # die "nyi\n";
    my $me = $class->SUPER::new( $name, $bend, $conf );
    $me->{merkle_height} = 16 + $SHARDLEN;
    return $me;
}

sub _shver_lev {
    my $me  = shift;
    my $ver = shift;
    my $lev = shift;

    return substr($ver, 0, $lev) . ('0' x (16 - $lev));
}

sub _mkey {
    my $me    = shift;
    my $shard = shift;
    my $ver   = shift;
    my $lev   = shift;

    # L/<S & mask>:V

    # least significant only
    $shard = ('0' x (16 - $SHARDLEN)) . substr($shard, - $SHARDLEN);

    if( $lev == $me->{merkle_height} ){
        return sprintf '%02X/%s:%s', $lev, $shard, $ver;
    }

    if( $lev >= $SHARDLEN ){
        return sprintf '%02X/%s:%s', $lev, $shard, $me->_shver_lev($ver, $lev - $SHARDLEN);
    }

    return sprintf '%02X/%s:%s', $lev, $me->_shver_lev($shard, 16 + $lev - $SHARDLEN), ('0' x 16);
}

sub _decode_mkey {
    my $me = shift;
    my $mk = shift;

    # 20/8843d7f92416211d:0000000049D2A314
    my($l,$sv) = split m|/|, $mk, 2;
    my($s,$v)  = split /:/, $sv, 2;
    return ($l, $s, $v);
}

sub _lkey {
    my $me = shift;
    my $k  = shift;
    my $v  = shift;
    my $s  = shift;

    return "$s:$v/$k";
}


sub _decode_lkey {
    my $me = shift;
    my $lk = shift;

    # 8843d7f92416211d:0000000049D2A314/acso
    my($sv, $k) = split m|/|, $lk, 2;
    # shard, version, key
    return ((split /:/, $sv), $k);
}

sub is_sharded {
    return 1;
}

sub is_my_shard {
    # XXX
    return 1;
}

################################################################

sub normalize_version {
    my $me    = shift;
    my $shard = shift;
    my $ver   = shift;
    my $lev   = shift;

    my($ns, $nv);
    if( $lev <= $SHARDLEN ){
        my $n = ($SHARDLEN - $lev) * 4;
        $ns = ($shard >> $n) << $n;
        $nv = 0;
    }else{
        $ns = $shard;
        my $n = ($me->{merkle_height} - $lev) * 4;
        my $nv = ($ver >> $n) << $n;
    }
    return ($ns, $nv);
}

sub version_max {
    my $me    = shift;
    my $ver   = shift;
    my $lev   = shift;

    my $bm = _version_max_bitmask();
    return $bm if $lev <= $SHARDLEN;
    $bm >>= (($lev - $SHARDLEN) * 4);
    return $ver | $bm;
}


1;
