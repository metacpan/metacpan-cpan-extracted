use strict;
use warnings;

use lib '../lib';

use Digest::SHA qw/hmac_sha256 sha256/;

use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::BaseFunc;
use Crypt::Protocol::OPRF;
use Crypt::Protocol::OPAQUE;

#use Smart::Comments;
use CBOR::XS;

#use bignum;
use FindBin qw($Bin);
use Crypt::Protocol::SIGMA;
use Crypt::KeyDerivation ':all';
use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);

#create RegistrationRequest: oprf_context(mode,suite,context_string), pwdU, blind, blinded_element, blinded_message, request.data
#0
#Ciphersuite(name='OPRF(P-256, SHA-256)', identifier=3, group=<sagelib.groups.GroupP256 object at 0x7fd171c66d10>, H=<built-in function openssl_sha256>, hash=<function <lambda> at 0x7fd171c7fe20>)
#b'VOPRF09-\x00\x00\x03'
#b'CorrectHorseBatteryStaple'
#0x411bf1a62d119afe30df682b91a0a33d777972d4f2daa4b34ca527d597078153
#0xa0e1e2b7d6676136224e19c9fdd495d91f49bfe5e8a192e712f065a448e52d28
#0xac1a5902e93b42100833f0de44730045474d9b527e605593b3be73248a90d3e8
#b'\x02\xa0\xe1\xe2\xb7\xd6ga6"N\x19\xc9\xfd\xd4\x95\xd9\x1fI\xbf\xe5\xe8\xa1\x92\xe7\x12\xf0e\xa4H\xe5-('
#b'\x02\xa0\xe1\xe2\xb7\xd6ga6"N\x19\xc9\xfd\xd4\x95\xd9\x1fI\xbf\xe5\xe8\xa1\x92\xe7\x12\xf0e\xa4H\xe5-('
#02a0e1e2b7d6676136224e19c9fdd495d91f49bfe5e8a192e712f065a448e52d28


my $prefix = "VOPRF09-";
my $mode = 0x00;
my $suite_id  = 0x0003;
my $context_string = creat_context_string($prefix, $mode, $suite_id);
my $DST = "HashToGroup-".$context_string;

my $pwd = 'CorrectHorseBatteryStaple';
my $blind = Crypt::OpenSSL::Bignum->new_from_hex('411bf1a62d119afe30df682b91a0a33d777972d4f2daa4b34ca527d597078153');
my $group_name = 'prime256v1';
my $type = 'sswu';
my $hash_name = 'SHA256';
my $expand_message_func = \&expand_message_xmd;

my $req_r = create_registration_request($pwd, $blind, $DST, $group_name, $type, $hash_name, $expand_message_func, 1);
### blind: $req_r->{blind}->to_hex
### request.data ( blindElement.hex ):  unpack("H*", $req_r->{request}{data})

is($req_r->{request}{data}, pack("H*", '02a0e1e2b7d6676136224e19c9fdd495d91f49bfe5e8a192e712f065a448e52d28'), 'create_registration_request');

my $s_priv_hex = 'c36139381df63bfc91c850db0b9cfbec7a62e86d80040a41aa7725bf0e79d5e5';
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

$blind = Crypt::OpenSSL::Bignum->new_from_hex('c497fddf6056d241e6cf9fb7ac37c384f49b357a221eb0a802c989b9942256c1');
my $cred_req_r = create_credential_request($pwd, $blind, $DST, $group_name, $type, $hash_name, $expand_message_func, 1);

my $masking_nonce = Crypt::OpenSSL::Bignum->new_from_hex('38fe59af0df2c79f57b8780278f5ae47355fe1f817119041951c80f612fdfc6d');
my $cred_res_r = create_credential_response(
$cred_req_r->{request}, $s_pub, $oprf_seed, $credential_identifier,"OprfKey", $upload_record->{envelope}, $upload_record->{masking_key}, 
$masking_nonce, $Nseed, $group_name, $info, "DeriveKeyPair".$context_string, $hash_name, $expand_message_func, $point_compress_t, $pack_func, 
);
is($cred_res_r->{masked_response}, pack("H*", 'adb901cb9a50203d9df723560fafa4ce22b66b58a31c8ff070a0bc801ab2161544475404c323712d8916620d4a184cd1603ea31cee0e341d7e3a5da01ab1eef8d6d132ee54cad7a68a72ef06ca0bdde88ac930e13aa906fd284aa79ca51e694f07'), 'create_credential_response');

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
my $recover_r = recover_credentials($cred_req_r, $cred_res_r, $pwd, $c_id, $s_id, $Nseed, $group_name, $finalize_info, $finalize_DST, $hash_name, $expand_message_func, $mac_func, $pwd_harden_func, $unpack_func);
is($recover_r->{c_priv}->to_hex, 'D1D280F712E4EBF3C881C686E13C281BC3A3FAB30A00411A350F4F8B7A1EA550', 'recover_credentials');
is($recover_r->{export_key}, pack("H*", '77869b0d11debf6fc88c1d192dde9546baf528b2f70c2aea89960fc2178586da'), 'recover_credentials');

done_testing;

1;
