#ABSTRACT: SIGMA protocol
package Crypt::Protocol::SIGMA;

use strict;
use warnings;
#use bignum;

require Exporter;

use Carp;
use Crypt::KeyDerivation ':all';

use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
#use Crypt::OpenSSL::ECDSA;

#use Smart::Comments;

our $VERSION=0.013;

our @ISA    = qw(Exporter);
our @EXPORT = qw/
  derive_z_ke_km
  derive_ks
  verify_msg_mac_sig
  gen_msg_mac_sig_enc

  a_send_msg1
  b_recv_msg1
  b_send_msg2
  a_recv_msg2
  a_verify_msg2
  a_send_msg3
  b_recv_msg3
  b_send_msg4
  a_recv_msg4
  /;

our @EXPORT_OK = @EXPORT;

sub derive_z_ke_km {
  my ( $self_priv, $peer_pub, $hash_name, $key_len ) = @_;

  my $z = ecdh( $self_priv, $peer_pub );
  my $z_hex = unpack("H*", $z);
  ### $z_hex

  my $zero_salt = pack( "H64", '0' );
  ### zero_salt: unpack("H*", $zero_salt)

  #my $ke = Crypt::KeyDerivation::hkdf( $z, $zero_salt, $hash_name, $key_len, "sigma encrypt key" );
  my $ke = hkdf( $hash_name, $z, $zero_salt, "sigma encrypt key", $key_len );
  ### ke: unpack("H*", $ke)

  #my $km = Crypt::KeyDerivation::hkdf( $z, $zero_salt, $hash_name, $key_len, "sigma mac key" );
  my $km = hkdf( $hash_name, $z, $zero_salt, "sigma mac key", $key_len );
  ### km: unpack("H*", $km)

  return { z => $z, ke => $ke, km => $km };
}

sub derive_ks {
  my ( $z, $na, $nb, $hash_name, $key_len ) = @_;

  #my $ks = Crypt::KeyDerivation::hkdf( $z, $na . $nb, $hash_name, $key_len, "sigma session key" );
  my $ks = hkdf( $hash_name, $z, $na . $nb, "sigma session key", $key_len );
}

sub a_send_msg1 {

  # msg1: g^x, na, other_data_a
  my ( $group_name, $random_range, $point_compress_t, $pack_msg_func, $ctx, $other_data_a ) = @_;

  my $na = Crypt::OpenSSL::Bignum->rand_range( $random_range );

  #my $nid = Crypt::OpenSSL::EC::EC_GROUP::get_curve_name($group);
  #my $group_name = OBJ_nid2sn($nid);
  my $ek_key_a_r = generate_ec_key( $group_name, undef );

  my $msg1 = $pack_msg_func->( [ $ek_key_a_r->{pub_bin}, $na->to_bin, $other_data_a ] );

  return { na => $na, x_r => $ek_key_a_r, other_data_a => $other_data_a, msg1 => $msg1 };
}

sub b_recv_msg1 {

  # msg1: g^x, na, other_data_a
  my ( $group_name, $msg1, $unpack_msg_func, $ctx ) = @_;

  my $msg1_r = $unpack_msg_func->( $msg1 );
  my ( $b_recv_ek_a_pub, $b_recv_na, $b_recv_other_data_a ) = @$msg1_r;
  ### b_recv_ek_a_pub: unpack("H*", $b_recv_ek_a_pub)
  ### b_recv_na: unpack("H*", $b_recv_na)
  ### b_recv_other_data_a: unpack("H*", $b_recv_other_data_a)

  #my $nid = Crypt::OpenSSL::EC::EC_GROUP::get_curve_name($group);
  #my $group_name = OBJ_nid2sn($nid);
  my $b_recv_ek_a_pub_pkey = gen_ec_pubkey( $group_name, unpack( "H*", $b_recv_ek_a_pub ));

  return { na => $b_recv_na, gx => $b_recv_ek_a_pub, gx_pkey => $b_recv_ek_a_pub_pkey, other_data_a => $b_recv_other_data_a, };
}

