package Crypt::OpenSSL::BaseFunc;

use strict;
use warnings;

use Carp;

require Exporter;
use AutoLoader;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use POSIX;

#use Smart::Comments;

our $VERSION = '0.039';

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
EC_POINT_point2hex
OBJ_sn2nid
OBJ_nid2sn
EC_POINT_new
);

our @XSF = qw(
mul_ec_point
point2hex
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
gen_ec_point
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

our @H2C = qw(
  sgn0_m_eq_1
  clear_cofactor
  CMOV

  calc_c1_c2_for_sswu
  map_to_curve_sswu_not_straight_line
  map_to_curve_sswu_straight_line

  sn2kv
  get_hash2curve_params
  expand_message_xmd
  hash_to_field
  map_to_curve
  encode_to_curve
  hash_to_curve
);

our @EXPORT = ( @OSSLF, @XSF, @PMF, @H2C ); 

our @EXPORT_OK = @EXPORT;

require XSLoader;
XSLoader::load( 'Crypt::OpenSSL::BaseFunc', $VERSION );

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

    ### generate_ec_key

    my $priv_pkey = gen_ec_key($group_name, $priv_hex || '');
    $priv_hex = read_key($priv_pkey);
    my $priv_bn  = Crypt::OpenSSL::Bignum->new_from_hex($priv_hex);
   
    ### $priv_hex

    my $pub_pkey = export_ec_pubkey($priv_pkey);

    ### $pub_pkey
    
    ### read_pubkey: read_pubkey($pub_pkey)

    my $pub_hex = read_ec_pubkey($pub_pkey, 1);

    ### $pub_hex

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

# Hash2Curve

our %H2C_CNF = (
  'prime256v1' => {
      k => 0x80,
      m => 1,
      'sswu' => {
          z                 => '-10',
          calc_c1_c2_func   => \&calc_c1_c2_for_sswu,
          map_to_curve_func => \&map_to_curve_sswu_straight_line,
      },
  },
);

sub sn2kv {
my ($group_name, $param_name) = @_;
return $H2C_CNF{$group_name}{$param_name};
}


sub get_hash2curve_params {
    my ( $group_name, $type ) = @_;

    my $ec_params_r = get_ec_params($group_name);
    
    $ec_params_r->{$_} = $H2C_CNF{$group_name}{$_} for keys(%{$H2C_CNF{$group_name}});

    if($type eq 'sswu'){
        my $z = Crypt::OpenSSL::Bignum->new_from_decimal( $H2C_CNF{$group_name}{$type}{z} );
        my $c1 = Crypt::OpenSSL::Bignum->new();
        my $c2 = Crypt::OpenSSL::Bignum->new();
        $H2C_CNF{$group_name}{$type}{calc_c1_c2_func}->( $c1, $c2, 
            @{$ec_params_r}{qw/p a b/}, 
            $z, 
            $ec_params_r->{ctx}, 
        );

        @{$ec_params_r}{qw/c1 c2 z/} = ($c1, $c2, $z);

    }

    $ec_params_r;
} ## end sub get_hash2curve_params

sub hash_to_curve {
  my ( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag ) = @_;

  my $h2c_r = get_hash2curve_params( $group_name, $type );
  #my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

  my $count = 2;
  #my ( $k, $m ) = sn2k_m( $group_name );
  my @res = hash_to_field( $msg, $count, $DST, $h2c_r->{p}, $h2c_r->{m}, $h2c_r->{k}, $hash_name, $expand_message_func );

  my $u0 = $res[0][0];
  my $Q0 = map_to_curve( $h2c_r, $group_name, $type, $u0, $clear_cofactor_flag );

  my $u1 = $res[1][0];
  my $Q1 = map_to_curve( $h2c_r, $group_name, $type, $u1, $clear_cofactor_flag );

  my $Q = Crypt::OpenSSL::EC::EC_POINT::new( $h2c_r->{group} );
  Crypt::OpenSSL::EC::EC_POINT::add( $h2c_r->{group}, $Q, $Q0, $Q1, $h2c_r->{ctx} );

  return $Q unless ( $clear_cofactor_flag );

  my $P = Crypt::OpenSSL::EC::EC_POINT::new( $h2c_r->{group} );
  clear_cofactor( $h2c_r->{group}, $P, $Q, $h2c_r->{ctx} );

  return wantarray ? ($P, $h2c_r) : $P;
} ## end sub hash_to_curve

sub encode_to_curve {
  my ( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag ) = @_;

  my $h2c_r = get_hash2curve_params( $group_name, $type );
  #my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

  my $count = 1;
  #my ( $k, $m ) = sn2k_m( $group_name );
  #my @res = hash_to_field( $msg, $count, $DST, $p, $m, $k, $hash_name, $expand_message_func );
  my @res = hash_to_field( $msg, $count, $DST, $h2c_r->{p}, $h2c_r->{m}, $h2c_r->{k}, $hash_name, $expand_message_func );

  my $u = $res[0][0];
  my $P = map_to_curve( $h2c_r, $group_name, $type, $u, $clear_cofactor_flag );
  return wantarray ? ($P, $h2c_r) : $P;
}

sub map_to_curve {
  my ( $params_ref, $group_name, $type, $u, $clear_cofactor_flag ) = @_;

  #my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

  my $x = Crypt::OpenSSL::Bignum->new();
  my $y = Crypt::OpenSSL::Bignum->new();
  $H2C_CNF{$group_name}{$type}{map_to_curve_func}->( 
      @{$params_ref}{qw/c1 c2 p a b z/}, 
      $u, $x, $y, $params_ref->{ctx} );

  ### $u 
  my $Q = gen_ec_point($group_name, $x, $y, $clear_cofactor_flag);

  ### $Q

  return $Q;
} ## end sub map_to_curve



#sub CMOV {
#my ($a, $b, $c) = @_;
#return $b if($c);
#return $a;
#}

sub hash_to_field {
  my ( $msg, $count, $DST, $p, $m, $k, $hash_name, $expand_message_func ) = @_;

  my $ctx = Crypt::OpenSSL::Bignum::CTX->new();

  my $L = $p->num_bits;
  $L = ceil(($L + $k)/8);
  ### $L

  my $len_in_bytes  = $count * $m * $L;
  ### len_in_bytes: $len_in_bytes
  my $uniform_bytes = $expand_message_func->( $msg, $DST, $len_in_bytes, $hash_name );
  ### uniform_bytes: unpack("H*", $uniform_bytes)

  my @res;
  for my $i ( 0 .. $count - 1 ) {
    my @u;
    for my $j ( 0 .. $m - 1 ) {
      my $elm_offset = $L * ( $j + $i * $m );
      my $tv         = substr( $uniform_bytes, $elm_offset, $L );

      my $tv_bn =  Crypt::OpenSSL::Bignum->new_from_bin( $tv );
      my $reminder = $tv_bn->mod($p, $ctx);
      ### reminder: $reminder->to_hex()
      ### reminder: $reminder->to_decimal()
      
      push @u, $reminder;
    }
    push @res, \@u;
  }
  return @res;
} ## end sub hash_to_field

sub expand_message_xmd {
  my ( $msg, $DST, $len_in_bytes, $hash_name ) = @_;

  #my $h_r = Crypt::OpenSSL::EVP::MD->new( $hash_name );
  my $h_r = EVP_get_digestbyname( $hash_name );

  my $hash_size = EVP_MD_get_size( $h_r );
  #my $ell = ceil( $len_in_bytes / $h_r->size() );
  #my $ell = ceil( $len_in_bytes / $hash_size );
  my $ell = ceil( $len_in_bytes / $hash_size );
  return if ( $ell > 255 );

  ### len_in_bytes: $len_in_bytes
  ### md get size : EVP_MD_get_size( $h_r )
  ### ell: $ell

  my $DST_len     = length( $DST );
  my $DST_len_hex = pack( "C*", $DST_len );
  my $DST_prime   = $DST . $DST_len_hex;
  ### DST: unpack("H*", $DST)
  ### $DST_len
  ### DST_len_hex: unpack("H*", $DST_len_hex)
  ### DST_prime: unpack("H*", $DST_prime)
  
  my $rn    = EVP_MD_get_block_size( $h_r ) * 2;
  my $Z_pad = pack( "H$rn", '00' );

  my $l_i_b_str = pack( "S>", $len_in_bytes );

  my $zero = pack( "H*", '00' );

  my $msg_prime = $Z_pad . $msg . $l_i_b_str . $zero . $DST_prime;
  ### msg_prime: unpack("H*", $msg_prime)
  
  my $len       = pack( "C*", 1 );
  my $b0        = digest( $hash_name, $msg_prime );


  my $b1 = digest( $hash_name, $b0 . $len . $DST_prime );

  ### b0: unpack("H*", $b0)
  ### b1: unpack("H*", $b1)

  #my $b0  = $h_r->digest( $msg_prime );
  #my $b1  = $h_r->digest( $b0 . $len . $DST_prime );

  my $b_prev        = $b1;
  my $uniform_bytes = $b1;
  for my $i ( 2 .. $ell ) {
    my $tmp = ( $b0 ^ $b_prev ) . pack( "C*", $i ) . $DST_prime;
    my $bi  = digest( $hash_name, $tmp );

    ### bi: unpack("H*", $bi)

    $uniform_bytes .= $bi;
    $b_prev = $bi;
  }

  ### uniform_bytes: unpack("H*", $uniform_bytes)
  my $res = substr( $uniform_bytes, 0, $len_in_bytes );
  ### res: unpack("H*", $res)

  return $res;
} ## end sub expand_message_xmd

1;
__END__

