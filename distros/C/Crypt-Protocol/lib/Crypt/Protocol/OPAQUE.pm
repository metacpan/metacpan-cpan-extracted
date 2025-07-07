#ABSTRACT: OPAQUE protocol
package Crypt::Protocol::OPAQUE;

use strict;
use warnings;
#use bignum;

require Exporter;

use Crypt::KeyDerivation ':all';

use Carp;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
#use Crypt::OpenSSL::ECDSA;
use Crypt::Protocol::OPRF;

#use Smart::Comments;

our $VERSION = 0.012;

our @ISA    = qw(Exporter);
our @EXPORT = qw/
  create_cleartext_credentials
  store
  recover
  create_registration_request
  create_registration_response
  finalize_registration_request
  derive_random_pwd
  create_credential_request
  create_credential_response
  recover_credentials
  /;

our @EXPORT_OK = @EXPORT;

sub recover_credentials {

  my (
    $cred_request, $cred_response,   $pwd, $c_id, $s_id, $Nseed, $group_name, $info, $DST, $hash_name, $expand_message_func,
    $mac_func,     $pwd_harden_func, $unpack_func
  ) = @_;

  my $evaluate_element = hex2point( $group_name, unpack( "H*", $cred_response->{Z} ) );
  my $randomized_pwd =
    derive_random_pwd( $cred_request->{ec_params}, $pwd, $cred_request->{blind}, $evaluate_element, $hash_name, $pwd_harden_func );
  ### randomized_pwd: unpack("H*", $randomized_pwd)

  my $hash_func   = EVP_get_digestbyname( $hash_name );
  my $Nh          = EVP_MD_get_size( $hash_func );
  my $masking_key = hkdf_expand( $hash_name, $randomized_pwd, '',  "MaskingKey", $Nh );
  ### masking_key: unpack("H*", $masking_key)

  my $L = length( $cred_response->{masked_response} );
  ### $L
  my $masking_nonce           = $cred_response->{masking_nonce};
  my $credential_response_pad = hkdf_expand( $hash_name, $masking_key, '', $masking_nonce . "CredentialResponsePad",  $L  );

  my $plain_response = $credential_response_pad ^ $cred_response->{masked_response};
  my $unpack_r       = $unpack_func->( $plain_response );
  my ( $s_pub, $envelope_nonce, $envelope_auth_tag ) = @$unpack_r;
  my $envelope = { nonce => $envelope_nonce, auth_tag => $envelope_auth_tag };

  my $recover_r = recover(
    $randomized_pwd, $s_pub, $envelope, $s_id, $c_id, $Nseed, $group_name, $info, $DST, $hash_name, $expand_message_func,
    $mac_func
  );
  $recover_r->{s_pub} = $s_pub;
  ### recover s_pub: unpack("H*", $s_pub)
  ### recover c_priv:  $recover_r->{c_priv}->to_hex
  ### recover export_key: unpack("H*", $recover_r->{export_key})

  return $recover_r;
} ## end sub recover_credentials

sub create_credential_response {
  my (
    $request,   $s_pub, $oprf_seed, $credential_identifier, $DSI, $envelope, $masking_key, $Nn, $Nseed, $group_name, $info, $DST,
    $hash_name, $expand_message_func, $point_compress_t, $pack_func
  ) = @_;
  ### blindElement: unpack("H*", $request->{data})
  ### s_pub: unpack("H*", $s_pub)
  ### oprf_seed: unpack("H*", $oprf_seed)
  ### $credential_identifier
  ### $DSI
  ### nonce: unpack("H*", $envelope->{nonce})
  ### auth_tag: unpack("H*", $envelope->{auth_tag})
  ### masking_key: unpack("H*", $masking_key)

  ### $Nseed
  ### $info
  ### $DST
  my $res_r = create_registration_response(
    $request,   $s_pub, $oprf_seed, $credential_identifier, $DSI, $Nseed, $group_name, $info, $DST,
    $hash_name, $expand_message_func, $point_compress_t
  );

  my $masking_nonce_bn = ( ref( $Nn ) eq 'Crypt::OpenSSL::Bignum' ) ? $Nn : random_bn( $Nn );
  my $masking_nonce    = $masking_nonce_bn->to_bin;
  ### masking_nonce: unpack("H*", $masking_nonce)

  #my $Npk = length($s_pub);
  #my $Ne = length($masking_key) + length($masking_nonce);
  #my $L = $Npk + $Ne;

  my $pack_msg = $pack_func->( [ $s_pub, $envelope->{nonce}, $envelope->{auth_tag} ] );
  my $L        = length( $pack_msg );

  my $credential_response_pad = hkdf_expand( $hash_name, $masking_key, '', $masking_nonce . "CredentialResponsePad", $L );
  ### credential_response_pad: unpack("H*", $credential_response_pad)

  my $masked_response = $credential_response_pad ^ $pack_msg;
  ### masked_response: unpack("H*", $masked_response)

  ### Z: unpack("H*", $res_r->{response}{data})
  ### $L
  ### pack_msg: unpack("H*", $pack_msg)

  my $cred_res = {
    Z               => $res_r->{response}{data},  # evaluate_element_binary
    masking_nonce   => $masking_nonce,
    masked_response => $masked_response,
  };

  return $cred_res;
} ## end sub create_credential_response

