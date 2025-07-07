#!/usr/bin/perl
#https://www.ietf.org/proceedings/52/slides/ipsec-9.pdf
#sigma_i

use strict;
use warnings;

#use lib '../lib';

#use bignum;
#use Smart::Comments;

use Test::More;
use FindBin qw($Bin);

use CBOR::XS;

use Crypt::Protocol::SIGMA;

use Crypt::KeyDerivation ':all';
use Digest::SHA qw/hmac_sha256 sha256/;
use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);

use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::ECDSA;

use Crypt::Protocol::OPRF;
use Crypt::Protocol::OPAQUE;

#use Smart::Comments;
use CBOR::XS;

#use bignum;
use FindBin qw($Bin);

my $prefix = "VOPRF09-";
my $mode = 0x00;
my $suite_id  = 0x0003;
my $context_string = creat_context_string($prefix, $mode, $suite_id);
my $DST = "HashToGroup-".$context_string;

my $pwd = 'CorrectHorseBatteryStaple';
my $blind = Crypt::OpenSSL::Bignum->new_from_hex('411bf1a62d119afe30df682b91a0a33d777972d4f2daa4b34ca527d597078153');
my $group_name = 'prime256v1';
my $group_params = get_ec_params( $group_name );
my $group        = $group_params->{group};
my $ctx          = $group_params->{ctx};
my $type = 'sswu';
my $hash_name = 'SHA256';
my $expand_message_func = \&expand_message_xmd;

my $req_r = create_registration_request($pwd, $blind, $DST, $group_name, $type, $hash_name, $expand_message_func, 1);
### blind: $req_r->{blind}->to_hex
### request.data ( blindElement.hex ):  unpack("H*", $req_r->{request}{data})

is($req_r->{request}{data}, pack("H*", '02a0e1e2b7d6676136224e19c9fdd495d91f49bfe5e8a192e712f065a448e52d28'), 'create_registration_request');

my $s_priv_hex = 'c36139381df63bfc91c850db0b9cfbec7a62e86d80040a41aa7725bf0e79d5e5';
my $s_priv_pkey = gen_ec_key($group_name, $s_priv_hex);
write_key_to_pem("$Bin/opaque-b_s_priv.pem", $s_priv_pkey);

my $s_pub = pack("H*", '035f40ff9cf88aa1f5cd4fe5fd3da9ea65a4923a5594f84fd9f2092d6067784874');
my $oprf_seed = pack("H*", '62f60b286d20ce4fd1d64809b0021dad6ed5d52a2c8cf27ae6582543a0a8dce2');
my $Nseed = 32;
my $info = 'OPAQUE-DeriveKeyPair';
my $point_compress_t = 2;
my $Nm = 32;

my $credential_identifier = '1234';
my $pack_func = sub {
    my ($r) = @_;
    join("", @$r);
};

my $res_r = create_registration_response($req_r->{request}, $s_pub, $oprf_seed, $credential_identifier,"OprfKey", $Nseed, $group_name, $info, "DeriveKeyPair".$context_string, $hash_name, $expand_message_func, $point_compress_t);
is($res_r->{response}{data}, pack("H*", '02665318BFCC8A2D0CA5DCB6E51C5A860A409D4187C32109AFECFF3538C79B5FB3'), 'create_registration_response');

my $c_id='alice';
my $s_id='bob';
my $pwd_harden_func = sub {
    my ($oprf_output) = @_;
    return $oprf_output;
};

#my $Nn = 32;
my $Nn  = Crypt::OpenSSL::Bignum->new_from_hex('a921f2a014513bd8a90e477a629794e89fec12d12206dde662ebdcf65670e51f');
my $finalize_info = 'OPAQUE-DeriveAuthKeyPair';
my $finalize_DST = "DeriveKeyPair".$context_string;
my $mac_func = \&hmac_sha256;
my $finalize_r = finalize_registration_request($req_r, $res_r->{response}, $pwd, $c_id, $s_id, $Nn, $Nseed, $group_name, $finalize_info, $finalize_DST, $hash_name, $expand_message_func, $mac_func, $pwd_harden_func);
my $upload_record = $finalize_r->{record};
### export_key: unpack("H*", $finalize_r->{export_key})
is($finalize_r->{record}{masking_key}, pack("H*", '26605b3dae07af6f79501f0bfad82c904b61a59fa7038d87b66b4fdac4707541'), 'finalize_registration_request');

