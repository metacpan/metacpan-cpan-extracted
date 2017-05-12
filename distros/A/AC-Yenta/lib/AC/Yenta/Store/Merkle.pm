# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jun-01 18:11 (EDT)
# Function: merkle tree for detecting missing data
#
# $Id$

package AC::Yenta::Store::Merkle;
use AC::Yenta::Debug 'merkle';
use AC::Yenta::SixtyFour;
use AC::Cache;
use AC::Import;
use Digest::SHA 'sha1_base64';
use strict;

our @EXPORT = qw(encode_version decode_version encode_shard decode_shard);

my $CACHESIZE = 256;

sub merkle_init {
    my $me = shift;

    $me->{merkle_cache} = AC::Cache->new( $CACHESIZE );
}

my($cachechk, $cachemiss, $cacheT);

sub _mcget {
    my $me = shift;
    my $mk = shift;

    $cachechk++;
    my $d = $me->{merkle_cache}->fetch( $mk );
    return $d if $d;
    $cachemiss ++;

    my $db = $me->{db};
    return $db->get($me->{name}, 'merkle', $mk);
}

sub _mcput {
    my $me = shift;
    my $mk = shift;
    my $d  = shift;

    my $db = $me->{db};
    $db->put($me->{name}, 'merkle', $mk, $d);
    $me->{merkle_cache}->store( $mk, $d );
}

sub _mcdel {
    my $me = shift;
    my $mk = shift;

    my $db = $me->{db};
    $db->del($me->{name}, 'merkle', $mk);
    $me->{merkle_cache}->remove( $mk );

}

sub get_merkle {
    my $me    = shift;
    my $shard = shift;
    my $ver   = shift;
    my $lev   = shift;

    return if $lev > $me->{merkle_height};

    my $db = $me->{db};
    my $mk = $me->_mkey(encode_shard($shard), encode_version($ver), $lev);
    debug("getting merkle for $mk");

    my $d = $me->_mcget( $mk );
    return unless $d;
    my @d = split /\0/, $d;

    my @res;

    if( $^T - $cacheT > 60 ){
        debug("merk cache stats: check: $cachechk, miss: $cachemiss") if $cachechk > 1;
        $cacheT = $^T;
    }

    if( $lev == $me->{merkle_height} ){
        # data is: lkey, ...
        for my $r (@d){
            my($s,$v,$k) = $me->_decode_lkey($r);
            push @res, { version => decode_version($v), key => $k, count => 1, shard => decode_shard($s) };
        }
    }else{
        # data is: mkey => hash count, ...
        my %d = @d;
        for my $lv (keys %d){
            my($l, $s, $v) = $me->_decode_mkey( $lv );
            my($h,$c)  = split /\s/, $d{$lv};
            push @res, { version => decode_version($v), level => hex($l), hash => $h, count => $c, shard => decode_shard($s) };
        }
    }

    return \@res;
}

################################################################
# we maintain a 16-ary merkle tree of all of the <key,version>s we have stored

sub merkle {
    my $me    = shift;
    my $add   = shift;
    my @del   = @_;

    # update leaf nodes
    my %todo;
    for my $rm (@del){
        my($ns,$nv,$h,$c) = $me->_merkle_leaf_del(encode_shard($rm->{shard}), $rm->{key}, encode_version($rm->{version}));
        $todo{"$ns $nv"} = { ver => $nv, hash => $h, count => $c, shard => $ns };
    }
    if( defined $add ){
        my($ns,$nv,$h,$c) = $me->_merkle_leaf_add(encode_shard($add->{shard}), $add->{key}, encode_version($add->{version}));
        $todo{"$ns $nv"} = { ver => $nv, hash => $h, count => $c, shard => $ns };
    }

    # update upper levels
    my $level = $me->{merkle_height};

    while($level >= 0 && keys %todo){
        my %next = %todo;
        %todo = ();

        for my $hd (values %next){
            # update level - 1 with hash
            # put level-1 hash into todo
            my($ns, $nv, $h, $c) = $me->_merkle_update( $hd->{shard}, $level, $hd->{ver}, $hd->{hash}, $hd->{count} );
            $todo{"$ns $nv"} = { ver => $nv, hash => $h, count => $c, shard => $ns } if defined $nv;
        }
        $level --;
    }
}

# non-leaf node:
#  list of (ver => hash+count)
#  of up to 16 next-level-down vers
#  \0 delimited, sorted by ver

# update merkle node
sub _merkle_update {
    my $me    = shift;
    my $shard = shift;
    my $lev   = shift;
    my $ver   = shift;
    my $hash  = shift;
    my $count = shift;

    my $db = $me->{db};

    my $k0 = $me->_mkey($shard, $ver, $lev);
    my $k1 = $me->_mkey($shard, $ver, $lev - 1);

    my(undef, $nextshard, $nextver) = $me->_decode_mkey($k1);

    unless( $lev ){
        # root hash - not used
        debug("updating merkle node root => $hash");
        $me->_mcput( 'root', $hash );
        return;
    }

    # get node
    my $d = $me->_mcget( $k1 );
    my $oldh = sha1_base64($d);
    my %d = split /\0/, $d;

    if($hash){
        # add/update
        debug("updating merkle node $k1 + { $k0 => $hash, $count }");
        $d{$k0} = "$hash $count";
    }else{
        # remove
        debug("updating merkle node $k1 - { $k0 => empty }");
        delete $d{$k0};
    }

    if( keys %d ){

        $d = join("\0", map {"$_\0$d{$_}"} (sort keys %d));
        $me->_mcput( $k1, $d );
        my $newh = sha1_base64($d);
        return if $newh eq $oldh;	# unchanged
        return ($nextshard, $nextver, $newh, scalar keys %d);
    }else{
        $me->_mcdel( $k1 );
        return unless $oldh;		# unchanged
        return ($nextshard, $nextver, undef);
    }
}

