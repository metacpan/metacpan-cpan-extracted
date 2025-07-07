#ABSTRACT: SPAKE2+ protocol
package Crypt::Protocol::SPAKE2Plus;

use strict;
use warnings;

#use bigint;

#use Crypt::Digest qw/digest_data/;
#use Crypt::Mac::HMAC qw/hmac/;

use Crypt::ScryptKDF qw/scrypt_raw/;
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;

our $VERSION=0.03;

#use Smart::Comments;

#use Digest::SHA qw/sha256 hmac_sha256/;

my %CURVE_M_N = (
  'prime256v1' => {
    M => '02886e2f97ace46e55ba9dd7242579f2993b64e16ef3dcab95afd497333d8fa12f',
    N => '03d8bbd6c639c62937b04d997f38c3770719c629d7014d49a24b4f98baa1292b49',
  },
  'secp384r1' => {
    M => '030ff0895ae5ebf6187080a82d82b42e2765e3b2f8749c7e05eba366434b363d3dc36f15314739074d2eb8613fceec2853',
    N => '02c72cf2e390853a1c1c4ad816a62fd15824f56078918f43f922ca21518f9c543bb252c5490214cf9aa3f0baab4b665c10',
  },
  'secp521r1' => {
    M =>
      '02003f06f38131b2ba2600791e82488e8d20ab889af753a41806c5db18d37d85608cfae06b82e4a72cd744c719193562a653ea1f119eef9356907edc9b56979962d7aa',
    N =>
      '0200c7924b9ec017f3094562894336a53c50167ba8c5963876880542bc669e494b2532d76c5b53dfb349fdf69154b9e0048c58a42e8ed04cef052a3bc349d95575cd25',
  },

  'edwards25519' => {
    M => 'd048032c6ea0b6d697ddc2e86bda85a33adac920f1bf18e1b0c6d166a5cecdaf',
    N => 'd3bfb518f44f3430f29d0c92af503865a1ed3281dc69b35dd868ba85f886c4ab',
  },

  'edwards448' => {
    M => 'b6221038a775ecd007a4e4dde39fd76ae91d3cf0cc92be8f0c2fa6d6b66f9a12942f5a92646109152292464f3e63d354701c7848d9fc3b8880',
    N => '6034c65b66e4cd7a49b0edec3e3c9ccc4588afd8cf324e29f0a84a072531c4dbf97ff9af195ed714a689251f08f8e06e2d1f24a0ffc0146600',
  },
);

sub new {
  my ( $class, %opt ) = @_;

  $opt{nil} = '';
  $opt{curve_name} //= 'prime256v1';
  $opt{hash_name}  //= 'SHA256';

  $opt{nid}   //= OBJ_sn2nid( $opt{curve_name} );
  $opt{group} //= Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name( $opt{nid} );
  
  $opt{order} //= Crypt::OpenSSL::Bignum->new();
  $opt{ctx} = Crypt::OpenSSL::Bignum::CTX->new();
  Crypt::OpenSSL::EC::EC_GROUP::get_order($opt{group}, $opt{order}, $opt{ctx});


  $opt{kdf} //= sub {
    my ( $Ka, $salt, $info, $dst_len ) = @_;

    hkdf( $opt{hash_name}, $Ka, $salt, $info, $dst_len );
  };

  $opt{mac} //= sub {
    my ( $key, $data ) = @_;

    #$hmac_raw  = hmac('SHA256', $key, 'data buffer');
    hmac( $opt{hash_name}, $key, $data );
  };

  $opt{pbkdf} //= sub {
    my ( $key, @args ) = @_;

    #scrypt_raw($password, $salt, $N, $r, $p, $len);
    scrypt_raw( $key, @args );
  };

  bless \%opt, $class;
} ## end sub new

sub init_M_or_N {

  #label: M/N
  my ( $self, $label, $X ) = @_;
  $X //= $CURVE_M_N{ $self->{curve_name} }{$label};

  $self->{$label} = hex2point( $self->{curve_name}, $X );
  return $self->{$label};
}

sub encode_ec_point {
  my ( $self, $point ) = @_;

  my $hex = point2hex( $self->{curve_name}, $point, 4 );

  my $s = pack( "H*", $hex );
  return $s;
}