my $b_recv_a_s_pub_pkey = gen_ec_pubkey($group_name, unpack("H*", $upload_record->{c_pub}));
write_pubkey_to_pem("$Bin/opaque-b_recv_a_s_pub.pem", $b_recv_a_s_pub_pkey );





my $random_range     = Crypt::OpenSSL::Bignum->new_from_hex( join( "", ( 'f' ) x 32 ) );
my $iv_range         = Crypt::OpenSSL::Bignum->new_from_hex( join( "", ( 'f' ) x 24 ) );
#my $group_name       = 'prime256v1';
my $key_len          = 32;
#my $hash_name        = 'SHA256';
my $cipher_name      = 'AES';
#my $point_compress_t = 2;

my $enc_func = sub {
  my ( $ke, $plaintext ) = @_;
  my $iv = Crypt::OpenSSL::Bignum->rand_range( $iv_range );
  my ( $ciphertext, $tag ) = gcm_encrypt_authenticate( $cipher_name, $ke, $iv->to_bin, undef, $plaintext );
my $cipher_info_r = [ $iv->to_bin, $ciphertext, $tag ];
  ### iv: $iv->to_hex
  ### ciphertext: unpack("H*", $ciphertext)
  ### tag: unpack("H*", $tag)
  return $cipher_info_r;
};

my $dec_func = sub {
  my ( $ke, $iv, $ciphertext, $tag ) = @_;
  my $plaintext = gcm_decrypt_verify( 'AES', $ke, $iv, undef, $ciphertext, $tag );
  ### iv: unpack("H*", $iv)
  ### ciphertext: unpack("H*", $ciphertext)
  ### tag: unpack("H*", $tag)
  ### plaintext: unpack("H*", $plaintext)
  return $plaintext;
};

#my $mac_func = \&hmac_sha256;

my $sig_verify_func = sub {
  my ( $tbs, $sig_r, $pkey_fname ) = @_;

  my $a_know_b_s_pub_pkey = read_pubkey_from_pem( $pkey_fname );
  #my $a_know_b_s_pub      = EVP_PKEY_get1_EC_KEY( $a_know_b_s_pub_pkey );

  #my $a_recv_sig = Crypt::OpenSSL::ECDSA::ECDSA_SIG->new();
  #$a_recv_sig->set_r( $sig_r->[0] );
  #$a_recv_sig->set_s( $sig_r->[1] );

  #my $dgst = digest("SHA256", $tbs);
  my $a_verify = ecdsa_verify($a_know_b_s_pub_pkey, "SHA256", $tbs, $sig_r);

  #my $a_verify = Crypt::OpenSSL::ECDSA::ECDSA_do_verify( $tbs, $a_recv_sig, $a_know_b_s_pub );
  ### verify sig : $a_verify
  return $a_verify;
};

my $sign_func = sub {
  my ( $pkey_fname, $b_tbs ) = @_;
  my $b_s_priv_pkey = read_key_from_pem( $pkey_fname );
  #my $dgst = digest("SHA256", $b_tbs);
  my $sig = ecdsa_sign($b_s_priv_pkey, "SHA256", $b_tbs);
  #my $b_s_priv      = EVP_PKEY_get1_EC_KEY( $b_s_priv_pkey );
  #my $b_sig         = Crypt::OpenSSL::ECDSA::ECDSA_do_sign( $b_tbs, $b_s_priv );
  #return ( $b_sig->get_r, $b_sig->get_s );
};


# a->b { g^x, na
my $id_a = 'alice';
$blind = Crypt::OpenSSL::Bignum->new_from_hex('c497fddf6056d241e6cf9fb7ac37c384f49b357a221eb0a802c989b9942256c1');
my $cred_req_r = create_credential_request($pwd, $blind, $DST, $group_name, $type, $hash_name, $expand_message_func, 1);
my $other_data_a = $cred_req_r->{request}{data};
### $id_a
### other_data_a: unpack("H*", $other_data_a)

### a_send_msg1
my $msg1_r = a_send_msg1( $group_name, $random_range, $point_compress_t, \&encode_cbor, $ctx, $other_data_a );
my ( $na, $ek_key_a_r, $msg1 ) = @{$msg1_r}{qw/na x_r msg1/};
### na: $na->to_hex

