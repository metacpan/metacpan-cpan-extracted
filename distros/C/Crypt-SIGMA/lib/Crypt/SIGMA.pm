#ABSTRACT: SIGMA protocol
package Crypt::SIGMA;

use strict;
use warnings;
use bignum;

require Exporter;

use Crypt::KeyDerivation ':all';

use Crypt::OpenSSL::Hash2Curve;
use Crypt::OpenSSL::Base::Func;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::ECDSA;

#use Smart::Comments;

our @ISA    = qw(Exporter);
our @EXPORT = qw/
  derive_z_ke_km
  derive_ks

  a_send_msg1
  b_recv_msg1
  b_send_msg2
  a_recv_msg2
  a_send_msg3
  b_recv_msg3
  b_send_msg4
  a_recv_msg4
  /;

our @EXPORT_OK = @EXPORT;

sub derive_z_ke_km {
  my ( $self_priv, $peer_pub, $hash_name, $key_len ) = @_;

  my $z = ecdh_pkey( $self_priv, $peer_pub );
  ### z: unpack("H*", $z)

  my $zero_salt = pack( "H64", '0' );
  ### zero_salt: unpack("H*", $zero_salt)

  my $ke = hkdf( $z, $zero_salt, $hash_name, $key_len, "sigma encrypt key" );
  ### ke: unpack("H*", $ke)

  my $km = hkdf( $z, $zero_salt, $hash_name, $key_len, "sigma mac key" );
  ### km: unpack("H*", $km)

  return { z => $z, ke => $ke, km => $km };
}

sub derive_ks {
  my ( $z, $na, $nb, $hash_name, $key_len ) = @_;

  my $ks = hkdf( $z, $na . $nb, $hash_name, $key_len, "sigma session key" );
}

sub a_send_msg1 {

  # msg1: g^x, na
  my ( $group, $random_range, $point_compress_t, $pack_msg_func, $ctx ) = @_;

  my $na = Crypt::OpenSSL::Bignum->rand_range( $random_range );

  my $ek_key_a_r = generate_ec_key( $group, undef, $point_compress_t, $ctx );

  my $msg1 = $pack_msg_func->( [ $ek_key_a_r->{pub_bin}, $na->to_bin ] );

  return { na => $na, x_r => $ek_key_a_r, msg1 => $msg1 };
}

sub b_recv_msg1 {

  # msg1: g^x, na
  my ( $group, $msg1, $unpack_msg_func, $ctx ) = @_;

  my $msg1_r = $unpack_msg_func->( $msg1 );
  my ( $b_recv_ek_a_pub, $b_recv_na ) = @$msg1_r;
  ### b_recv_ek_a_pub: unpack("H*", $b_recv_ek_a_pub)
  ### b_recv_na: unpack("H*", $b_recv_na)

  my $b_recv_ek_a_pub_pkey = evp_pkey_from_point_hex( $group, unpack( "H*", $b_recv_ek_a_pub ), $ctx );

  return { na => $b_recv_na, gx => $b_recv_ek_a_pub, gx_pkey => $b_recv_ek_a_pub_pkey };
}

