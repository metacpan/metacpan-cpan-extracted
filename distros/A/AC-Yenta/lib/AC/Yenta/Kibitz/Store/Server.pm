# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-01 11:06 (EDT)
# Function: server side api of storage system
#
# $Id$

package AC::Yenta::Kibitz::Store::Server;
use AC::Yenta::Debug 'store_server';
use AC::Yenta::Store;
use AC::Yenta::Config;
use AC::Dumper;
use JSON;
use Digest::SHA 'sha1_base64';
require 'AC/protobuf/yenta_getset.pl';
require 'AC/protobuf/yenta_check.pl';
use strict;

my $TIMEOUT = 1;

sub api_get {
    my $io      = shift;
    my $proto   = shift;
    my $gpb     = shift;
    my $content = shift;	# not used

    unless( $proto->{want_reply} ){
        $io->shut();
        return;
    }

    # decode request
    my $req;
    eval {
        $req = ACPYentaGetSet->decode( $gpb );
    };
    if(my $e = $@){
        problem("cannot decode request: $e");
        $io->shut();
        return;
    }

    # process requests
    my @res;
    my $rescont;
    for my $r (@{ $req->{data} }){
        debug("get request: $r->{map}, $r->{key}, $r->{version}");
        my($data, $ver, $file, $meta) = store_get( $r->{map}, $r->{key}, $r->{version} );
        my $res = {
            map		=> $r->{map},
            key		=> $r->{key},
        };

        if( $meta && $file ){
            unless( _check_content( $meta, $file ) ){
                problem("content SHA1 check failed: $r->{map}, $r->{key}, $ver - removing");
                # QQQ - remove from system, (and let AE get a new copy)?
                store_remove($r->{map}, $r->{key}, $ver);
                # tell caller it was not found
                $ver = undef;
            }
        }

        if( defined $ver ){
            $res->{version} = $ver;
            $res->{value}   = $data;
            $res->{meta}    = $meta  if defined $meta;
            if( $file ){
                # if one file to send, send it as content
                if( @{$req->{data}} == 1 ){
                    $rescont = $file;
                }else{
                    $res->{file} = $$file;
                }
            }
        }
        push @res, $res;
    }

    # encode results
    my $ect = '';
    my $yp = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    $ect = $proto->{data_encrypted} ? $yp->encrypt(undef, $$rescont) : $$rescont if $rescont;
    my $response = $yp->encode_reply( {
        type		  => 'yenta_get',
        msgid		  => $proto->{msgid},
        is_reply	  => 1,
        data_encrypted	  => $proto->{data_encrypted},
        content_encrypted => $proto->{data_encrypted},
    }, { data => \@res }, \$ect );

    debug("sending get reply");
    $io->timeout_rel($TIMEOUT);
    $io->{writebuf_timeout} = $TIMEOUT;
    $io->write_and_shut( $response . $ect );

}

sub api_check {
    my $io      = shift;
    my $proto   = shift;
    my $gpb     = shift;
    my $content = shift;	# not used

    unless( $proto->{want_reply} ){
        $io->shut();
        return;
    }

    # decode request
    my $req;
    eval {
        $req = ACPYentaCheckRequest->decode( $gpb );
    };
    if(my $e = $@){
        problem("cannot decode request: $e");
        $io->shut();
        return;
    }

    debug("check request: $req->{map}, $req->{version}, $req->{level}");

    my @res;
    my @todo = { version => $req->{version}, shard => $req->{shard} };

    # the top of the tree will be fairly sparse,
    # return up to several levels if they are sparse
    for my $l (0 .. 32){
        my $cl = $req->{level} + $l;
        my @lres;
        my $nexttot;
        for my $do (@todo){
            my @r = _get_check( $req->{map}, $do->{shard}, $do->{version}, $cl );
            push @lres, @r;
            for (@r){
                $nexttot += $_->{key} ? ($_->{count} / 8) : $_->{count};
            }
        }
        push @res, @lres;
        @todo = ();
        last unless @lres;				# reached the bottom of the tree
        last if @res > 64;				# got enough results
        last if (@lres > 2) && ($nexttot > @lres + 2);	# less sparse region
        # get the next level also
        @todo = @lres;
    }

    # encode results
    my $yp = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    my $response = $yp->encode_reply( {
        type		  => 'yenta_check',
        msgid		  => $proto->{msgid},
        is_reply	  => 1,
        data_encrypted	  => $proto->{data_encrypted},
        }, { check => \@res } );

    debug("sending check reply");
    $io->timeout_rel($TIMEOUT);
    $io->{writebuf_timeout} = $TIMEOUT;
    $io->write_and_shut( $response );

}

