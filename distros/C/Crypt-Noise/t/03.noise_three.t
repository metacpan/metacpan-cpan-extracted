#!/usr/bin/perl
use strict;
use warnings;

#use lib '../lib';

use Test::More;

#use Smart::Comments;

use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
#use Crypt::OpenSSL::Hash2Curve;
use Crypt::OpenSSL::Base::Func;
use Crypt::Noise;

use CBOR::XS;
use Digest::SHA qw/hmac_sha256 sha256/;
#use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);
use FindBin;
use POSIX qw/strftime/;

our $noise_conf = {
  group_name => 'prime256v1',
  #group_name             => 'secp256r1',

  hash_name => 'SHA256',
  hash_func => \&sha256,
  hash_len  => 32,

  cipher_name => 'AESGCM',
  enc_func    => sub {                 #encrypt: key, iv, aad, plaintext  -> ciphertext, authtag
    ### enc: scalar(@_)
    ### key, iv, aad, plain, ciphertext, tag
    my ($key, $iv, $aad, $plain) = @_;
    #print unpack("H*", $_), "\n" for @_;
    my $tag_len = 16;
    my $res = aead_encrypt('aes-256-gcm', $plain, $aad, $key, $iv, $tag_len);
    my $ciphertext = $res->[0];
    my $tag = $res->[1];
    #print unpack("H*", $_), "\n" for ($ciphertext, $tag);
    return ($ciphertext, $tag);
  },
  dec_func => sub {                    #decrypt: key, iv, aad, ciphertext, authtag -> plaintext
    ### dec: scalar(@_)
    ### key, iv, aad, ciphertext, tag, plain
    my ($key, $iv, $aad, $ciphertext, $tag) = @_;
    my $plain = aead_decrypt('aes-256-gcm', $ciphertext, $aad, $tag, $key, $iv);
    #print unpack("H*", $_), "\n" for ($plain);
    return $plain;
    #return gcm_decrypt_verify( 'AES', @d );
  },

  check_rs_pub_func => \&check_pub_s,

  key_len     => 32,
  iv_len      => 12,
  authtag_len => 16,

  msg_pack_func   => \&encode_cbor,
  msg_unpack_func => \&decode_cbor,
};
$noise_conf->{ec_params} = get_ec_params( $noise_conf->{group_name} );
init_ciphersuite_name( $noise_conf );


my @test_psk = ( [ undef, undef ], [ 'test_psk', 0 ], [ 'test_psk', 1 ], ['test_psk', 2], ['test_psk', 3] );