sub concat_data {
  my ( $self, @data ) = @_;
  my $s = join(
    '',
    map {
      $_ //= $self->{nil};
      my $len = length( $_ );
      $len = pack 'S<4', $len;
      $len, $_;
    } @data
  );
  return $s;
}

sub bmod_w0_w1 {

  #w0 = w0s mod p
  #w1 = w1s mod p

  my ( $self, $w ) = @_;

  my $ctx = Crypt::OpenSSL::Bignum::CTX->new();
  my $out = Crypt::OpenSSL::Bignum->new_from_hex('0');
  $out = $w->mod( $self->{order}, $ctx );

  return $out;
}

sub bmod_w0_w1_alt {

  #w0 = [ w0s mod (p-1) ]  + 1
  #w1 = [ w1s mod (p-1) ]  + 1

  my ( $self, $w ) = @_;

  my $ctx = Crypt::OpenSSL::Bignum::CTX->new();
  my $one = Crypt::OpenSSL::Bignum->one();

  my $out   = Crypt::OpenSSL::Bignum->new_from_hex('0');
  $out = $self->{order}->sub( $one );
  $out = $w->mod( $out, $ctx );
  $out = $out->add( $one );

  return $out;
}

sub calc_w0_w1 {

  #w0s || w1s = PBKDF(len(pw) || pw || len(A) || A || len(B) || B)
  #len(A) = len(B) = 0, w0s || w1s = PBKDF(pw)
  my ( $self, $bmod_w0_w1_sub, $pw, $A, $B, @pbkdf_args ) = @_;

  my $s = $pw;
  $s = $self->concat_data( $pw, $A, $B ) if ( ( defined $A and length( $A ) > 0 ) or ( defined $B and length( $B ) > 0 ) );

  my $okm = $self->{pbkdf}->( $s, @pbkdf_args );

  my ( $w0s, $w1s ) = $self->split_key( $okm );

  my $w0_bn = hex2bn( unpack( "H*", $w0s ) );
  my $w0    = $bmod_w0_w1_sub->( $self, $w0_bn );

  my $w1_bn = hex2bn( unpack( "H*", $w1s ) );
  my $w1    = $bmod_w0_w1_sub->( $self, $w1_bn );

  return ( $w0, $w1 );
} ## end sub calc_w0_w1

sub calc_L {

  # A, B: w0, w1, L = w1*P
  my ( $self, $w1_bn ) = @_;

  my $zero = Crypt::OpenSSL::Bignum->new_from_hex( '0' );
  my $temp = Crypt::OpenSSL::EC::EC_POINT::new( $self->{group} );
  my $L    = mul_ec_point( $self->{curve_name}, $w1_bn, $temp, $zero );
  return $L;
}

sub random_le_p {

  # G has order p*h
  my ( $self ) = @_;

  #my $p        = $self->{curve_hr}->{n};           #order of P
  #my $r        = Crypt::Perl::Math::randint( $p );
  #my $random_bn = Crypt::OpenSSL::Bignum->rand_range($range);
  my $r;
  return $r;
}

sub A_calc_X {

# A : X = x*P + w0*M
  my ( $self, $w0, $x ) = @_;
  my $X = mul_ec_point( $self->{curve_name}, $x, $self->{M}, $w0 );
  return $X;
}

sub B_calc_Y {

# B : Y = y*P + w0*N
  my ( $self, $w0, $y ) = @_;
  my $Y = mul_ec_point( $self->{curve_name}, $y, $self->{N}, $w0 );
  return $Y;
}

sub is_X_or_Y_suitable {
  my ( $self, $U ) = @_;
  my $UU;

  #my $UU = $U->multiply( $self->{curve_hr}->{h} );
  #return if ( $UU->is_infinity() );
  return 1;
}