sub b_send_msg2 {

  # msg2: g^y, nb, ENC{ B, other_data_b, SigB(MAC(1, na, B, g^y, other_data_a, other_data_b)) }
  my (
    $group_name, $b_recv_msg1_r, $id_b, $s_priv_b, $random_range, $point_compress_t, $hash_name, $key_len, 
    $pack_msg_func, $mac_func, $sign_func, $enc_func, 
    $ctx,
    $other_data_b, 
  ) = @_;

  #parse recv msg1
  #my $b_recv_msg1_r = b_recv_msg1( $group, $msg1, $unpack_msg_func, $ctx );
  my ( $b_recv_na, $b_recv_ek_a_pub, $b_recv_ek_a_pub_pkey, $b_recv_other_data_a ) =
    @{$b_recv_msg1_r}{qw/na gx gx_pkey other_data_a/};
  ### b_recv_na: unpack("H*", $b_recv_na)
  ### b_recv_ek_a_pub: unpack("H*", $b_recv_ek_a_pub)
  ### b_recv_other_data_a: unpack("H*", $b_recv_other_data_a)

  #nb, ek
  my $nb         = Crypt::OpenSSL::Bignum->rand_range( $random_range );

  #my $nid = Crypt::OpenSSL::EC::EC_GROUP::get_curve_name($group);
  #my $group_name = OBJ_nid2sn($nid);

  my $ek_key_b_r = generate_ec_key( $group_name, undef );

  my $kr = derive_z_ke_km( $ek_key_b_r->{priv_pkey}, $b_recv_ek_a_pub_pkey, $hash_name, $key_len );

  # $b_tbm = [1, na, B, g^y]
  my $data_to_enc_r = [ $id_b, $other_data_b ];
  my $data_to_mac_r = [ 1, $b_recv_na, $id_b, $ek_key_b_r->{pub_bin}, $b_recv_other_data_a, $other_data_b ];
  my $b_cipher_info = gen_msg_mac_sig_enc($data_to_enc_r, $data_to_mac_r, $kr->{km}, $s_priv_b, $kr->{ke}, $pack_msg_func, $mac_func, $sign_func, $enc_func);
  ### b_cipher_info: unpack("H*", $b_cipher_info)

  my $msg2 = $pack_msg_func->( [ $ek_key_b_r->{pub_bin}, $nb->to_bin, $b_cipher_info ] );

  return { nb => $nb, y_r => $ek_key_b_r, other_data_b => $other_data_b, derive_key => $kr, msg2 => $msg2 };
} ## end sub b_send_msg2

sub a_recv_msg2 {

  # msg2: g^y, nb, ENC{ B, other_data_b, SigB(MAC(1, na, B, g^y, other_data_a, other_data_b)) }
  my ( $group_name, $msg1_r, $msg2, $hash_name, $key_len, $unpack_msg_func, $dec_func, $ctx ) = @_;

  my $ek_key_a_r = $msg1_r->{x_r};

  my $msg2_r = $unpack_msg_func->( $msg2 );
  my ( $a_recv_ek_b_pub, $a_recv_nb, $a_recv_cipher_info ) = @$msg2_r;
  ### a_recv_ek_b_pub: unpack("H*", $a_recv_ek_b_pub)
  ### a_recv_nb: unpack("H*", $a_recv_nb)
  ### a_recv_cipher_info: unpack("H*", $a_recv_cipher_info)
  #my $nid = Crypt::OpenSSL::EC::EC_GROUP::get_curve_name($group);
  #my $group_name = OBJ_nid2sn($nid);
  my $a_recv_ek_b_pub_pkey = gen_ec_pubkey( $group_name, unpack( "H*", $a_recv_ek_b_pub ));

  my $key_r = derive_z_ke_km( $ek_key_a_r->{priv_pkey}, $a_recv_ek_b_pub_pkey, $hash_name, $key_len );

  my $cipher_info = $unpack_msg_func->( $a_recv_cipher_info );
  my $b_plaintext = $dec_func->( $key_r->{ke}, @$cipher_info );
  ### b_plaintext: unpack("H*", $b_plaintext)

  my $b_plaintext_r = $unpack_msg_func->( $b_plaintext );
  my ( $a_recv_id_b, $a_recv_other_data_b, $a_recv_sig_b ) = @$b_plaintext_r;
  ### $a_recv_id_b
  ### a_recv_other_data_b: unpack("H*", $a_recv_other_data_b)

  return {
    nb           => $a_recv_nb,
    gy           => $a_recv_ek_b_pub,
    gy_pkey      => $a_recv_ek_b_pub_pkey,
    derive_key   => $key_r,
    id_b         => $a_recv_id_b,
    other_data_b => $a_recv_other_data_b,
    sig          => $a_recv_sig_b,
  };
} ## end sub a_recv_msg2


