package Crypto::Utils::OpenSSL;

use strict;
use warnings;

use Carp;

require Exporter;
use FFI::CheckLib qw(find_lib_or_die);
use FFI::Platypus 1.00;
use FFI::Platypus::Buffer qw(buffer_to_scalar scalar_to_pointer);
use POSIX;

our $VERSION = '0.039';

our @ISA = qw(Exporter);

our @OSSLF = qw(
  BN_bn2hex
  BN_hex2bn
  BN_dec2bn
  BN_bin2bn
  BN_bn2bin
  OPENSSL_free
  EC_POINT_invert
  EC_POINT_add
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
  EC_POINT_copy
  EC_GROUP_get0_order
  EC_POINT_is_at_infinity
  EC_POINT_is_on_curve
  EC_POINT_mul
  EC_GROUP_get_curve_name
  EC_GROUP_get_order
  EC_GROUP_get_degree
  EC_GROUP_get_cofactor
  EC_GROUP_new_by_curve_name
  BN_new
  BN_CTX_new
  BN_copy
  BN_add
  BN_sub
  BN_mod
  bn_mod
  BN_rand_range
  BN_value_one
  BN_one
  BN_zero
  BN_mod_inverse
  BN_is_zero
  BN_is_one
  BN_cmp
  BN_num_bits
  is_bn
);

our @FFIF = qw(
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
  scrypt
);

#aead_encrypt_split

our @H2C = qw(
  sgn0_m_eq_1
  clear_cofactor
  CMOV

  calc_c1_c2_for_sswu
  map_to_curve_sswu_not_straight_line
  map_to_curve_sswu_straight_line

  expand_message_xmd
);

our @EXPORT = ( @OSSLF, @FFIF, @PMF, @H2C );

our @EXPORT_OK = @EXPORT;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->bundle('Crypto::Utils');

my $crypto = FFI::Platypus->new( api => 1 );
$crypto->lib( $ENV{CRYPTO_LIB} || find_lib_or_die( lib => 'crypto' ) );

sub _ptr {
    my ($obj) = @_;
    return undef unless defined $obj;
    return ref($obj) ? ${$obj} : $obj;
}

sub _obj {
    my ( $ptr, $class ) = @_;
    return undef unless defined $class;
    return undef unless defined $ptr && $ptr;
    return bless \$ptr, $class;
}

sub _bytes_from_ptr {
    my ( $ptr, $len ) = @_;
    return undef unless $ptr;
    return undef if !defined($len) || $len < 0;
    my $out = buffer_to_scalar( $ptr, $len );
    OPENSSL_free($ptr);
    return $out;
}

sub _string_from_ptr {
    my ($ptr) = @_;
    return undef unless $ptr;
    my $out = $ffi->cast( 'opaque' => 'string', $ptr );
    OPENSSL_free($ptr);
    return $out;
}

$crypto->attach(
    [ CRYPTO_free => '_CRYPTO_free' ] => [ 'opaque', 'string', 'int' ] =>
      'void' );

sub OPENSSL_free {
    my ($ptr) = @_;
    _CRYPTO_free( _ptr($ptr), __FILE__, __LINE__ );
}

$crypto->attach( 'OBJ_nid2sn'           => ['int']    => 'string' );
$crypto->attach( 'OBJ_sn2nid'           => ['string'] => 'int' );
$crypto->attach( 'EVP_get_digestbyname' => ['string'] => 'opaque' );
if ( $crypto->find_symbol('EVP_MD_get_block_size') ) {
    $crypto->attach( 'EVP_MD_get_block_size' => ['opaque'] => 'int' );
}
else {
    $crypto->attach(
        [ 'EVP_MD_block_size' => 'EVP_MD_get_block_size' ] => ['opaque'] =>
          'int' );
}
if ( $crypto->find_symbol('EVP_MD_get_size') ) {
    $crypto->attach( 'EVP_MD_get_size' => ['opaque'] => 'int' );
}
else {
    $crypto->attach(
        [ 'EVP_MD_size' => 'EVP_MD_get_size' ] => ['opaque'] => 'int' );
}
$crypto->attach( 'EVP_MD_CTX_new'  => []         => 'opaque' );
$crypto->attach( 'EVP_MD_CTX_free' => ['opaque'] => 'void' );
if ( $crypto->find_symbol('EVP_DigestInit_ex2') ) {
    $crypto->attach(
        'EVP_DigestInit_ex2' => [ 'opaque', 'opaque', 'opaque' ] => 'int' );
}
else {
    $crypto->attach( [ 'EVP_DigestInit_ex' => 'EVP_DigestInit_ex2' ] =>
          [ 'opaque', 'opaque', 'opaque' ] => 'int' );
}
$crypto->attach(
    'EVP_DigestUpdate' => [ 'opaque', 'string', 'size_t' ] => 'int' );
$crypto->attach(
    'EVP_DigestFinal_ex' => [ 'opaque', 'opaque', 'uint*' ] => 'int' );
$crypto->attach( [ BN_bn2hex => '_BN_bn2hex' ] => ['opaque'] => 'opaque' );
$crypto->attach(
    [ BN_hex2bn => '_BN_hex2bn' ] => [ 'opaque*', 'string' ] => 'int' );
$crypto->attach(
    [ BN_dec2bn => '_BN_dec2bn' ] => [ 'opaque*', 'string' ] => 'int' );
$crypto->attach(
    [ BN_bin2bn => '_BN_bin2bn' ] => [ 'string', 'int', 'opaque' ] =>
      'opaque' );
$crypto->attach( 'BN_new'     => [] => 'opaque' );
$crypto->attach( 'BN_CTX_new' => [] => 'opaque' );
$crypto->attach(
    [ BN_copy => '_BN_copy' ] => [ 'opaque', 'opaque' ] => 'opaque' );
