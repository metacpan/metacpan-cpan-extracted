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

our $VERSION = '0.035';

our @ISA = qw(Exporter);

our @EXPORT = qw( 
EC_GROUP_get_curve
EC_KEY_get0_private_key
EC_KEY_set_private_key
EC_POINT_get_affine_coordinates
EC_POINT_hex2point
EC_POINT_point2hex
EC_POINT_set_affine_coordinates
EVP_MD_block_size
EVP_MD_size
EVP_PKEY_assign_EC_KEY
EVP_PKEY_get1_EC_KEY
EVP_PKEY_new
EVP_get_digestbyname
OBJ_sn2nid

PKCS12_key_gen 
PKCS5_PBKDF2_HMAC 
aes_cmac 
bn_mod_sqrt 
digest
ecdh 
ecdh_pkey
ecdh_pkey_raw
evp_pkey_from_point_hex
evp_pkey_from_priv_hex
generate_ec_key
get_ec_params
hex2point
i2osp
pem_read_pkey
pem_write_evp_pkey
random_bn
sn_hex2point
sn_point2hex
pem_read_priv_hex
pem_read_pub_hex
aead_encrypt_raw
aead_encrypt
aead_encrypt_split
aead_decrypt_raw
aead_decrypt
); 

our @EXPORT_OK = @EXPORT;

require XSLoader;
XSLoader::load( 'Crypt::OpenSSL::Base::Func', $VERSION );

#sub aead_encrypt_main {
    #my ($cipher_name, $plaintext, $aad, $key, $iv, $tag_len) = @_;
    
    #my $res = aead_encrypt($cipher_name, $plaintext, $aad, $key, $iv, $tag_len);
    #my ($ciphertext, $tag) = aead_encrypt_split($res, $tag_len);
    
    #return ($ciphertext, $tag);
#}

sub aead_encrypt_split {
    my ($res, $tag_len) = @_;
    my $ciphertext = substr $res, 0, length($res) - $tag_len;
    my $tag = substr $res, length($res) - $tag_len, $tag_len;
    return ($ciphertext, $tag);
}

sub sn_hex2point {
    my ($group_name, $point_hex) = @_;

    my $ec_params_r = get_ec_params($group_name);
    #my $point_bn = Crypt::OpenSSL::Bignum->new_from_hex($point_hex);
    my $P = hex2point($ec_params_r->{group}, $point_hex);

    return $P;
}

sub sn_point2hex {
    my ($group_name, $point, $point_compress_t) = @_;
    $point_compress_t //= 4;

    my $ec_params_r = get_ec_params($group_name);
    my $point_hex = Crypt::OpenSSL::EC::EC_POINT::point2hex($ec_params_r->{group}, $point, $point_compress_t, $ec_params_r->{ctx});
    return $point_hex;
}

#sub point2hex {
    #my ($group, $point, $point_compress_t, $ctx) = @_;
    #$point_compress_t //= 4;

    #my $point_hex = Crypt::OpenSSL::EC::EC_POINT::point2hex($ec_params_r->{group}, $point, $point_compress_t, $ctx);
    #return $point_hex;
#}


sub random_bn {
    my ($Nn) = @_; 
    my $range_hex = join("", ('ff') x $Nn);
    my $range = Crypt::OpenSSL::Bignum->new_from_hex($range_hex);

    my $random_bn = Crypt::OpenSSL::Bignum->rand_range($range);
    return $random_bn;
}

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

sub generate_ec_key {
    my ( $group, $priv_bn, $point_compress_t, $ctx ) = @_;
    $point_compress_t //= 2;

    my $priv_key = Crypt::OpenSSL::EC::EC_KEY::new();
    $priv_key->set_group( $group );

    if(! $priv_bn){
        $priv_key->generate_key();
        $priv_bn = $priv_key->get0_private_key();
    }
    my $priv_pkey = evp_pkey_from_priv_hex( $group, $priv_bn->to_hex );

    #my $pub_point = Crypt::OpenSSL::EC::EC_POINT::new( $group );
    #my $zero = Crypt::OpenSSL::Bignum->zero;
    #Crypt::OpenSSL::EC::EC_POINT::mul( $group, $pub_point, $zero, $G, $priv_pkey, $ctx );

    my $ec_key = EVP_PKEY_get1_EC_KEY($priv_pkey);

    my $pub_point      = $ec_key->get0_public_key();
    my $pub_hex  = Crypt::OpenSSL::EC::EC_POINT::point2hex( $group, $pub_point, $point_compress_t, $ctx );
    my $pub_bin  = pack( "H*", $pub_hex );
    my $pub_pkey = evp_pkey_from_point_hex( $group, $pub_hex, $ctx );

    return {
        priv_pkey => $priv_pkey, priv_key => $priv_key, priv_bn => $priv_bn, 
        pub_pkey => $pub_pkey, pub_point => $pub_point, pub_hex => $pub_hex, pub_bin => $pub_bin,
    };
} ## end sub generate_ec_key

sub get_ec_params {
    my ( $group_name ) = @_;

    my $nid   = OBJ_sn2nid( $group_name );
    my $group = Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name( $nid );
    my $ctx   = Crypt::OpenSSL::Bignum::CTX->new();


    my $p = Crypt::OpenSSL::Bignum->new();
    my $a = Crypt::OpenSSL::Bignum->new();
    my $b = Crypt::OpenSSL::Bignum->new();
    EC_GROUP_get_curve( $group, $p, $a, $b, $ctx );

    my $degree = Crypt::OpenSSL::EC::EC_GROUP::get_degree($group);

    my $order = Crypt::OpenSSL::Bignum->new();
    Crypt::OpenSSL::EC::EC_GROUP::get_order($group, $order, $ctx);

    my $cofactor = Crypt::OpenSSL::Bignum->new();
    Crypt::OpenSSL::EC::EC_GROUP::get_cofactor($group, $cofactor, $ctx);

    return { 
        nid => $nid, group =>$group, 
        p => $p, a=> $a, b=>$b, 
        degree => $degree, order=> $order, $cofactor=>$cofactor, 
        ctx=> $ctx 
    };
} 


1;
__END__