sub A_calc_ZV {

  # A: Z = h*x*(Y - w0*N), V = h*w1*(Y - w0*N)
  my ( $self, $w0, $w1, $x, $Y ) = @_;

  #return unless ( $self->is_X_or_Y_suitable( $Y ) );

  my $zero = Crypt::OpenSSL::Bignum->new_from_hex( '0' );
  my $ctx  = Crypt::OpenSSL::Bignum::CTX->new();

  my $temp = mul_ec_point( $self->{curve_name}, $zero, $self->{N}, $w0 );
  EC_POINT_invert( $self->{group}, $temp, $ctx );
  EC_POINT_add( $self->{group}, $temp, $temp, $Y, $ctx );

  my $Z = mul_ec_point( $self->{curve_name}, $zero, $temp, $x );
  clear_cofactor( $self->{group}, $Z, $Z, $ctx );

  my $V = mul_ec_point( $self->{curve_name}, $zero, $temp, $w1 );
  clear_cofactor( $self->{group}, $V, $V, $ctx );

  return ( $Z, $V );
} ## end sub A_calc_ZV

sub B_calc_ZV {

  # B: Z = h*y*(X - w0*M), V = h*y*L
  my ( $self, $w0, $L, $y, $X ) = @_;

  #return unless ( $self->is_X_or_Y_suitable( $X ) );

  my $zero = Crypt::OpenSSL::Bignum->new_from_hex( '0' );
  my $ctx  = Crypt::OpenSSL::Bignum::CTX->new();

  my $temp = mul_ec_point( $self->{curve_name}, $zero, $self->{M}, $w0 );
  EC_POINT_invert( $self->{group}, $temp, $ctx );
  EC_POINT_add( $self->{group}, $temp, $temp, $X, $ctx );

  my $Z = mul_ec_point( $self->{curve_name}, $zero, $temp, $y );
  clear_cofactor( $self->{group}, $Z, $Z, $ctx );

  my $V = mul_ec_point( $self->{curve_name}, $zero, $L, $y );
  clear_cofactor( $self->{group}, $V, $V, $ctx );

  return ( $Z, $V );
} ## end sub B_calc_ZV

sub generate_TT {
  my ( $self, $Context, $A, $B, $X, $Y, $Z, $V, $w0 ) = @_;

  my @points = map { pack( "H*", point2hex( $self->{curve_name}, $_, 4 ) ) } ( $self->{M}, $self->{N}, $X, $Y, $Z, $V );
  my $TT     = $self->concat_data( $Context, $A, $B, @points, pack( "H*", $w0->to_hex() ) );

  return $TT;
}

sub generate_TT_alt {
  my ( $self, $X, $Y, $Z, $V, $w0 ) = @_;

  my @points = map { pack( "H*", point2hex( $self->{curve_name}, $_, 4 ) ) } ( $X, $Y, $Z, $V );
  my $TT     = $self->concat_data( @points, pack( "H*", $w0->to_hex() ) );

  return $TT;
}

sub calc_Ka_and_Ke {

  #Ka || Ke = Hash(TT)
  my ( $self, $TT ) = @_;
  my $TT_digest = digest( $self->{hash_name}, $TT );
  my ( $Ka, $Ke ) = $self->split_key( $TT_digest );

  return ( $Ka, $Ke );
}

sub calc_KcA_and_KcB {

  #KcA || KcB = KDF(nil, Ka, "ConfirmationKeys" || aad)
  my ( $self, $Ka, $kdf_dst_len, $aad ) = @_;

  $kdf_dst_len //= EVP_MD_get_size( EVP_get_digestbyname( $self->{hash_name} ) );

  $aad //= '';

  my $Kc = $self->{kdf}->( $Ka, '', "ConfirmationKeys" . $aad, $kdf_dst_len );
  my ( $KcA, $KcB ) = $self->split_key( $Kc );
  return ( $KcA, $KcB );
}

sub A_calc_MacA {
  ### A_calc_MacA

  #cA = MAC(KcA, ...)
  my ( $self, $KcA, $Y ) = @_;
  return $self->{mac}->( $KcA, $Y );
}

sub B_calc_MacB {
  ### B_calc_MacB

  #cB = MAC(KcB, ...)
  my ( $self, $KcB, $X ) = @_;
  return $self->{mac}->( $KcB, $X );
}

sub split_key {
  my ( $self, $k ) = @_;
  return unless ( defined $k );

  my $len = length( $k );
  my $ka  = substr $k, 0, $len / 2;
  my $kb  = substr $k, $len / 2;

  return ( $ka, $kb );
}

1;