# get + process merkle data
sub _get_check {
    my $map   = shift;
    my $shard = shift;
    my $ver   = shift;
    my $lev   = shift;

    my $res = store_get_merkle($map, $shard, $ver, $lev);
    return unless $res;
    for my $r (@$res) {
        $r->{map}   = $map;
    }

    return @$res;
}

sub api_distrib {
    my $io      = shift;
    my $proto   = shift;
    my $gpb     = shift;
    my $content = shift;	# reference

    # decode request
    my $req;
    eval {
        $req = ACPYentaDistRequest->decode( $gpb );
        die "invalid k/v for put request\n" unless $req->{datum}{key} && $req->{datum}{version};
    };
    if(my $e = $@){
        my $enc = $proto->{data_encrypted} ? ' (encrypted)' : '';
        problem("cannot decode request: peer: $io->{peerip} $enc, $e");
        $io->shut();
        return;
    }

    unless( conf_map( $req->{datum}{map} ) ){
        problem("distribute request for unknown map '$req->{datum}{map}' - $io->{info}");
        _reply_error($io, $proto, 404, 'Map Not Found');
        return;
    }

    my $v = $req->{datum};

    # do we already have ?
    my $want = store_want( $v->{map}, $v->{shard}, $v->{key}, $v->{version} );

    if( $want ){
        # put

        debug("put request from $io->{peerip}: $v->{map}, $v->{key}, $v->{version}");

        # file content is passed by reference, to avoid large copies
        $content ||= \ $v->{file} if $v->{file};

        # check
        if( $v->{meta} && $content ){
            unless( _check_content( $v->{meta}, $content ) ){
                problem("content SHA1 check failed: $req->{datum}{map}, $req->{datum}{key}, $req->{datum}{version}");
                $io->shut();
                return;
            }
        }

        $want = store_put( $v->{map}, $v->{shard}, $v->{key}, $v->{version}, $v->{value},
                   $content, $v->{meta} );

        # distribute to other systems
        AC::Yenta::Store::Distrib->new( $req, $content ) if $want;
    }else{
        debug("put from $io->{peerip} unwanted: $v->{map}, $v->{shard}, $v->{key}, $v->{version}");
    }


    unless( $proto->{want_reply} ){
        $io->shut();
        return;
    }

    # encode results
    my $yp = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    my $response = $yp->encode_reply( {
        type		=> 'yenta_distrib',
        msgid		=> $proto->{msgid},
        is_reply	=> 1,
        data_encrypted	=> $proto->{data_encrypted},
    }, { status_code => 200, status_message => 'OK', haveit => !$want } );

    debug("sending distrib reply");
    $io->timeout_rel($TIMEOUT);
    $io->write_and_shut( $response );

}

sub _check_content {
    my $meta = shift;
    my $cont = shift;

    return 1 unless $meta && $meta =~ /^\{/;

    eval {
        $meta = decode_json($meta);
    };
    return 1 if $@;

    if( $meta->{sha1} ){
        my $chk = sha1_base64( $$cont );
        return unless $chk eq $meta->{sha1};
    }
    if( $meta->{size} ){
        my $len = length($$cont);
        return unless $len == $meta->{size};
    }

    return 1;
}

sub _reply_error {
    my $io    = shift;
    my $proto = shift;
    my $code  = shift;
    my $msg   = shift;

    my $yp = AC::Yenta::Protocol->new( secret => conf_value('secret') );
    my $response = $yp->encode_reply( {
        type		=> 'yenta_distrib',
        msgid		=> $proto->{msgid},
        is_reply	=> 1,
        is_error	=> 1,
        data_encrypted	=> $proto->{data_encrypted},
    }, {
        status_code     => $code,
        status_message  => $msg,
        haveit		=> 0,
    } );

    debug("sending distrib reply");
    $io->write_and_shut( $response );
}

1;
