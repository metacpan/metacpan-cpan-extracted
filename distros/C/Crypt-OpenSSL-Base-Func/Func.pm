package Crypt::OpenSSL::Base::Func;

use strict;
use warnings;

use Carp;

require Exporter;
use AutoLoader;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use POSIX;
#use Smart::Comments;

our $VERSION = '0.038';

our @ISA = qw(Exporter);

our @OSSLF= qw(
BN_bn2hex
EC_GROUP_get_curve
EC_POINT_get_affine_coordinates
EC_POINT_set_affine_coordinates
EVP_MD_get_block_size
EVP_MD_get_size
EVP_PKEY_get1_EC_KEY
EVP_get_digestbyname
OBJ_sn2nid
OBJ_nid2sn
);

our @XSF = qw(
hex2point
aead_decrypt
aead_encrypt
aes_cmac 
bn_mod_sqrt 
ecdh 
ecdsa_sign
ecdsa_verify
export_ec_pubkey
export_rsa_pubkey
gen_ec_key
gen_ec_pubkey
get_ec_params
get_pkey_bn_param
get_pkey_octet_string_param
get_pkey_utf8_string_param
hex2bn
hexdump
slurp
bin2hex
pkcs12_key_gen 
pkcs5_pbkdf2_hmac
print_pkey_gettable_params
read_key
read_pubkey
read_ec_pubkey
read_key_from_der
read_key_from_pem
read_pubkey_from_der
read_pubkey_from_pem
rsa_oaep_decrypt
rsa_oaep_encrypt
symmetric_decrypt
symmetric_encrypt
write_key_to_der
write_key_to_pem
write_pubkey_to_der
write_pubkey_to_pem
digest_array
);

our @PMF = qw(
hkdf
hkdf_expand
hkdf_extract
hmac
i2osp
random_bn
sn_point2hex
generate_ec_key
get_ec_params 
digest
);
#aead_encrypt_split

our @EXPORT = ( @OSSLF, @XSF, @PMF ); 

our @EXPORT_OK = @EXPORT;

require XSLoader;
XSLoader::load( 'Crypt::OpenSSL::Base::Func', $VERSION );

sub digest {
    my ($digest_name, @arr) = @_;
    return digest_array($digest_name, \@arr);
}

sub hkdf {
# define EVP_KDF_HKDF_MODE_EXTRACT_AND_EXPAND  0
# define EVP_KDF_HKDF_MODE_EXTRACT_ONLY        1
# define EVP_KDF_HKDF_MODE_EXPAND_ONLY         2
    my ($digest_name, $k, $salt, $info, $len) = @_;
    return hkdf_main(0, $digest_name, $k, $salt, $info, $len);
}

sub hkdf_extract {
    my ($digest_name, $k, $salt, $info, $len) = @_;
    return hkdf_main(1, $digest_name, $k, $salt, $info, $len);
}

sub hkdf_expand {
    my ($digest_name, $k, $salt, $info, $len) = @_;
    return hkdf_main(2, $digest_name, $k, $salt, $info, $len);
}



sub sn_point2hex {
    my ($group_name, $point, $point_compress_t) = @_;
    $point_compress_t //= 4;

    my $ec_params_r = get_ec_params($group_name);
    my $point_hex = Crypt::OpenSSL::EC::EC_POINT::point2hex($ec_params_r->{group}, $point, $point_compress_t, $ec_params_r->{ctx});
    return $point_hex;
}


#sub aead_encrypt_split {
    #my ($res, $tag_len) = @_;
    #my $ciphertext = substr $res, 0, length($res) - $tag_len;
    #my $tag = substr $res, length($res) - $tag_len, $tag_len;
    #return ($ciphertext, $tag);
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
    my ( $group_name, $priv_hex ) = @_;

    my $priv_pkey = gen_ec_key($group_name, $priv_hex || '');
    $priv_hex = read_key($priv_pkey);
    my $priv_bn  = Crypt::OpenSSL::Bignum->new_from_hex($priv_hex);
    #print "hex:$priv_hex,\n";

    my $pub_pkey = export_ec_pubkey($priv_pkey);
    my $pub_hex = read_ec_pubkey($pub_pkey, 1);
    #print "hex:$pub_hex,\n";
    my $pub_bin  = pack( "H*", $pub_hex );

    my $pub_point =hex2point($group_name, $pub_hex);

    return {
        name => $group_name, 
        priv_pkey => $priv_pkey, 
        #priv_key => $priv_key, 
        priv_bn => $priv_bn,
        pub_pkey => $pub_pkey, 
        pub_point => $pub_point, 
        pub_hex => $pub_hex, 
        pub_bin => $pub_bin,
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
        nid => $nid,
        name => $group_name,
        group =>$group,
        p => $p, a=> $a, b=>$b, degree => $degree, order=> $order, cofactor=>$cofactor,
        ctx=> $ctx,
    };
}

1;
__END__