sub a_verify_msg2 {
  my ( $msg1_r, $a_recv_msg2_r, $sig_pub, $pack_msg_func, $mac_func, $verify_func ) = @_;

  my $kr = $a_recv_msg2_r->{derive_key};

  my $data_to_mac_r = [ 1, $msg1_r->{na}->to_bin, $a_recv_msg2_r->{id_b}, $a_recv_msg2_r->{gy}, $msg1_r->{other_data_a}, $a_recv_msg2_r->{other_data_b} ] ;

  my $verify_res = verify_msg_mac_sig($data_to_mac_r, $a_recv_msg2_r->{sig}, $kr->{km}, $sig_pub, $pack_msg_func, $mac_func, $verify_func);
  ### $verify_res

  croak "a verify msg2 fail" unless ( $verify_res );

  return $a_recv_msg2_r;
} ## end sub a_verify_msg2

sub verify_msg_mac_sig {

    my ($data_to_mac_r, $sig_r, $km, $sig_pub, $pack_msg_func, $mac_func, $verify_func) = @_;

    my $rebuild_tbm = $pack_msg_func->( $data_to_mac_r );
    ### rebuild_tbm: unpack("H*", $rebuild_tbm)

    my $rebuild_tbs = $mac_func->( $rebuild_tbm, $km );
    ### rebuild_tbs: unpack("H*", $rebuild_tbs)

    my $verify_res = $verify_func->( $rebuild_tbs, $sig_r, $sig_pub  );
    ### $verify_res

    return $verify_res;
}

sub gen_msg_mac_sig_enc {
    my ($data_to_enc_r, $data_to_mac_r, $km, $sign_priv, $ke, $pack_msg_func, $mac_func, $sign_func, $enc_func) = @_;

    my $tbm = $pack_msg_func->( $data_to_mac_r );
    ### tbm: unpack("H*", $tbm)

    my $tbs = $mac_func->( $tbm, $km );
    ### tbs: unpack("H*", $tbs)

    my $sig = $sign_func->( $sign_priv, $tbs );
    ### sig: unpack("H*", $sig)

    my $tbe = $pack_msg_func->( [ @$data_to_enc_r, $sig ] );
    ### tbe: unpack("H*", $tbe)

    my $cipher_info_r = $enc_func->( $ke, $tbe );
    my $cipher_info = $pack_msg_func->($cipher_info_r);
    ### cipher_info: unpack("H*", $cipher_info)
    return $cipher_info;
}

