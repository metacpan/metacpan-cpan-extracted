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

our $VERSION = '0.03';

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

PKCS5_PBKDF2_HMAC PKCS12_key_gen 
aes_cmac 
ecdh hex2point
bn_mod_sqrt 
digest
); 

our @EXPORT_OK = @EXPORT;


require XSLoader;
XSLoader::load( 'Crypt::OpenSSL::Base::Func', $VERSION );





1;
__END__