sub create_credential_request {
  return create_registration_request( @_ );
}

sub finalize_registration_request {
  my (
    $request, $response, $pwd, $c_id, $s_id, $Nn, $Nseed, $group_name, $info, $DST, $hash_name, $expand_message_func, $mac_func,
    $pwd_harden_func
  ) = @_;

  ### finalize_registration_request

  #my ($pwd, $blind, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag) = @_;

  my $evaluate_element = hex2point( $group_name, unpack( "H*", $response->{data} ) );
  my $randomized_pwd =
    derive_random_pwd( $request->{ec_params}, $pwd, $request->{blind}, $evaluate_element, $hash_name, $pwd_harden_func );
  ### blind: $request->{blind}->to_hex
  ### evaluate_element: unpack("H*", $response->{data})
  ### randomized_pwd: unpack("H*", $randomized_pwd)

  ### s_pub: unpack("H*", $response->{s_pub})
  ### $c_id
  ### $s_id
  my $store_r = store(
    $randomized_pwd,      $response->{s_pub}, $s_id, $c_id, $Nn, $Nseed, $group_name, $info, $DST, $hash_name,
    $expand_message_func, $mac_func
  );
  ### cleartext_credentails: $store_r->{cleartext_credentails}

  my $record = { c_pub => $store_r->{c_pub}, masking_key => $store_r->{masking_key}, envelope => $store_r->{envelope} };
  $store_r->{record} = $record;
  ### record c_pub: unpack("H*", $record->{c_pub})
  ### record masking_key: unpack("H*", $record->{masking_key})
  ### record envelope auth_tag: unpack("H*", $record->{envelope}{auth_tag})
  ### record envelope nonce: unpack("H*", $record->{envelope}{nonce})

  return $store_r;
} ## end sub finalize_registration_request

sub derive_random_pwd {
  my ( $ec_params, $pwd, $blind, $evaluate_element, $hash_name, $harden_func ) = @_;

  my $oprf_output =
    finalize( $ec_params->{group}, $ec_params->{order}, $pwd, $blind, $evaluate_element, $hash_name, $ec_params->{ctx} );
  ### oprf_output: unpack("H*", $oprf_output)

  my $stretched_oprf_output = $harden_func->( $oprf_output );
  ### stretched_oprf_output: unpack("H*", $stretched_oprf_output)
  
  my $hash_func   = EVP_get_digestbyname( $hash_name );
  my $Nh          = EVP_MD_get_size( $hash_func );

  my $randomized_pwd = hkdf_extract( $hash_name , $oprf_output . $stretched_oprf_output, '', '', $Nh  );
  ### randomized_pwd: unpack("H*", $randomized_pwd)

  return $randomized_pwd;
}

sub create_registration_response {

  my (
    $request,             $s_pub, $oprf_seed, $credential_identifier, $DSI, $Nseed, $group_name, $info, $DST, $hash_name,
    $expand_message_func, $point_compress_t
  ) = @_;

  ### $request

  my $ikm = hkdf_expand( $hash_name, $oprf_seed, '',  $credential_identifier . $DSI , $Nseed);
  ### ikm: unpack("H*", $ikm)

  my $kU_ec_key_r = derive_key_pair( $group_name, $ikm, $info, $DST, $hash_name, $expand_message_func );
  my $kU          = $kU_ec_key_r->{priv_bn};
  ### kU: $kU->to_hex

  ### $group_name
  my $blindedElement_hex = unpack( "H*", $request->{data} );
  ### $blindedElement_hex
  my $ec_params     = get_ec_params( $group_name );
  my $blind_element = hex2point( $group_name, $blindedElement_hex );
  ### blinded_element:  sn_point2hex($group_name, $blind_element, 2)

  my $evaluate_element = evaluate( $ec_params->{group}, $blind_element, $kU, $ec_params->{ctx} );
  ### evaluate_element: sn_point2hex($group_name, $evaluate_element, 2)
  #evaluated_message = self.config.oprf_suite.group.serialize(evaluated_element)

  my $evaluate_element_hex    = sn_point2hex( $group_name, $evaluate_element, $point_compress_t );
  my $evaluate_element_binary = pack( "H*", $evaluate_element_hex );
  ### $evaluate_element_hex

  my $response = { data => $evaluate_element_binary, s_pub => $s_pub };
  ### $response

  return { response => $response, kU => $kU, ec_params => $ec_params };
} ## end sub create_registration_response