$crypto->attach(
    [ BN_add => '_BN_add' ] => [ 'opaque', 'opaque', 'opaque' ] => 'int' );
$crypto->attach(
    [ BN_sub => '_BN_sub' ] => [ 'opaque', 'opaque', 'opaque' ] => 'int' );
$crypto->attach( [ BN_mod_inverse => '_BN_mod_inverse' ] =>
      [ 'opaque', 'opaque', 'opaque', 'opaque' ] => 'opaque' );
$crypto->attach( [ BN_div => '_BN_div' ] =>
      [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int' );
$crypto->attach( [ BN_num_bits => '_BN_num_bits' ] => ['opaque'] => 'int' );
$crypto->attach( [ BN_cmp => '_BN_cmp' ] => [ 'opaque', 'opaque' ] => 'int' );
$crypto->attach(
    [ BN_rand_range => '_BN_rand_range' ] => [ 'opaque', 'opaque' ] => 'int' );
$crypto->attach(
    [ EC_GROUP_get0_order => '_EC_GROUP_get0_order' ] => ['opaque'] =>
      'opaque' );
$crypto->attach( [ EC_GROUP_get_order => '_EC_GROUP_get_order' ] =>
      [ 'opaque', 'opaque', 'opaque' ] => 'int' );
$crypto->attach(
    [ EC_GROUP_get_degree => '_EC_GROUP_get_degree' ] => ['opaque'] => 'int' );
$crypto->attach( [ EC_GROUP_get_cofactor => '_EC_GROUP_get_cofactor' ] =>
      [ 'opaque', 'opaque', 'opaque' ] => 'int' );
$crypto->attach( 'EC_GROUP_new_by_curve_name' => ['int'] => 'opaque' );
$crypto->attach(
    [ EC_GROUP_get_curve_name => '_EC_GROUP_get_curve_name' ] => ['opaque'] =>
      'int' );

if ( $crypto->find_symbol('EC_GROUP_get_curve') ) {
    $crypto->attach( [ EC_GROUP_get_curve => '_EC_GROUP_get_curve' ] =>
          [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int' );
}
else {
    $crypto->attach( [ EC_GROUP_get_curve_GFp => '_EC_GROUP_get_curve' ] =>
          [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int' );
}
$crypto->attach(
    [ EC_POINT_new => '_EC_POINT_new' ] => ['opaque'] => 'opaque' );
$crypto->attach(
    [ EC_POINT_copy => '_EC_POINT_copy' ] => [ 'opaque', 'opaque' ] => 'int' );
$crypto->attach( [ EC_POINT_is_at_infinity => '_EC_POINT_is_at_infinity' ] =>
      [ 'opaque', 'opaque' ] => 'int' );
$crypto->attach( [ EC_POINT_is_on_curve => '_EC_POINT_is_on_curve' ] =>
      [ 'opaque', 'opaque', 'opaque' ] => 'int' );
$crypto->attach( [ EC_POINT_mul => '_EC_POINT_mul' ] =>
      [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int' );
$crypto->attach( [ EC_POINT_invert => '_EC_POINT_invert' ] =>
      [ 'opaque', 'opaque', 'opaque' ] => 'int' );
$crypto->attach( [ EC_POINT_add => '_EC_POINT_add' ] =>
      [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int' );

if ( $crypto->find_symbol('EC_POINT_set_affine_coordinates') ) {
    $crypto->attach(
        [
            EC_POINT_set_affine_coordinates =>
              '_EC_POINT_set_affine_coordinates'
        ] => [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int'
    );
}
else {
    $crypto->attach(
        [
            EC_POINT_set_affine_coordinates_GFp =>
              '_EC_POINT_set_affine_coordinates'
        ] => [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int'
    );
}

if ( $crypto->find_symbol('EC_POINT_get_affine_coordinates') ) {
    $crypto->attach(
        [
            EC_POINT_get_affine_coordinates =>
              '_EC_POINT_get_affine_coordinates'
        ] => [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int'
    );
}
else {
    $crypto->attach(
        [
            EC_POINT_get_affine_coordinates_GFp =>
              '_EC_POINT_get_affine_coordinates'
        ] => [ 'opaque', 'opaque', 'opaque', 'opaque', 'opaque' ] => 'int'
    );
}
$crypto->attach( [ EC_POINT_point2hex => '_EC_POINT_point2hex' ] =>
      [ 'opaque', 'opaque', 'int', 'opaque' ] => 'opaque' );
$crypto->attach( [ EC_POINT_hex2point => '_EC_POINT_hex2point' ] =>
      [ 'opaque', 'string', 'opaque', 'opaque' ] => 'opaque' );
$crypto->attach(
    [ EVP_PKEY_get1_EC_KEY => '_EVP_PKEY_get1_EC_KEY' ] => ['opaque'] =>
      'opaque' );

$ffi->attach( 'hexdump' => [ 'string', 'string', 'int' ] => 'void' );
$ffi->attach( 'slurp' => [ 'string', 'opaque*' ] => 'size_t' );
$ffi->attach( [ hex2bn       => '_hex2bn' ]      => ['string'] => 'opaque' );
$ffi->attach( [ bn_value_one => 'BN_value_one' ] => []         => 'opaque' );
$ffi->attach( [ bn_one       => '_BN_one' ]      => ['opaque'] => 'int' );
$ffi->attach( [ bn_zero      => '_BN_zero' ]     => ['opaque'] => 'void' );
$ffi->attach( [ bn2bin => '_BN_bn2bin' ] => [ 'opaque', 'opaque*' ] => 'int' );
$ffi->attach( 'bin2hex' => [ 'string', 'size_t' ] => 'string' );
$ffi->attach(
    [ get_pkey_bn_param => '_get_pkey_bn_param' ] => [ 'opaque', 'string' ] =>
      'opaque' );
$ffi->attach(
    [ get_pkey_octet_string_param => '_get_pkey_octet_string_param' ] =>
      [ 'opaque', 'string', 'opaque*' ] => 'size_t' );
$ffi->attach( [ get_pkey_utf8_string_param => '_get_pkey_utf8_string_param' ] =>
      [ 'opaque', 'string' ] => 'opaque' );
$ffi->attach(
    [ export_rsa_pubkey => '_export_rsa_pubkey' ] => ['opaque'] => 'opaque' );
$ffi->attach( [ rsa_oaep_encrypt => '_rsa_oaep_encrypt' ] =>
      [ 'string', 'opaque', 'string', 'size_t', 'opaque*' ] => 'size_t' );
$ffi->attach( [ rsa_oaep_decrypt => '_rsa_oaep_decrypt' ] =>
      [ 'string', 'opaque', 'string', 'size_t', 'opaque*' ] => 'size_t' );
$ffi->attach( [ read_key => '_read_key' ] => ['opaque'] => 'opaque' );
$ffi->attach( 'read_key_from_der'         => ['string'] => 'opaque' );
$ffi->attach( 'read_pubkey_from_der'      => ['string'] => 'opaque' );
$ffi->attach( 'read_key_from_pem'         => ['string'] => 'opaque' );
$ffi->attach( 'read_pubkey_from_pem'      => ['string'] => 'opaque' );
$ffi->attach( [ read_pubkey => '_read_pubkey' ] => ['opaque'] => 'opaque' );
$ffi->attach( [ read_ec_pubkey => '_read_ec_pubkey' ] => [ 'opaque', 'int' ] =>
      'opaque' );
$ffi->attach(
    [ bn_mod_sqrt => '_bn_mod_sqrt' ] => [ 'opaque', 'opaque' ] => 'opaque' );
$ffi->attach( [ aes_cmac => '_aes_cmac' ] =>
      [ 'string', 'string', 'size_t', 'string', 'size_t', 'size_t*' ] =>
      'opaque' );
$ffi->attach(
    [ pkcs12_key_gen => '_pkcs12_key_gen' ] => [
        'string', 'size_t', 'string', 'size_t',
        'uint',   'uint',   'string', 'size_t*'
    ] => 'opaque'
);
$ffi->attach( [ pkcs5_pbkdf2_hmac => '_pkcs5_pbkdf2_hmac' ] =>
      [ 'string', 'size_t', 'string', 'size_t', 'uint', 'string',
        'size_t*' ] => 'opaque' );
$ffi->attach( [ hmac => '_hmac' ] =>
      [ 'string', 'string', 'size_t', 'string', 'size_t', 'opaque*' ] =>
      'int' );
$ffi->attach(
    [ hkdf => '_hkdf' ] => [
        'int',    'string', 'string',  'size_t', 'string', 'size_t',
        'string', 'size_t', 'opaque*', 'size_t'
    ] => 'int'
);
$ffi->attach(
    [ scrypt => '_scrypt' ] => [
        'string', 'size_t', 'string',  'size_t', 'uint64', 'uint32',
        'uint32', 'uint64', 'opaque*', 'size_t'
    ] => 'int'
);
$ffi->attach(
    [ ecdh => '_ecdh' ] => [ 'opaque', 'opaque', 'size_t*' ] => 'opaque' );
$ffi->attach(
    [ gen_ec_key => '_gen_ec_key' ] => [ 'string', 'string' ] => 'opaque' );
$ffi->attach( 'gen_ec_pubkey' => [ 'string', 'string' ] => 'opaque' );
$ffi->attach(
    [ export_ec_pubkey => '_export_ec_pubkey' ] => ['opaque'] => 'opaque' );
$ffi->attach(
    [ write_key_to_der => '_write_key_to_der' ] => [ 'string', 'opaque' ] =>
      'string' );
$ffi->attach(
    [ write_key_to_pem => '_write_key_to_pem' ] => [ 'string', 'opaque' ] =>
      'string' );
$ffi->attach( [ write_pubkey_to_der => '_write_pubkey_to_der' ] =>
      [ 'string', 'opaque' ] => 'string' );
$ffi->attach( [ write_pubkey_to_pem => '_write_pubkey_to_pem' ] =>
      [ 'string', 'opaque' ] => 'string' );
$ffi->attach( [ ecdsa_sign => '_ecdsa_sign' ] =>
      [ 'opaque', 'string', 'string', 'int', 'opaque*' ] => 'int' );
$ffi->attach( [ ecdsa_verify => '_ecdsa_verify' ] =>
      [ 'opaque', 'string', 'string', 'int', 'string', 'int' ] => 'int' );
$ffi->attach(
    [ symmetric_cipher => '_symmetric_cipher' ] => [
        'string', 'string', 'int', 'string', 'string', 'int', 'opaque*', 'int'
    ] => 'int'
);
$ffi->attach(
    [ aead_encrypt => '_aead_encrypt' ] => [
        'string', 'string', 'int',     'string',  'int', 'string',
        'string', 'int',    'opaque*', 'opaque*', 'int'
    ] => 'int'
);
$ffi->attach(
    [ aead_decrypt => '_aead_decrypt' ] => [
        'string', 'string', 'int',    'string', 'int', 'string',
        'int',    'string', 'string', 'int',    'opaque*'
    ] => 'int'
);
$ffi->attach( [ print_pkey_gettable_params => '_print_pkey_gettable_params' ] =>
      ['opaque'] => 'void' );
$ffi->attach( [ sgn0_m_eq_1 => '_sgn0_m_eq_1' ] => ['opaque'] => 'int' );
$ffi->attach(
    [ CMOV => '_CMOV' ] => [ 'opaque', 'opaque', 'int' ] => 'opaque' );
$ffi->attach( [ calc_c1_c2_for_sswu => '_calc_c1_c2_for_sswu' ] =>
      [ ( ('opaque') x 7 ) ] => 'int' );
$ffi->attach(
    [ map_to_curve_sswu_straight_line => '_map_to_curve_sswu_straight_line' ]
    => [ ( ('opaque') x 10 ) ] => 'int' );
$ffi->attach(
    [
        map_to_curve_sswu_not_straight_line =>
          '_map_to_curve_sswu_not_straight_line'
    ] => [ ( ('opaque') x 8 ) ] => 'int'
);

sub BN_bn2hex {
    my $ptr = _BN_bn2hex( _ptr( $_[0] ) );
    return _string_from_ptr($ptr);
}

sub BN_hex2bn {
    my ( $bn_ref, $hex_str ) = @_;
    croak "BN_hex2bn: hex string is required" unless defined $hex_str;

    my $raw_ptr = _ptr($bn_ref);
    my $ret     = _BN_hex2bn( \$raw_ptr, $hex_str );
    return $ret;
}

sub BN_dec2bn {
    my ( $bn_ref, $dec_str ) = @_;
    croak "BN_dec2bn: decimal string is required" unless defined $dec_str;

    my $raw_ptr = _ptr($bn_ref);
    my $ret     = _BN_dec2bn( \$raw_ptr, $dec_str );
    return $ret;
}

sub BN_bin2bn {
    my ( $bytes, $len, $ret ) = @_;
    croak "BN_bin2bn: binary string is required" unless defined $bytes;
    $len //= length($bytes);

    if ( defined $ret ) {
        _BN_bin2bn( $bytes, $len, _ptr($ret) );
        return $ret;
    }
    else {
        return _BN_bin2bn( $bytes, $len, undef );
    }
}

sub BN_copy {
    return _BN_copy( _ptr( $_[0] ), _ptr( $_[1] ) );
}

sub BN_add {
    return _BN_add( map { _ptr($_) } @_ );
}

sub BN_sub {
    return _BN_sub( map { _ptr($_) } @_ );
}

sub BN_mod_inverse {
    my ( $r, $a, $n, $ctx ) = @_;
    if ( defined $r ) {
        _BN_mod_inverse( _ptr($r), _ptr($a), _ptr($n), _ptr($ctx) );
        return $r;
    }
    else {
        return _BN_mod_inverse( undef, _ptr($a), _ptr($n), _ptr($ctx) );
    }
}

sub BN_num_bits {
    return _BN_num_bits( _ptr( $_[0] ) );
}

sub BN_cmp {
    return _BN_cmp( _ptr( $_[0] ), _ptr( $_[1] ) );
}

sub BN_is_zero {
    return BN_num_bits( _ptr( $_[0] ) ) == 0;
}

sub BN_is_one {
    return BN_cmp( _ptr( $_[0] ), BN_value_one() ) == 0;
}

sub BN_mod {
    if ( scalar @_ == 3 ) {
        my ( $a, $b, $ctx ) = @_;
        my $rem = BN_new();
        _BN_div( undef, _ptr($rem), _ptr($a), _ptr($b), _ptr($ctx) );
        return $rem;
    }
    else {
        my ( $rem, $m, $d, $ctx ) = @_;
        return _BN_div( undef, _ptr($rem), _ptr($m), _ptr($d), _ptr($ctx) );
    }
}

sub bn_mod {
    return BN_mod(@_);
}

sub BN_rand_range {
    return _BN_rand_range( map { _ptr($_) } @_ );
}

my %GROUP_CACHE;

sub _get_cached_group {
    my ($group_or_name) = @_;
    return undef unless defined $group_or_name;
    return $group_or_name if ref($group_or_name);    # already a group object

    if ( !$GROUP_CACHE{$group_or_name} ) {
        my $nid = OBJ_sn2nid($group_or_name);
        $GROUP_CACHE{$group_or_name} = EC_GROUP_new_by_curve_name($nid);
    }
    return $GROUP_CACHE{$group_or_name};
}

sub point2hex {
    my ( $group_or_name, $point, $conv_form ) = @_;
    my $group = _get_cached_group($group_or_name);

    my $ctx = BN_CTX_new();
    my $ptr =
      _EC_POINT_point2hex( _ptr($group), _ptr($point), $conv_form, _ptr($ctx) );
    return _string_from_ptr($ptr);
}

sub hex2point {
    my ( $group_or_name, $hex ) = @_;
    my $group = _get_cached_group($group_or_name);
    my $ctx   = BN_CTX_new();
    my $point = EC_POINT_new($group);
    _EC_POINT_hex2point( _ptr($group), $hex, _ptr($point), _ptr($ctx) );
    return $point;
}

sub hex2bn {
    return _hex2bn(@_);
}

sub BN_one {
    _BN_one( _ptr( $_[0] ) );
    return $_[0];
}

sub BN_zero {
    _BN_zero( _ptr( $_[0] ) );
    return $_[0];
}

sub mul_ec_point {
    my ( $group_or_name, $x, $Q, $y ) = @_;
    my $group = _get_cached_group($group_or_name);
    my $ctx   = BN_CTX_new();
    my $P     = EC_POINT_new($group);
    EC_POINT_mul( $group, $P, $x, $Q, $y, $ctx );
    return $P;
}

sub EC_POINT_copy {
    return _EC_POINT_copy( map { _ptr($_) } @_ );
}

sub clear_cofactor {
    my ( $group, $P, $Q, $ctx ) = @_;
    my $cofactor = BN_new();
    EC_GROUP_get_cofactor( $group, $cofactor, $ctx );
    if ( BN_is_one($cofactor) || BN_is_zero($cofactor) ) {
        EC_POINT_copy( $P, $Q );
    }
    else {
        EC_POINT_mul( $group, $P, undef, $Q, $cofactor, $ctx );
    }
    return 1;
}

sub gen_ec_point {
    my ( $group, $x, $y, $clear_cofactor_flag ) = @_;
    my $ctx = BN_CTX_new();
    my $Q   = EC_POINT_new($group);
    EC_POINT_set_affine_coordinates( $group, $Q, $x, $y, $ctx );
    if ($clear_cofactor_flag) {
        my $P = EC_POINT_new($group);
        clear_cofactor( $group, $P, $Q, $ctx );
        $Q = $P;
    }
    return $Q;
}

sub sgn0_m_eq_1 {
    return _sgn0_m_eq_1( _ptr( $_[0] ) );
}

sub CMOV {
    return _CMOV( _ptr( $_[0] ), _ptr( $_[1] ), $_[2] );
}

sub calc_c1_c2_for_sswu {
    return _calc_c1_c2_for_sswu( map { _ptr($_) } @_ );
}

sub map_to_curve_sswu_straight_line {
    return _map_to_curve_sswu_straight_line( map { _ptr($_) } @_ );
}

sub map_to_curve_sswu_not_straight_line {
    return _map_to_curve_sswu_not_straight_line( map { _ptr($_) } @_ );
}

sub bn_mod_sqrt { _bn_mod_sqrt( _ptr( $_[0] ), _ptr( $_[1] ) ) }

sub read_key {
    my $ptr = _read_key( _ptr( $_[0] ) );
    return _string_from_ptr($ptr);
}

sub read_pubkey {
    my $ptr = _read_pubkey( _ptr( $_[0] ) );
    return _string_from_ptr($ptr);
}

sub read_ec_pubkey {
    my $ptr = _read_ec_pubkey( _ptr( $_[0] ), $_[1] );
    return _string_from_ptr($ptr);
}

sub get_pkey_bn_param {
    return _get_pkey_bn_param( _ptr( $_[0] ), $_[1] );
}

sub get_pkey_utf8_string_param {
    my $ptr = _get_pkey_utf8_string_param( _ptr( $_[0] ), $_[1] );
    return _string_from_ptr($ptr);
}

sub export_rsa_pubkey {
    return _export_rsa_pubkey( _ptr( $_[0] ) );
}

sub gen_ec_key {
    return _gen_ec_key( $_[0], $_[1] // '' );
}

sub export_ec_pubkey {
    return _export_ec_pubkey( _ptr( $_[0] ) );
}

sub write_key_to_der {
    return _write_key_to_der( $_[0], _ptr( $_[1] ) );
}

sub write_key_to_pem {
    return _write_key_to_pem( $_[0], _ptr( $_[1] ) );
}

sub write_pubkey_to_der {
    return _write_pubkey_to_der( $_[0], _ptr( $_[1] ) );
}

sub write_pubkey_to_pem {
    return _write_pubkey_to_pem( $_[0], _ptr( $_[1] ) );
}

sub print_pkey_gettable_params {
    return _print_pkey_gettable_params( _ptr( $_[0] ) );
}

sub EC_GROUP_get0_order {
    return _EC_GROUP_get0_order( _ptr( $_[0] ) );
}

sub EC_GROUP_get_order {
    return _EC_GROUP_get_order( map { _ptr($_) } @_ );
}

sub EC_GROUP_get_degree {
    return _EC_GROUP_get_degree( map { _ptr($_) } @_ );
}

sub EC_GROUP_get_cofactor {
    return _EC_GROUP_get_cofactor( map { _ptr($_) } @_ );
}

sub EC_GROUP_get_curve_name {
    return _EC_GROUP_get_curve_name( _ptr( $_[0] ) );
}

sub EC_GROUP_get_curve {
    return _EC_GROUP_get_curve( map { _ptr($_) } @_ );
}

sub EC_POINT_new {
    return _EC_POINT_new( _ptr( $_[0] ) );
}

sub EC_POINT_is_at_infinity {
    return _EC_POINT_is_at_infinity( map { _ptr($_) } @_ );
}

sub EC_POINT_is_on_curve {
    return _EC_POINT_is_on_curve( map { _ptr($_) } @_ );
}

sub EC_POINT_mul {
    return _EC_POINT_mul( map { _ptr($_) } @_ );
}

sub EC_POINT_invert {
    return _EC_POINT_invert( map { _ptr($_) } @_ );
}

sub EC_POINT_add {
    return _EC_POINT_add( map { _ptr($_) } @_ );
}

sub EC_POINT_set_affine_coordinates {
    return _EC_POINT_set_affine_coordinates( map { _ptr($_) } @_ );
}

sub EC_POINT_get_affine_coordinates {
    return _EC_POINT_get_affine_coordinates( map { _ptr($_) } @_ );
}

sub EC_POINT_point2hex {
    my $ptr =
      _EC_POINT_point2hex( _ptr( $_[0] ), _ptr( $_[1] ), $_[2], _ptr( $_[3] ) );
    return _string_from_ptr($ptr);
}

sub EVP_PKEY_get1_EC_KEY {
    return _EVP_PKEY_get1_EC_KEY( _ptr( $_[0] ) );
}

sub ecdh {
    my $len = 0;
    my $ptr = _ecdh( _ptr( $_[0] ), _ptr( $_[1] ), \$len );
    return _bytes_from_ptr( $ptr, $len );
}

sub hkdf_main {
    my ( $mode, $digest_name, $ikm, $salt, $info, $okm_len ) = @_;
    $ikm  //= '';
    $salt //= '';
    $info //= '';
    my $ptr;
    my $len = _hkdf(
        $mode, $digest_name,  $ikm,  length($ikm), $salt, length($salt),
        $info, length($info), \$ptr, $okm_len
    );
    return _bytes_from_ptr( $ptr, $len );
}

sub hmac {
    my ( $digest_name, $key, $msg ) = @_;
    $key //= '';
    $msg //= '';
    my $ptr;
    my $len =
      _hmac( $digest_name, $key, length($key), $msg, length($msg), \$ptr );
    return _bytes_from_ptr( $ptr, $len );
}

sub aes_cmac {
    my ( $cipher_name, $key, $msg ) = @_;
    $key //= '';
    $msg //= '';
    my $len = 0;
    my $ptr =
      _aes_cmac( $cipher_name, $key, length($key), $msg, length($msg), \$len );
    return _bytes_from_ptr( $ptr, $len );
}

sub pkcs12_key_gen {
    my ( $password, $salt, $id, $iteration, $digest_name ) = @_;
    $password //= '';
    $salt     //= '';
    my $len = 0;
    my $ptr =
      _pkcs12_key_gen( $password, length($password), $salt, length($salt), $id,
        $iteration, $digest_name, \$len );
    return _bytes_from_ptr( $ptr, $len );
}

sub pkcs5_pbkdf2_hmac {
    my ( $password, $salt, $iteration, $digest_name ) = @_;
    $password //= '';
    $salt     //= '';
    my $len = 0;
    my $ptr =
      _pkcs5_pbkdf2_hmac( $password, length($password), $salt, length($salt),
        $iteration, $digest_name, \$len );
    return _bytes_from_ptr( $ptr, $len );
}

sub digest_array {
    my ( $digest_name, $arr ) = @_;
    my $digest = EVP_get_digestbyname($digest_name);
    my $ctx    = EVP_MD_CTX_new();
    EVP_DigestInit_ex2( $ctx, $digest, undef );
    for my $msg ( @{$arr} ) {
        $msg //= '';
        EVP_DigestUpdate( $ctx, $msg, length($msg) );
    }
    my $out_len = EVP_MD_get_size($digest);
    my $out     = "\0" x $out_len;
    my $got     = $out_len;
    EVP_DigestFinal_ex( $ctx, scalar_to_pointer($out), \$got );
    EVP_MD_CTX_free($ctx);
    return substr( $out, 0, $got );
}

sub ecdsa_sign {
    my ( $priv_key, $digest_name, $msg ) = @_;
    $msg //= '';
    my $ptr;
    my $len =
      _ecdsa_sign( _ptr($priv_key), $digest_name, $msg, length($msg), \$ptr );
    return _bytes_from_ptr( $ptr, $len );
}

sub BN_bn2bin {
    my ($bn) = @_;
    my $ptr;
    my $len = _BN_bn2bin( _ptr($bn), \$ptr );
    return _bytes_from_ptr( $ptr, $len );
}

sub ecdsa_verify {
    my ( $pub_key, $digest_name, $msg, $sig ) = @_;
    $msg //= '';
    $sig //= '';
    return _ecdsa_verify( _ptr($pub_key), $digest_name, $msg, length($msg),
        $sig, length($sig) );
}

sub symmetric_encrypt {
    my ( $cipher_name, $plaintext, $key, $iv ) = @_;
    $plaintext //= '';
    $key       //= '';
    $iv        //= '';
    my $ptr;
    my $len =
      _symmetric_cipher( $cipher_name, $plaintext, length($plaintext), $key,
        $iv, length($iv), \$ptr, 1 );
    return _bytes_from_ptr( $ptr, $len );
}

sub symmetric_decrypt {
    my ( $cipher_name, $ciphertext, $key, $iv ) = @_;
    $ciphertext //= '';
    $key        //= '';
    $iv         //= '';
    my $ptr;
    my $len =
      _symmetric_cipher( $cipher_name, $ciphertext, length($ciphertext), $key,
        $iv, length($iv), \$ptr, 0 );
    return _bytes_from_ptr( $ptr, $len );
}

sub aead_encrypt {
    my ( $cipher_name, $plaintext, $aad, $key, $iv, $tag_len ) = @_;
    $plaintext //= '';
    $aad       //= '';
    $key       //= '';
    $iv        //= '';
    my ( $ciphertext, $tag );
    my $ciphertext_len = _aead_encrypt(
        $cipher_name, $plaintext, length($plaintext), $aad,
        length($aad), $key,       $iv,                length($iv),
        \$ciphertext, \$tag,      $tag_len
    );
    return [
        _bytes_from_ptr( $ciphertext, $ciphertext_len ),
        _bytes_from_ptr( $tag,        $tag_len )
    ];
}

sub aead_decrypt {
    my ( $cipher_name, $ciphertext, $aad, $tag, $key, $iv ) = @_;
    $ciphertext //= '';
    $aad        //= '';
    $tag        //= '';
    $key        //= '';
    $iv         //= '';
    my $ptr;
    my $len = _aead_decrypt(
        $cipher_name, $ciphertext, length($ciphertext), $aad,
        length($aad), $tag,        length($tag),        $key,
        $iv,          length($iv), \$ptr
    );
    return $len > 0 ? _bytes_from_ptr( $ptr, $len ) : undef;
}

sub get_pkey_octet_string_param {
    my ( $pkey, $param_name ) = @_;
    my $ptr;
    my $len = _get_pkey_octet_string_param( _ptr($pkey), $param_name, \$ptr );
    return _bytes_from_ptr( $ptr, $len );
}

sub rsa_oaep_encrypt {
    my ( $digest_name, $pub, $plaintext ) = @_;
    $plaintext //= '';
    my $ptr;
    my $len = _rsa_oaep_encrypt( $digest_name, _ptr($pub), $plaintext,
        length($plaintext), \$ptr );
    return _bytes_from_ptr( $ptr, $len );
}

sub rsa_oaep_decrypt {
    my ( $digest_name, $priv, $ciphertext ) = @_;
    $ciphertext //= '';
    my $ptr;
    my $len = _rsa_oaep_decrypt( $digest_name, _ptr($priv), $ciphertext,
        length($ciphertext), \$ptr );
    return _bytes_from_ptr( $ptr, $len );
}

sub digest {
    my ( $digest_name, @arr ) = @_;
    return digest_array( $digest_name, \@arr );
}

sub hkdf {

    # define EVP_KDF_HKDF_MODE_EXTRACT_AND_EXPAND  0
    # define EVP_KDF_HKDF_MODE_EXTRACT_ONLY        1
    # define EVP_KDF_HKDF_MODE_EXPAND_ONLY         2
    my ( $digest_name, $k, $salt, $info, $len ) = @_;
    return hkdf_main( 0, $digest_name, $k, $salt, $info, $len );
}

sub hkdf_extract {
    my ( $digest_name, $k, $salt, $info, $len ) = @_;
    return hkdf_main( 1, $digest_name, $k, $salt, $info, $len );
}

sub hkdf_expand {
    my ( $digest_name, $k, $salt, $info, $len ) = @_;
    return hkdf_main( 2, $digest_name, $k, $salt, $info, $len );
}

sub scrypt {
    my ( $password, $salt, $n, $r, $p, $len, $maxmem ) = @_;
    $password //= '';
    $salt     //= '';
    $n        //= 32768;
    $r        //= 8;
    $p        //= 1;
    $len      //= 64;
    $maxmem   //= 0;
    my $ptr;
    my $res_len =
      _scrypt( $password, length($password), $salt, length($salt), $n, $r, $p,
        $maxmem, \$ptr, $len );

    if ( $res_len < 0 ) {
        croak "scrypt failed";
    }
    return _bytes_from_ptr( $ptr, $res_len );
}

sub sn_point2hex {
    my ( $group_name, $point, $point_compress_t ) = @_;
    $point_compress_t //= 4;

    my $ec_params_r = get_ec_params($group_name);
    my $point_hex =
      EC_POINT_point2hex( $ec_params_r->{group}, $point, $point_compress_t,
        $ec_params_r->{ctx} );
    return $point_hex;
}

sub is_bn {
    my ($val) = @_;
    return 0 unless defined $val;
    return 1 if ref($val);
    return ( $val =~ /^\d+$/ && $val > 100000 );
}

sub random_bn {
    my ($Nn) = @_;

    my $random_bn = BN_new();

    if ( is_bn($Nn) ) {
        BN_rand_range( $random_bn, $Nn );
    }
    elsif ( $Nn =~ /^\d+$/ ) {

        my $range_hex = join( "", ('ff') x $Nn );

        my $range = BN_new();
        BN_hex2bn( $range, $range_hex );

        BN_rand_range( $random_bn, $range );
    }

    return $random_bn;
}

sub i2osp {
    my ( $len, $L ) = @_;

    my $s = pack "C*", $len;
    $s = unpack( "H*", $s );

    my $s_len = length($s);
    my $tmp_l = $L * 2;
    if ( $tmp_l > $s_len ) {
        my $pad_len = $tmp_l - $s_len;
        substr $s, 0, 0, ('0') x $pad_len;
    }

    $s = pack( "H*", $s );

    return $s;
}

sub generate_ec_key {
    my ( $group_name, $priv_hex ) = @_;

    ### generate_ec_key

    my $priv_pkey = gen_ec_key( $group_name, $priv_hex || '' );
    $priv_hex = read_key($priv_pkey);

    my $priv_bn = BN_new();
    BN_hex2bn( $priv_bn, $priv_hex );

    ### $priv_hex

    my $pub_pkey = export_ec_pubkey($priv_pkey);

    ### $pub_pkey

    ### read_pubkey: read_pubkey($pub_pkey)

    my $pub_hex = read_ec_pubkey( $pub_pkey, 1 );

    ### $pub_hex

    my $pub_bin = pack( "H*", $pub_hex );

    my $pub_point = hex2point( $group_name, $pub_hex );

    return {
        name      => $group_name,
        priv_pkey => $priv_pkey,

        #priv_key => $priv_key,
        priv_bn   => $priv_bn,
        pub_pkey  => $pub_pkey,
        pub_point => $pub_point,
        pub_hex   => $pub_hex,
        pub_bin   => $pub_bin,
    };

} ## end sub generate_ec_key

sub get_ec_params {
    my ($group_name) = @_;

    my $nid   = OBJ_sn2nid($group_name);
    my $group = EC_GROUP_new_by_curve_name($nid);
    my $ctx   = BN_CTX_new();

    my $p = BN_new();
    my $a = BN_new();
    my $b = BN_new();
    EC_GROUP_get_curve( $group, $p, $a, $b, $ctx );

    my $degree = EC_GROUP_get_degree($group);

    my $order = BN_new();
    EC_GROUP_get_order( $group, $order, $ctx );

    my $cofactor = BN_new();
    EC_GROUP_get_cofactor( $group, $cofactor, $ctx );

    return {
        nid      => $nid,
        name     => $group_name,
        group    => $group,
        p        => $p,
        a        => $a,
        b        => $b,
        degree   => $degree,
        order    => $order,
        cofactor => $cofactor,
        ctx      => $ctx,
    };
}

sub expand_message_xmd {
    my ( $msg, $DST, $len_in_bytes, $hash_name ) = @_;

    my $h_r = EVP_get_digestbyname($hash_name);

    my $hash_size = EVP_MD_get_size($h_r);

    #my $ell = ceil( $len_in_bytes / $h_r->size() );
    #my $ell = ceil( $len_in_bytes / $hash_size );
    my $ell = ceil( $len_in_bytes / $hash_size );
    return if ( $ell > 255 );

    ### len_in_bytes: $len_in_bytes
    ### md get size : EVP_MD_get_size( $h_r )
    ### ell: $ell

    my $DST_len     = length($DST);
    my $DST_len_hex = pack( "C*", $DST_len );
    my $DST_prime   = $DST . $DST_len_hex;
    ### DST: unpack("H*", $DST)
    ### $DST_len
    ### DST_len_hex: unpack("H*", $DST_len_hex)
    ### DST_prime: unpack("H*", $DST_prime)

    my $rn    = EVP_MD_get_block_size($h_r) * 2;
    my $Z_pad = pack( "H$rn", '00' );

    my $l_i_b_str = pack( "S>", $len_in_bytes );

    my $zero = pack( "H*", '00' );

    my $msg_prime = $Z_pad . $msg . $l_i_b_str . $zero . $DST_prime;
    ### msg_prime: unpack("H*", $msg_prime)

    my $len = pack( "C*", 1 );
    my $b0  = digest( $hash_name, $msg_prime );

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

=pod

=encoding utf8

=head1 NAME

Crypto::Utils::OpenSSL - Base Functions, using the OpenSSL libraries

=head1 SYNOPSIS

    use Crypto::Utils::OpenSSL;


=head1 Methods

=head2 symmetric

=head3 aes_cmac

RFC4493: aes_cmac

    my $mac = aes_cmac($cipher_name, $key, $plaintext)

    my $cipher_name = 'aes-128-cbc'; 
    my $key = pack("H*", '2b7e151628aed2a6abf7158809cf4f3c');
    my $msg_1 = pack("H*", '6bc1bee22e409f96e93d7e117393172a');
    my $mac_1 = aes_cmac($cipher_name, $key, $msg_1);
    print unpack("H*", $mac_1), "\n";

    #$ echo -n '6bc1bee22e409f96e93d7e117393172a' | xxd -r -p | openssl dgst -mac cmac -macopt cipher:aes-128-cbc -macopt hexkey:2b7e151628aed2a6abf7158809cf4f3c 
    #(stdin)= 070a16b46b4d4144f79bdd9dd04a287c

=head3 aead_encrypt
    
    my $r = aead_encrypt($cipher_name, $plaintext, $aad, $key, $iv, $tag_len);
    # $r = [ $ciphertext, $tag ];

=head3 aead decrypt

    my $plaintext = aead_decrypt($cipher_name, $ciphertext, $aad, $tag, $key, $iv);


=head2 pkcs

=head3 pkcs12_key_gen

RFC7292 : PKCS12_key_gen

see also openssl/crypto/pkcs12/p12_key.c

    pkcs12_key_gen($password, $salt, $id, $iteration, $digest_name)

    my $macdata_key = pkcs12_key_gen('123456', pack("H*", 'e241f01650dbeae4'), 3, 2048, 'sha256');
    print unpack("H*", $macdata_key), "\n";

=head3 pkcs5_pbkdf2_hmac

RFC2898 : PBKDF2

see also openssl/crypto/evp/p5_crpt2.c 

    my $k = pkcs5_pbkdf2_hmac($password, $salt, $iteration, $digest_name)

    my $pbkdf2_key = pkcs5_pbkdf2_hmac('123456', pack("H*", 'b698314b0d68bcbd'), 2048, 'sha256');
    print unpack("H*", $pbkdf2_key), "\n";

=head3 scrypt

RFC7914 : Scrypt

    my $key = scrypt($password, $salt, $n, $r, $p, $len, $maxmem)

    my $key = scrypt('password', 'salt', 16384, 8, 1, 64);

=head2 bignum

=head3  random_bn

    my $Nn = 16;
    my $random_bn = random_bn($Nn);
    print BN_bn2hex($random_bn), "\n";

=head2 hash

=head3 digest

    my $dgst = digest($digest_name, $msg);

=head2 ec

=head3  gen_ec_key

    my $priv_pkey = gen_ec_key(group_name, $priv_hex);

=head3 gen_ec_pubkey

    my $pub_pkey = gen_ec_pubkey(group_name, $pub_hex);

=head3 export_ec_pubkey

    my $pub_pkey = export_ec_pubkey($priv_pkey);

=head3 read_ec_pubkey

    my $pub_hex = read_ec_pubkey($pub_pkey, $want_compressed);

=head3  ecdh

    my $z_bin = ecdh($local_priv_pkey, $peer_pub_pkey);

=head2 pkey

=head3 read_key

    my $priv_hex = read_key($priv_pkey);

=head3 read_pubkey

    my $pub_hex = read_pubkey($pub_pkey);

=head3 read_key_from_pem
    
    my $priv_pkey = read_key_from_pem($priv_pem_filename);

=head3 read_pubkey_from_pem
    
    my $pub_pkey = read_pubkey_from_pem($pub_pem_filename);

=head3 read_key_from_der
    
    my $priv_pkey = read_key_from_der($priv_der_filename);

=head3 read_pubkey_from_der
    
    my $pub_pkey = read_pubkey_from_der($pub_der_filename);

=head3 write_key_to_pem

    write_key_to_pem($dst_fname, $priv_pkey);

=head3 write_pubkey_to_pem

    write_key_to_pem($dst_fname, $pub_pkey);

=head3 write_key_to_der

    write_key_to_der($dst_fname, $priv_pkey);

=head3 write_pubkey_to_der

    write_key_to_der($dst_fname, $pub_pkey);

=head3 get_pkey_bn_param

    my $x_bn = get_pkey_bn_param($pkey, $param_name);

=head3 get_pkey_octet_string_param

    my $x_hex = get_pkey_octet_string_param($pkey, $param_name);

=head3 get_pkey_utf8_string_param

    my $s = get_pkey_utf8_string_param($pkey, $param_name);
=head2 expand_message_xmd

  my $s = expand_message_xmd( $msg, $DST, $len_in_bytes, $hash_name );


=cut