sub b_send_msg2 {

  # msg2: g^y, nb, ENC{ B, SigB(MAC(1, na, B, g^y)) }
  my ( $group, $b_recv_msg1_r, $id_b, $random_range, $point_compress_t, $hash_name, $key_len, $pack_msg_func, $mac_func, $sign_func, $enc_func, $ctx ) = @_;

  #parse recv msg1
  #my $b_recv_msg1_r = b_recv_msg1( $group, $msg1, $unpack_msg_func, $ctx );
  my ( $b_recv_na, $b_recv_ek_a_pub, $b_recv_ek_a_pub_pkey ) = @{$b_recv_msg1_r}{qw/na gx gx_pkey/};
  ### b_recv_na: unpack("H*", $b_recv_na)
  ### b_recv_ek_a_pub: unpack("H*", $b_recv_ek_a_pub)

  #nb, ek
  my $nb         = Crypt::OpenSSL::Bignum->rand_range( $random_range );
  my $ek_key_b_r = generate_ec_key( $group, undef, $point_compress_t, $ctx );

  # $b_tbm = [1, na, B, g^y]
  my $b_tbm = $pack_msg_func->( [ 1, $b_recv_na, $id_b, $ek_key_b_r->{pub_bin} ] );

  my $key_r = derive_z_ke_km( $ek_key_b_r->{priv_pkey}, $b_recv_ek_a_pub_pkey, $hash_name, $key_len );

  # $b_tbs = MAC($b_tbm)
  my $b_tbs = $mac_func->( $key_r->{km}, $b_tbm );

  # @b_sig = sigB($b_tbs)
  my @b_sig = $sign_func->( $b_tbs );

  # $b_tbe = { B, SigB(MAC(1, na, B, g^y)) }
  my $b_tbe = $pack_msg_func->( [ $id_b, @b_sig ] );

  my $b_cipher_info = $enc_func->( $key_r->{ke}, $b_tbe, $pack_msg_func );
  ### b_cipher_info: unpack("H*", $b_cipher_info)

  my $msg2 = $pack_msg_func->( [ $ek_key_b_r->{pub_bin}, $nb->to_bin, $b_cipher_info ] );

  return { nb => $nb, y_r => $ek_key_b_r, derive_key => $key_r, msg1_r => $b_recv_msg1_r, msg2 => $msg2 };
} ## end sub b_send_msg2

sub a_recv_msg2 {

  # msg2: g^y, nb, ENC{ B, SigB(MAC(1, na, B, g^y)) }
  my ( $group, $msg2, $na, $ek_key_a_r, $hash_name, $key_len, $pack_msg_func, $unpack_msg_func, $mac_func, $sig_verify_func, $dec_func, $ctx) = @_;

  my $msg2_r = $unpack_msg_func->( $msg2 );
  my ( $a_recv_ek_b_pub, $a_recv_nb, $a_recv_cipher_info ) = @$msg2_r;
  ### a_recv_ek_b_pub: unpack("H*", $a_recv_ek_b_pub)
  ### a_recv_nb: unpack("H*", $a_recv_nb)
  ### a_recv_cipher_info: unpack("H*", $a_recv_cipher_info)
  my $a_recv_ek_b_pub_pkey = evp_pkey_from_point_hex( $group, unpack( "H*", $a_recv_ek_b_pub ), $ctx );

  my $key_r = derive_z_ke_km( $ek_key_a_r->{priv_pkey}, $a_recv_ek_b_pub_pkey, $hash_name, $key_len );

  my $cipher_info = $unpack_msg_func->( $a_recv_cipher_info );
  my $b_plaintext = $dec_func->( $key_r->{ke}, @$cipher_info );
  ### b_plaintext: unpack("H*", $b_plaintext)

  my $b_plaintext_r = $unpack_msg_func->( $b_plaintext );
  my ( $a_recv_id_b, @a_recv_sig_b ) = @$b_plaintext_r;
  ### $a_recv_id_b
  ### r : unpack("H*", $a_recv_sig_b[0])
  ### s : unpack("H*", $a_recv_sig_b[1])

  my $a_rebuild_tbm = $pack_msg_func->( [ 1, $na->to_bin, $a_recv_id_b, $a_recv_ek_b_pub ] );
  my $a_rebuild_tbs = $mac_func->( $key_r->{km}, $a_rebuild_tbm );
  ### a_rebuild_tbm: unpack("H*", $a_rebuild_tbm)
  ### a_rebuild_tbs: unpack("H*", $a_rebuild_tbs)

  my $verify_res = $sig_verify_func->( $a_rebuild_tbs, @a_recv_sig_b );
  return unless ( $verify_res );
  ### $verify_res

  return { derive_key => $key_r, nb => $a_recv_nb, gy => $a_recv_ek_b_pub, id => $a_recv_id_b };
} ## end sub a_recv_msg2