sub create_registration_request {
  my ( $pwd, $blind, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag ) = @_;

  my $blindedElement;
  ( $blind, $blindedElement ) =
    blind( $pwd, $blind, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );

  my $ec_params          = get_ec_params( $group_name );
  my $blindedElement_hex = sn_point2hex( $group_name, $blindedElement, 2 );
  my $request            = { data => pack( "H*", $blindedElement_hex ) };
  return { request => $request, blind => $blind, ec_params => $ec_params };
}

sub create_cleartext_credentials {
  my ( $s_pub, $c_pub, $s_id, $c_id ) = @_;

  $s_id //= $s_pub;
  $c_id //= $c_pub;

  my $cleartext_credentials = join(
    "", $s_pub,
    map { i2osp( length( $_ ), 2 ) . $_ } ( $s_id, $c_id ) );

  return $cleartext_credentials;
}

sub store {
  my ( $randomized_pwd, $s_pub, $s_id, $c_id, $Nn, $Nseed, $group_name, $info, $DST, $hash_name, $expand_message_func, $mac_func ) =
    @_;

  my $envelope_nonce_bn = ( ref( $Nn ) eq 'Crypt::OpenSSL::Bignum' ) ? $Nn : random_bn( $Nn );
  my $envelope_nonce    = $envelope_nonce_bn->to_bin;

  my $hash_func   = EVP_get_digestbyname( $hash_name );
  my $Nh          = EVP_MD_get_size( $hash_func );
  my $masking_key = hkdf_expand( $hash_name, $randomized_pwd, '', "MaskingKey", $Nh  );

  ### opaque store
  ### $randomized_pwd
  ### $hash_name
  ### $Nh
  ### $envelope_nonce
  ### $masking_key
  
  my $auth_key    = hkdf_expand( $hash_name, $randomized_pwd, '',  $envelope_nonce . "AuthKey", $Nh );
  my $export_key    = hkdf_expand( $hash_name, $randomized_pwd, '',  $envelope_nonce . "ExportKey", $Nh );


  ### auth_key: unpack("H*", $auth_key)

  my $seed = hkdf_expand( $hash_name, $randomized_pwd, '',  $envelope_nonce . "PrivateKey", $Nseed  );
  ### seed: unpack("H*", $seed)

  my $c_ec_key_r = derive_key_pair( $group_name, $seed, $info, $DST, $hash_name, $expand_message_func );
  my $c_priv     = $c_ec_key_r->{priv_bn};
  my $c_pub      = $c_ec_key_r->{pub_bin};
  ### c_priv: $c_priv->to_hex
  ### c_pub: unpack("H*", $c_pub)

  my $cleartext_credentials = create_cleartext_credentials( $s_pub, $c_pub, $s_id, $c_id );
  ### cleartext_credentails: unpack("H*", $cleartext_credentials)

  my $auth_tag = $mac_func->( $envelope_nonce . $cleartext_credentials, $auth_key );

  my $envelope = { auth_tag => $auth_tag, nonce => $envelope_nonce };

  return {
    envelope              => $envelope, c_pub => $c_pub, masking_key => $masking_key,
    export_key            => $export_key,
    c_priv                => $c_priv, auth_key => $auth_key,
    cleartext_credentails => $cleartext_credentials,
  };
} ## end sub store

sub recover {
  my (
    $randomized_pwd, $s_pub, $envelope, $s_id, $c_id, $Nseed, $group_name, $info, $DST, $hash_name, $expand_message_func,
    $mac_func
  ) = @_;

  my $hash_func = EVP_get_digestbyname( $hash_name );
  my $Nh        = EVP_MD_get_size( $hash_func );

  my $auth_key = hkdf_expand( $hash_name, $randomized_pwd, '', $envelope->{nonce} . "AuthKey" , $Nh);
  ### auth_key: unpack("H*", $auth_key)
  my $export_key = hkdf_expand(  $hash_name, $randomized_pwd, '', $envelope->{nonce} . "ExportKey" , $Nh);

  #my $masking_key = hkdf_expand($randomized_pwd, $hash_name, $Nh, "MaskingKey");
  ### export_key: unpack("H*", $export_key)

  my $seed = hkdf_expand( $hash_name, $randomized_pwd, '', $envelope->{nonce} . "PrivateKey" ,  $Nseed);
  ### seed: unpack("H*", $seed)

  my $c_ec_key_r = derive_key_pair( $group_name, $seed, $info, $DST, $hash_name, $expand_message_func );
  my $c_priv     = $c_ec_key_r->{priv_bn};
  my $c_pub      = $c_ec_key_r->{pub_bin};
  ### c_priv: $c_priv->to_hex

  my $cleartext_credentials = create_cleartext_credentials( $s_pub, $c_pub, $s_id, $c_id );
  my $expected_tag          = $mac_func->( $envelope->{nonce} . $cleartext_credentials, $auth_key );

  if ( $envelope->{auth_tag} ne $expected_tag ) {
    croak "not match envelope.auth_tag";
  }

  return {
    export_key => $export_key,
    c_priv     => $c_priv,
    c_ec_key_r => $c_ec_key_r,
  };
} ## end sub recover

1;
