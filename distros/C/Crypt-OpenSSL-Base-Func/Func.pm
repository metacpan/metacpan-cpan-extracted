package Crypt::OpenSSL::Base::Func;

use strict;
use warnings;
use bignum;

use Carp;

require Exporter;
use AutoLoader;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Math::BigInt;
use POSIX;
#use Data::Dump qw/dump/;

our $VERSION = '0.032';

our @ISA = qw(Exporter);

our @EXPORT = qw( 
OBJ_sn2nid
EVP_MD_size
EVP_MD_block_size
EVP_get_digestbyname
EC_POINT_point2hex
EC_POINT_hex2point
EC_GROUP_get_curve
EC_POINT_set_affine_coordinates
EC_POINT_get_affine_coordinates
EC_POINT_point2hex
EC_POINT_hex2point
EC_KEY_get0_private_key
EVP_PKEY_new
EVP_PKEY_assign_EC_KEY
EVP_PKEY_get1_EC_KEY
EC_KEY_set_private_key

evp_pkey_from_point_hex
evp_pkey_from_priv_hex
pem_write_evp_pkey
pem_read_pkey

PKCS5_PBKDF2_HMAC 
PKCS12_key_gen 
i2osp
aes_cmac 
ecdh 
ecdh_pkey
hex2point
bn_mod_sqrt 
digest
); 

our @EXPORT_OK = @EXPORT;


require XSLoader;
XSLoader::load( 'Crypt::OpenSSL::Base::Func', $VERSION );


sub i2osp {
    my ($len, $L) = @_;  

    my $s = pack "C*", $len;
    $s = unpack("H*", $s);

    my $s_len = length($s);
    my $tmp_l = $L*2;
    if($tmp_l > $s_len){
        my $pad_len = $tmp_l - $s_len;
        substr $s, 0, 0, ('0') x $pad_len;
    }   

    $s = pack("H*", $s);

    return $s; 
}



1;
__END__

