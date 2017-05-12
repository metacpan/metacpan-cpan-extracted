# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jun-16 10:50 (EDT)
# Function: 
#
# $Id$

package AC::Yenta::Crypto;
use AC::Yenta::Debug 'crypto';
use AC::Misc;
use Time::HiRes 'time';
use Crypt::Rijndael;
use Digest::SHA  qw(sha256 hmac_sha256_base64);
use strict;

require 'AC/protobuf/auth.pl';

my $ALGORITHM = 'x-acy-aes-1';

sub new {
    my $class  = shift;
    my $secret = shift;

    return bless {
        secret	=> $secret,
    }, $class;
}

sub encrypt {
    my $me  = shift;
    my $buf = shift;

    my $seqno  = int( time() * 1_000_000 );
    my $nonce  = random_text(48);
    my $key    = $me->_key($seqno, $nonce);
    my $iv     = $me->_iv($key, $seqno, $nonce);

    # pad
    my $pbuf = $buf;
    $pbuf .= "\0" x (16 - length($pbuf) & 0xF) if length($pbuf) & 0xF;

    my $aes    = Crypt::Rijndael->new( $key, Crypt::Rijndael::MODE_CBC );
    $aes->set_iv( $iv );
    my $ct     = $aes->encrypt( $pbuf );
    my $hmac   = hmac_sha256_base64($ct, $key);

    my $eb     = ACPEncrypt->encode( {
        algorithm	=> $ALGORITHM,
        seqno		=> $seqno,
        nonce		=> $nonce,
        hmac		=> $hmac,
        length		=> length($buf),
        ciphertext	=> $ct,
    } );

    debug("encrypted <$seqno,$nonce,$hmac>");

    return $eb;
}

sub decrypt {
    my $me  = shift;
    my $buf = shift;

    my $ed     = ACPEncrypt->decode( $buf );
    die "cannot decrypt: unknown alg\n" unless $ed->{algorithm} eq $ALGORITHM;

    my $seqno  = $ed->{seqno},
    my $nonce  = $ed->{nonce};
    my $key    = $me->_key($seqno, $nonce);
    my $iv     = $me->_iv($key, $seqno, $nonce);

    my $hmac   = hmac_sha256_base64($ed->{ciphertext}, $key);
    die "cannot decrypt: hmac mismatch\n" unless $hmac eq $ed->{hmac};

    my $aes    = Crypt::Rijndael->new( $key, Crypt::Rijndael::MODE_CBC );
    $aes->set_iv( $iv );
    my $pt     = substr($aes->decrypt( $ed->{ciphertext} ), 0, $ed->{length});

    debug("decrypted <$seqno,$nonce,$hmac>");

    return $pt;
}


sub _key {
    my $me    = shift;
    my $seqno = shift;
    my $nonce = shift;

    return sha256( 'key1' . $me->{secret} . $seqno . $nonce . '1yek' );
}

sub _iv {
    my $me    = shift;
    my $key   = shift;
    my $seqno = shift;
    my $nonce = shift;

    return substr(sha256( 'iv'   . $key . $seqno ), 0, 16);
}


1;