sub a_send_msg3 {
    # ENC{ A, SigA(MAC(0, nb, A, g^x, other_data_b, other_data_a))
    my ( $id_a, $s_priv_a, $msg1_r, $a_recv_msg2_r, $pack_msg_func, $mac_func, $sign_func, $enc_func ) = @_;


    my $data_to_enc_r = [ $id_a ];

    my $data_to_mac_r = [ 0, $a_recv_msg2_r->{nb}, $id_a, $msg1_r->{x_r}{pub_bin}, $a_recv_msg2_r->{other_data_b}, $msg1_r->{other_data_a} ];
    ### a recv nb: unpack("H*", $a_recv_msg2_r->{nb})
    ### $id_a
    ### gx: unpack("H*", $msg1_r->{x_r}{pub_bin})

    my $kr = $a_recv_msg2_r->{derive_key};

    my $a_cipher_info = gen_msg_mac_sig_enc($data_to_enc_r, $data_to_mac_r, $kr->{km}, $s_priv_a, $kr->{ke}, $pack_msg_func, $mac_func, $sign_func, $enc_func);
    ### a_cipher_info: unpack("H*", $a_cipher_info)

    return $a_cipher_info;
} ## end sub a_send_msg3

sub b_recv_msg3 {

  # msg3 a -> b: ENC{ A, SigA(MAC(0, nb, A, g^x, other_data_b, other_data_a))
  # msg4 b -> a: MAC(2, na, "ack")
  my ( $b_recv_msg1_r, $b_send_msg2_r, $msg3, $s_pub_a, $pack_msg_func, $unpack_msg_func, $mac_func, $verify_func, $dec_func ) = @_;

  my $cipher_info = $unpack_msg_func->( $msg3 );

  my $kr     = $b_send_msg2_r->{derive_key};
  my $plaintext = $dec_func->( $kr->{ke}, @$cipher_info );

  my $plaintext_r = $unpack_msg_func->( $plaintext );
  my ( $b_recv_id_a, $b_recv_sig_a ) = @$plaintext_r;
  ### $b_recv_id_a

  my $nb            = $b_send_msg2_r->{nb};
  my $data_to_mac_r = [ 0, $nb->to_bin, $b_recv_id_a, $b_recv_msg1_r->{gx}, $b_send_msg2_r->{other_data_b}, $b_recv_msg1_r->{other_data_a} ];
  ### nb: $nb->to_hex
  ### $b_recv_id_a
  ### b recv gx: unpack("H*", $b_recv_msg1_r->{gx})

  my $verify_res = verify_msg_mac_sig($data_to_mac_r, $b_recv_sig_a, $kr->{km}, $s_pub_a, $pack_msg_func, $mac_func, $verify_func);
  ### $verify_res

  croak "b verify msg3 fail" unless ( $verify_res );

  return $verify_res;
} ## end sub b_recv_msg3

sub b_send_msg4 {
  my ( $b_recv_msg1_r, $b_send_msg2_r, $pack_msg_func, $mac_func ) = @_;

  my $b_tbm4 = $pack_msg_func->( [ 2, $b_recv_msg1_r->{na}, "ack" ] );
  ### b_tbm4: unpack("H*", $b_tbm4)

  my $b_mac4 = $mac_func->( $b_tbm4, $b_send_msg2_r->{derive_key}{km}, );
  ### b_mac4: unpack("H*", $b_mac4)

  return $b_mac4;
}

sub a_recv_msg4 {
  my ( $msg4, $na, $a_recv_msg2_r, $pack_msg_func, $mac_func ) = @_;

  my $a_rebuild_tbm4 = $pack_msg_func->( [ 2, $na->to_bin, "ack" ] );
  ### a_rebuild_tbm4: unpack("H*", $a_rebuild_tbm4)
  my $a_rebuild_mac4 = $mac_func->( $a_rebuild_tbm4, $a_recv_msg2_r->{derive_key}{km}, );

  my $res = $msg4 eq $a_rebuild_mac4;
  ### msg4 : unpack("H*", $msg4)
  ### a_rebuild_mac4 : unpack("H*", $a_rebuild_mac4)
  ### res : $res
  return $res;
}

1;
