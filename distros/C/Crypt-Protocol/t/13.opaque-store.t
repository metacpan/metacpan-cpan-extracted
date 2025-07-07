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

#create envelope: random_pwd, server_public_key, idU, idS, Nh, auth_key, export_key, masking_key, seed, client_public_key, pk_bytes, cleartext_creds, auth_key, envelope_nonce
#ccd32affb94efac1f2bbd7c8632e44a7609178354745dbbeb21540bc05b8696a
#035f40ff9cf88aa1f5cd4fe5fd3da9ea65a4923a5594f84fd9f2092d6067784874
#b'alice'
#b'bob'
#32
#2893cd0b3759bc48949ce2d97472fa565b72ed7b20d1f5dd928fc75fe6d29255
#77869b0d11debf6fc88c1d192dde9546baf528b2f70c2aea89960fc2178586da
#26605b3dae07af6f79501f0bfad82c904b61a59fa7038d87b66b4fdac4707541
#f116ed65b0c631e7cabc59d2cba1bbe15a53d53958aa25c3a31ffd118ce80254
#02cf2d6cec2457d533aafefc830ef389a5be5fafb0dedc4bf8de8899e349df2f43
#02cf2d6cec2457d533aafefc830ef389a5be5fafb0dedc4bf8de8899e349df2f43
#<sagelib.opaque_messages.CleartextCredentials object at 0x7f834cc6f880>
#2893cd0b3759bc48949ce2d97472fa565b72ed7b20d1f5dd928fc75fe6d29255
#a921f2a014513bd8a90e477a629794e89fec12d12206dde662ebdcf65670e51f


my $prefix = "VOPRF09-";
my $mode = 0x00;
my $suite_id  = 0x0003;
my $context_string = creat_context_string($prefix, $mode, $suite_id);
my $DST = "DeriveKeyPair".$context_string;

my $group_name = 'prime256v1';
#my $seed = pack("H*", '5496a9d861b51d9e797e836a130fee901dab7c96eea77f6e65bf1b9e5a44b136');
my $info = 'OPAQUE-DeriveAuthKeyPair';
my $hash_name = 'SHA256';
my $expand_message_func = \&expand_message_xmd;

my $randomized_pwd=pack("H*", 'ccd32affb94efac1f2bbd7c8632e44a7609178354745dbbeb21540bc05b8696a');
my $s_pub = pack("H*", '035f40ff9cf88aa1f5cd4fe5fd3da9ea65a4923a5594f84fd9f2092d6067784874');
my $c_id = 'alice';
my $s_id = 'bob';
my $Nseed = 32;
#my $Nn = 32;
my $Nn  = Crypt::OpenSSL::Bignum->new_from_hex('a921f2a014513bd8a90e477a629794e89fec12d12206dde662ebdcf65670e51f');

my $store_r = store($randomized_pwd, $s_pub, $s_id, $c_id, $Nn, $Nseed, $group_name, $info, $DST, $hash_name, $expand_message_func, \&hmac_sha256);
### auth_tag: unpack("H*", $store_r->{envelope}{auth_tag})
### envelope_nonce: unpack("H*", $store_r->{envelope}{nonce})
### export_key: unpack("H*", $store_r->{export_key})
### masking_key: unpack("H*", $store_r->{masking_key})
### c_pub:  unpack("H*", $store_r->{c_pub})

is(unpack("H*", $store_r->{export_key}), '77869b0d11debf6fc88c1d192dde9546baf528b2f70c2aea89960fc2178586da', 'store: export_key');


is(unpack("H*", $store_r->{envelope}{auth_tag}), 'fea1d1f93f65896f14c0805f6fda165dbaad00212b8b27bcc988222866713ba2', 'store: auth_tag');

my $recover_r = recover($randomized_pwd, $s_pub, $store_r->{envelope}, $s_id, $c_id, $Nseed, $group_name, $info, $DST, $hash_name, $expand_message_func, \&hmac_sha256);
is(unpack("H*", $recover_r->{export_key}), '77869b0d11debf6fc88c1d192dde9546baf528b2f70c2aea89960fc2178586da', 'recover: export_key');
is($recover_r->{c_priv}->to_hex, 'D1D280F712E4EBF3C881C686E13C281BC3A3FAB30A00411A350F4F8B7A1EA550', 'recover: priv');

done_testing;
1;