sub a_send_msg3 {

  # ENC{ A, SigA(MAC(0, nb, A, g^x))
  my ( $id_a, $a_recv_nb, $ek_key_a_r, $derive_key, $pack_msg_func, $mac_func, $sign_func, $enc_func ) = @_;

  my $a_tbm = $pack_msg_func->( [ 0, $a_recv_nb, $id_a, $ek_key_a_r->{pub_bin} ] );
  ### a_tbm: unpack("H*", $a_tbm)

  my $a_tbs = $mac_func->( $derive_key->{km}, $a_tbm );
  ### a_tbs: unpack("H*", $a_tbs)

  my @a_sig = $sign_func->( $a_tbs );

  my $a_tbe = $pack_msg_func->( [ $id_a, @a_sig ] );

  my $a_cipher_info = $enc_func->( $derive_key->{ke}, $a_tbe, $pack_msg_func );
  ### a_cipher_info: unpack("H*", $a_cipher_info)

  return $a_cipher_info;
} ## end sub a_send_msg3

sub b_recv_msg3 {

  # msg3 a -> b: ENC{ A, SigA(MAC(0, nb, A, g^x))
  # msg4 b -> a: MAC(2, na, "ack")
  my ( $msg3, $b_send_msg2_r, $pack_msg_func, $unpack_msg_func, $mac_func, $sig_verify_func, $dec_func ) = @_;

  my $cipher_info = $unpack_msg_func->( $msg3 );

  my $key_r     = $b_send_msg2_r->{derive_key};
  my $plaintext = $dec_func->( $key_r->{ke}, @$cipher_info );

  my $plaintext_r = $unpack_msg_func->( $plaintext );
  my ( $b_recv_id_a, @b_recv_sig_a ) = @$plaintext_r;
  ### $b_recv_id_a
  ### r : unpack("H*", $b_recv_sig_a[0])
  ### s : unpack("H*", $b_recv_sig_a[1])

  my $nb            = $b_send_msg2_r->{nb};
  my $b_recv_msg1_r = $b_send_msg2_r->{msg1_r};
  my $b_rebuild_tbm = $pack_msg_func->( [ 0, $nb->to_bin, $b_recv_id_a, $b_recv_msg1_r->{gx} ] );
  my $b_rebuild_tbs = $mac_func->( $key_r->{km}, $b_rebuild_tbm );
  ### b_rebuild_tbm: unpack("H*", $b_rebuild_tbm)
  ### b_rebuild_tbs: unpack("H*", $b_rebuild_tbs)

  my $verify_res = $sig_verify_func->( $b_rebuild_tbs, @b_recv_sig_a );
  ### $verify_res
  
  return $verify_res;
} ## end sub b_recv_msg3

sub b_send_msg4 {
    my ($b_recv_msg1_r, $b_send_msg2_r, $pack_msg_func, $mac_func) = @_;

    my $b_tbm4 = $pack_msg_func->( [ 2, $b_recv_msg1_r->{na}, "ack" ] );
    ### b_tbm4: unpack("H*", $b_tbm4)
    
    my $b_mac4 = $mac_func->( $b_send_msg2_r->{derive_key}{km}, $b_tbm4 );
    ### b_mac4: unpack("H*", $b_mac4)

    return $b_mac4;
}

sub a_recv_msg4 {
  my ( $msg4, $na, $a_recv_msg2_r, $pack_msg_func, $mac_func ) = @_;

  my $a_rebuild_tbm4 = $pack_msg_func->( [ 2, $na->to_bin, "ack" ] );
  ### a_rebuild_tbm4: unpack("H*", $a_rebuild_tbm4)
  my $a_rebuild_mac4 = $mac_func->( $a_recv_msg2_r->{derive_key}{km}, $a_rebuild_tbm4 );

  my $res = $msg4 eq $a_rebuild_mac4;
  ### msg4 : unpack("H*", $msg4)
  ### a_rebuild_mac4 : unpack("H*", $a_rebuild_mac4)
  ### res : $res
  return $res;
}

1;