# leaf nodes:
#   list of all "ver/key"
#   \0 delimited. sorted by "ver/key"

# add new <key,version> to merkle leaf
sub _merkle_leaf_add {
    my $me    = shift;
    my $shard = shift;
    my $key   = shift;
    my $ver   = shift;

    my $db = $me->{db};
    my $mk = $me->_mkey($shard, $ver, $me->{merkle_height});
    my $vk = $me->_lkey($key, $ver, $shard);

    debug("adding to merkle leaf $mk - $vk");

    # get current data
    my $d = $me->_mcget( $mk );
    my @d = split /\0/, $d;
    # append new item + uniqify
    my %d;
    @d{@d} = ();
    $d{$vk}   = undef;
    $d = join("\0", sort keys %d);
    $me->_mcput( $mk, $d );

    my $hash = sha1_base64($d);
    return ($shard, $ver, $hash, scalar keys %d);
}

# remove <key,version> from merkle leaf
sub _merkle_leaf_del {
    my $me    = shift;
    my $shard = shift;
    my $key   = shift;
    my $ver   = shift;

    my $db = $me->{db};
    my $mk = $me->_mkey($shard, $ver, $me->{merkle_height});
    my $vk = $me->_lkey($key, $ver, $shard);

    debug("removing from merkle leaf $mk - $vk");

    # get current data
    my $d = $me->_mcget( $mk );
    my @d = split /\0/, $d;
    # remove item
    @d = grep { $vk ne $_ } @d;

    if( @d ){
        $d = join("\0", @d);
        $me->_mcput( $mk, $d );

        my $hash = sha1_base64($d);
        return ($shard, $ver, $hash, scalar @d);
    }else{
        $me->_mcdel( $mk );
        # empty node => empty hash
        return ($shard, $ver, undef);
    }
}

################################################################

sub _get_actual_keys {
    my $me    = shift;
    my $shard = shift;
    my $ver   = shift;

    my $db = $me->{db};

    # get range on data
    my @key = map {
        my $k = $_->{k}; $k =~ s|.*/||; $k
    } $db->range($me->{name}, 'data', encode_version($ver), encode_version($ver + 1));
    debug("actual key: @key");

    return @key unless defined $shard;

    # get vers list to filter on shard
    my $sh = encode_shard($shard);
    return grep {
        my $k = $_;

        my $vl = $db->get($me->{name}, 'vers', $k);
        my($s) = $vl =~ /;\s*(.*)/;

        $s == $sh;
    } @key;
}

# check merkle leaf node against actual data
sub merkle_scrub {
    my $me    = shift;
    my $shard = shift;
    my $ver   = shift;

    debug("scrub $me->{name} $shard/$ver");

    # get list of keys from merkle leaf node
    my $mlist = $me->get_merkle($shard, $ver, $me->{merkle_height}) || [];
    my @mkey  = map { $_->{key} } @$mlist;
    my %mkey;
    @mkey{@mkey} = @mkey;

    # get list of keys from actual data
    my @akey  = $me->_get_actual_keys( $shard, $ver );

    # compare lists

    for my $k (@akey){
        next if $mkey{$k};
        debug("missing key in merkle tree: $shard/$ver/$k");
        $me->merkle( { key => $k, shard => $shard, version => $ver } );
    }
}


################################################################

sub _mkey {
    my $me    = shift;
    my $shard = shift;
    my $ver   = shift;
    my $lev   = shift;

    # 10/000484D6594DB72B
    sprintf '%02X/%s', $lev, $me->_ver_lev($ver, $lev);
}

sub _decode_mkey {
    my $me = shift;
    my $mk = shift;

    # 10/000484D6594DB72B
    my($l,$sv) = split m|/|, $mk, 2;
    # level, shard, version
    return ($l, undef, $sv);
}

sub _lkey {
    my $me = shift;
    my $k  = shift;
    my $v  = shift;
    my $s  = shift;

    # 000484D6594DB72B/foobar
    return "$v/$k";
}

sub _decode_lkey {
    my $me = shift;
    my $lk = shift;

    # 000484D6594DB72B/foobar
    my($sv, $k) = split m|/|, $lk, 2;
    # shard, version, key
    return (undef, $sv, $k);
}

sub _ver_lev {
    my $me  = shift;
    my $ver = shift;
    my $lev = shift;

    return substr($ver, 0, $lev) . ('0' x ($me->{merkle_height} - $lev));
}

################################################################

sub encode_version {
    my $v = shift;
    return x64_number_to_hex($v);
}

sub decode_version {
    my $v = shift;
    return x64_hex_to_number($v);
}

sub encode_shard {
    my $v = shift;
    return undef unless defined $v;
    return x64_number_to_hex($v);
}

sub decode_shard {
    my $v = shift;
    return undef unless defined $v;
    return x64_hex_to_number($v);
}

sub _version_max_bitmask {
    return x64_sixty_four_ones();
}


# numeric version + level => numeric version
sub normalize_version {
    my $me    = shift;
    my $shard = shift;
    my $ver   = shift;
    my $lev   = shift;

    my $n = ($me->{merkle_height} - $lev) * 4;
    my $nv = ($ver >> $n) << $n;
    return (undef, $nv);
}

sub version_max {
    my $me    = shift;
    my $ver   = shift;
    my $lev   = shift;

    my $bm = _version_max_bitmask() >> ($lev * 4);
    return $ver | $bm;
}


1;