for my $pattern_name ( qw/XX XN XK XX1/ ) {

    #my $pattern_cnf = noise_pattern($pattern);
    for my $psk_r ( @test_psk ) {

        my ( $psk, $psk_id ) = @$psk_r;

        ### -----------start a_hs --------: $pattern_name, $psk, $psk_id
        my $a_hs = new_handshake_state(
            $noise_conf,
            { who          => 'a',
                pattern_name => $pattern_name,
                initiator    => 1,
                prologue     => 'some_info',

                psk    => $psk,
                psk_id => $psk_id,

                s_priv => pem_read_pkey( $FindBin::Bin . '/a_s_priv.pem', 1 ),
                s_pub  => pem_read_pkey( $FindBin::Bin . '/a_s_pub.pem',  0 ),
                rs_pub => pem_read_pkey( $FindBin::Bin . '/b_s_pub.pem',  0 ),

                s_pub_type  => 'raw',
                s_pub_bin   => pack( "H*", pem_read_pub_hex( $FindBin::Bin . '/a_s_pub.pem', 2 ) ),
                rs_pub_type => 'raw',
                rs_pub_bin  => pack( "H*", pem_read_pub_hex( $FindBin::Bin . '/a_rs_pub.pem', 2 ) ),
            },
        );

        ### -----------start bs --------: $pattern_name, $psk, $psk_id
        my $b_hs = new_handshake_state(
            $noise_conf,
            { who => 'b',

                pattern_name => $pattern_name,

                initiator => 0,
                prologue  => 'some_info',

                psk    => $psk,
                psk_id => $psk_id,

                s_priv => pem_read_pkey( $FindBin::Bin . '/b_s_priv.pem', 1 ),
                s_pub  => pem_read_pkey( $FindBin::Bin . '/b_s_pub.pem',  0 ),
                rs_pub => pem_read_pkey( $FindBin::Bin . '/a_s_pub.pem',  0 ),

                s_pub_type  => 'raw',
                s_pub_bin   => pack( "H*", pem_read_pub_hex( $FindBin::Bin . '/b_s_pub.pem', 2 ) ),
                rs_pub_type => 'raw',
                rs_pub_bin  => pack( "H*", pem_read_pub_hex( $FindBin::Bin . '/b_rs_pub.pem', 2 ) ),
            } );

  ### a write message to b
  ### init a_hs
  ### $a_hs
  ### a send msg to b
  my $a_msg_src = "init.syn";
  my ( $a_msg ) = write_message( $noise_conf, $a_hs, [], $a_msg_src );
  ### $a_msg
  ###  $a_hs

  ### b read message from a
  ### init b_hs
  ### $b_hs
  ### b recv msg from a
  my ( $b_recv_a_msg_r ) = read_message( $noise_conf, $b_hs, [], $a_msg );
  ### $b_recv_a_msg_r->[0]
  ###         $b_hs

  ### b write_message to a
  ### b send msg to a
  my $b_msg_src = "resp.ack";
  my ( $b_msg ) = write_message( $noise_conf, $b_hs, [], $b_msg_src );
  ### b_msg: unpack("H*", $b_msg)
  ### $b_hs

  ### a read_message from b
  ### a recv msg from b
  my ( $a_recv_b_msg_r ) = read_message( $noise_conf, $a_hs, [], $b_msg );
  ### $a_recv_b_msg_r->[0]
  ### $a_hs

  # a write message to b
  ### a send msg to b
  my $a_msg2_src = "init.ack";
  ### $a_msg2_src
  my ( $a_msg2, $a_c1, $a_c2 ) = write_message( $noise_conf, $a_hs, [], $a_msg2_src );
  ### a_msg2: unpack( "H*", $a_msg2 )
  ### $a_hs
  ### $a_c1
  ### $a_c2

  # b read message from a
  ### b recv msg from a
  my ( $b_recv_a_msg2_r, $b_c1, $b_c2 ) = read_message( $noise_conf, $b_hs, [], $a_msg2 );
  ### b_recv_a_msg2: $b_recv_a_msg2_r->[0]
  ### $b_hs
  ### $b_c1
  ### $b_c2

  # a -> b : plain_a.txt  -> trans_cipherinfo_a
  ### a send comm msg to b
our $plain_a = 'fujian quanzhou 666';
  my ( $a_c1_key, $a_c1_iv ) = derive_session_key_iv( $noise_conf, $a_c1->{k}, '' );
  my $a_trans_cipherinfo_b = session_encrypt( $noise_conf, $a_c1_key, $a_c1_iv, $a_hs->{ss}{h}, $plain_a );
  ### b recv comm msg from a
  my ( $b_c1_key, $b_c1_iv ) = derive_session_key_iv( $noise_conf, $b_c1->{k}, '' );
  my $b_recv_plaintext_a = session_decrypt( $noise_conf, $b_c1_key, $b_c1_iv, $b_hs->{ss}{h}, $a_trans_cipherinfo_b );
  ### $b_recv_plaintext_a

  ### b to a , plain_b.txt to trans_cipherinfo_b
  ### b send comm msg to a
our $plain_b = 'anhui hefei 888';
  my ( $b_c2_key, $b_c2_iv ) = derive_session_key_iv( $noise_conf, $b_c2->{k}, '' );
  my $b_trans_cipherinfo_a = session_encrypt( $noise_conf, $b_c2_key, $b_c2_iv, $b_hs->{ss}{h}, $plain_b );
  ### a recv comm msg from b
  my ( $a_c2_key, $a_c2_iv ) = derive_session_key_iv( $noise_conf, $a_c2->{k}, '' );
  my $a_recv_plaintext_b = session_decrypt( $noise_conf, $a_c2_key, $a_c2_iv, $a_hs->{ss}{h}, $b_trans_cipherinfo_a );
  ### $a_recv_plaintext_b

  is( $plain_a, $b_recv_plaintext_a, 'plain_a' );
  is( $plain_b, $a_recv_plaintext_b, 'plain_b' );

        ### -----------end test --------: $pattern_name, $psk, $psk_id
    } ## end for my $psk_r ( @test_psk)
} ## end for my $pattern_name ( ...)

done_testing;

sub check_pub_s {
    my ( $type, $value ) = @_;
    ### check pub s: $type, unpack("H*", $value)

    if ( $type eq 'raw' ) {

        #check the value is in the TOFU (trust on first use) record or not
        return $value;                     #pub raw
    }

    if ( $type eq 'id' ) {

        #check the value is in the TOFU (trust on first use) record or not
        #map value to the pub raw
    }

    if ( $type eq 'sn' ) {

        #check the value is in the TOFU (trust on first use) record or not
        #map value to the cert, extract the pub raw from cert
    }

    if ( $type eq 'cert' ) {

        #check the value is in the TOFU (trust on first use) record or not
        #if not, check_cert_avail
        #extract the pub raw from cert
    }
} ## end sub check_pub_s