my ( $ek_a, $ek_a_priv, $ek_a_pub, $ek_a_pub_hex_compressed, $ek_a_pub_pkey, $ek_a_priv_pkey ) =
  @{$ek_key_a_r}{qw/priv_key priv_bn pub_point pub_hex pub_pkey priv_pkey/};
write_pubkey_to_pem( 'opaque-a_ek_pub.pem', $ek_a_pub_pkey  );
###  $ek_a_pub_hex_compressed

write_key_to_pem( 'opaque-a_ek_priv.pem', $ek_a_priv_pkey  );
###  ek_a_priv: $ek_a_priv->to_hex

### msg1: unpack("H*", $msg1)
# }

# b -> a {  g^y, nb, ENC{ B, SigB(MAC(1, na, B, g^y)) }
my $id_b          = 'bob';
### b_recv_msg1
my $b_recv_msg1_r = b_recv_msg1( $group_name, $msg1, \&decode_cbor, $ctx );
my $b_recv_other_data_a = $b_recv_msg1_r->{other_data_a};
my $b_recv_cred_req_r =    { data => $b_recv_other_data_a }; 
my $masking_nonce = Crypt::OpenSSL::Bignum->new_from_hex('38fe59af0df2c79f57b8780278f5ae47355fe1f817119041951c80f612fdfc6d');
my $cred_res_r = create_credential_response(
$b_recv_cred_req_r, $s_pub, $oprf_seed, $credential_identifier,"OprfKey", $upload_record->{envelope}, $upload_record->{masking_key}, 
$masking_nonce, $Nseed, $group_name, $info, "DeriveKeyPair".$context_string, $hash_name, $expand_message_func, $point_compress_t, $pack_func, 
);
is($cred_res_r->{masked_response}, pack("H*", 'adb901cb9a50203d9df723560fafa4ce22b66b58a31c8ff070a0bc801ab2161544475404c323712d8916620d4a184cd1603ea31cee0e341d7e3a5da01ab1eef8d6d132ee54cad7a68a72ef06ca0bdde88ac930e13aa906fd284aa79ca51e694f07'), 'create_credential_response');

my $other_data_b = encode_cbor([ @{$cred_res_r}{qw/Z masking_nonce masked_response/} ]);
### b_send_msg2
my $b_send_msg2_r = b_send_msg2(
  $group_name, $b_recv_msg1_r, $id_b, "$Bin/opaque-b_s_priv.pem",$random_range, $point_compress_t, $hash_name, $key_len, \&encode_cbor,
  $mac_func,
    $sign_func,
  $enc_func,
  $ctx,
  $other_data_b, 
);

my ( $nb, $ek_key_b_r, $derive_key_b_r, $msg2 ) = @{$b_send_msg2_r}{qw/nb y_r derive_key msg2/};
my ( $b_z,       $b_ke,            $b_km )                 = @{$derive_key_b_r}{qw/z ke km/};
my ( $b_recv_na, $b_recv_ek_a_pub, $b_recv_ek_a_pub_pkey ) = @{$b_recv_msg1_r}{qw/na  gx gx_pkey/};
my ( $ek_b,      $ek_b_priv,       $ek_b_pub, $ek_b_pub_hex_compressed, $ek_b_pub_pkey, $ek_b_priv_pkey ) =
  @{$ek_key_b_r}{qw/priv_key priv_bn pub_point pub_hex pub_pkey priv_pkey/};

### $id_b
### $other_data_b
### nb: $nb->to_hex

write_pubkey_to_pem( 'opaque-b_ek_pub.pem', $ek_b_pub_pkey  );
###  $ek_b_pub_hex_compressed

write_key_to_pem( 'opaque-b_ek_priv.pem', $ek_b_priv_pkey );
###  ek_b_priv: $ek_b_priv->to_hex

### msg2: unpack("H*", $msg2)
# }

# a -> b { ENC{ A, SigA(MAC(0, nb, A, g^x)) }
my $a_recv_msg2_r = a_recv_msg2(
  $group_name,       $msg1_r,  $msg2, 
  $hash_name,    $key_len,
   \&decode_cbor,
  $dec_func,
  $ctx,
);

my $a_recv_other_data_b = $a_recv_msg2_r->{other_data_b};
my $cred_res_arr = decode_cbor $a_recv_other_data_b;
my $a_recv_cred_res_r = { Z => $cred_res_arr->[0], masking_nonce => $cred_res_arr->[1], masked_response => $cred_res_arr->[2] };

my $unpack_func = sub {
    my ($r) = @_;
    my $s_pub = substr $r, 0, 33;
    my $nonce = substr $r, 33, 32;
    my $auth_tag = substr $r, 65, 32;
    ### r: unpack("H*", $r)
    ### s_pub: unpack("H*", $s_pub)
    ### nonce: unpack("H*", $nonce)
    ### auth_tag: unpack("H*", $auth_tag)
    return [ $s_pub, $nonce, $auth_tag ];
};
my $recover_r = recover_credentials($cred_req_r, $a_recv_cred_res_r, $pwd, $id_a, $a_recv_msg2_r->{id_b}, $Nseed, $group_name, $finalize_info, $finalize_DST, $hash_name, $expand_message_func, $mac_func, $pwd_harden_func, $unpack_func);

is($recover_r->{export_key}, pack("H*", '77869b0d11debf6fc88c1d192dde9546baf528b2f70c2aea89960fc2178586da'), 'recover_credentials');

is($recover_r->{c_priv}->to_hex, 'D1D280F712E4EBF3C881C686E13C281BC3A3FAB30A00411A350F4F8B7A1EA550', 'recover_credentials');

my $a_recover_a_s_priv_pkey = gen_ec_key($group_name, $recover_r->{c_priv}->to_hex);
write_key_to_pem("$Bin/opaque-a_recover_c_s_priv.pem", $a_recover_a_s_priv_pkey );

my $a_recover_b_s_pub_pkey = gen_ec_pubkey($group_name, unpack("H*", $recover_r->{s_pub}));
write_pubkey_to_pem("$Bin/opaque-a_recover_b_s_pub.pem", $a_recover_b_s_pub_pkey );
my $a_verify_msg2 = a_verify_msg2(
    $msg1_r, $a_recv_msg2_r, "$Bin/opaque-a_recover_b_s_pub.pem",
  \&encode_cbor, 
  $mac_func,
  $sig_verify_func, 
);

my $a_recv_ek_b_pub_pkey = gen_ec_pubkey( $group_name, unpack( "H*", $a_recv_msg2_r->{gy} ));
write_pubkey_to_pem( 'opaque-a_recv_b_ek_pub.pem', $a_recv_ek_b_pub_pkey  );

my $a_send_msg3 = a_send_msg3(
  $id_a,
"$Bin/opaque-a_recover_c_s_priv.pem", 
  $msg1_r, 
  $a_recv_msg2_r, 
  \&encode_cbor,
  $mac_func,
    $sign_func, 
  $enc_func,

);

### a_send_msg3: unpack("H*", $a_send_msg3)
# }

# b recv a {  MAC(2, na, "ack")
my $msg3_verify_res = b_recv_msg3(
  $b_recv_msg1_r, 
  $b_send_msg2_r,
  $a_send_msg3,
"$Bin/opaque-b_recv_a_s_pub.pem", 
  \&encode_cbor, \&decode_cbor,
  $mac_func,
    $sig_verify_func, 
  $dec_func,
);
### $msg3_verify_res

my $mac4 = b_send_msg4( $b_recv_msg1_r, $b_send_msg2_r, \&encode_cbor, $mac_func );
### mac4: unpack("H*", $mac4)
# }

# a recv b {
my $res_msg4 = a_recv_msg4( $mac4, $na, $a_recv_msg2_r, \&encode_cbor, $mac_func );
###  $res_msg4
# }

# ks {
my $b_ks = derive_ks( $b_z, $b_recv_na, $nb->to_bin, $hash_name, $key_len );
### b_ks: unpack("H*", $b_ks)
my $a_ks = derive_ks( $a_recv_msg2_r->{derive_key}{z}, $na->to_bin, $a_recv_msg2_r->{nb}, $hash_name, $key_len );
### a_ks: unpack("H*", $a_ks)
# }

is( $a_ks, $b_ks, 'sigma session key' );

done_testing;

