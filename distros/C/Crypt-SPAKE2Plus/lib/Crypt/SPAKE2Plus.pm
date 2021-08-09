#ABSTRACT: SPAKE2+ protocol
package Crypt::SPAKE2Plus;

use strict;
use warnings;
use bigint;

use Crypt::Perl::BigInt;
use Crypt::Perl::ECDSA::EC::Curve;
use Crypt::Perl::ECDSA::EC::DB;
use Crypt::Perl::ECDSA::EncodedPoint;
use Crypt::Perl::ECDSA::EC::Point;
use Crypt::Perl::Math;

use Crypt::KeyDerivation ':all';
use Crypt::Digest qw/digest_data/;
use Crypt::Mac::HMAC qw/hmac/;

use Crypt::ScryptKDF qw/scrypt_raw/;

use Smart::Comments;

#use Crypt::Perl::RNG;
#use Crypt::Perl::ECDSA::PrivateKey;
#use Crypt::Perl::ECDSA::Utils;
#use Digest::SHA qw/sha256 hmac_sha256/;

my %CURVE_M_N = (
  'prime256v1' => {
    M => pack( "H*", '02886e2f97ace46e55ba9dd7242579f2993b64e16ef3dcab95afd497333d8fa12f' ),
    N => pack( "H*", '03d8bbd6c639c62937b04d997f38c3770719c629d7014d49a24b4f98baa1292b49' ),
  },
  'secp384r1' => {
    M => pack( "H*", '030ff0895ae5ebf6187080a82d82b42e2765e3b2f8749c7e05eba366434b363d3dc36f15314739074d2eb8613fceec2853' ),
    N => pack( "H*", '02c72cf2e390853a1c1c4ad816a62fd15824f56078918f43f922ca21518f9c543bb252c5490214cf9aa3f0baab4b665c10' ),
  },
  'secp521r1' => {
    M => pack(
      "H*",
      '02003f06f38131b2ba2600791e82488e8d20ab889af753a41806c5db18d37d85608cfae06b82e4a72cd744c719193562a653ea1f119eef9356907edc9b56979962d7aa'
    ),
    N => pack(
      "H*",
      '0200c7924b9ec017f3094562894336a53c50167ba8c5963876880542bc669e494b2532d76c5b53dfb349fdf69154b9e0048c58a42e8ed04cef052a3bc349d95575cd25'
    ),
  },

  'edwards25519' => {
    M => pack( "H*", 'd048032c6ea0b6d697ddc2e86bda85a33adac920f1bf18e1b0c6d166a5cecdaf' ),
    N => pack( "H*", 'd3bfb518f44f3430f29d0c92af503865a1ed3281dc69b35dd868ba85f886c4ab' ),
  },

  'edwards448' => {
    M => pack(
      'H*', 'b6221038a775ecd007a4e4dde39fd76ae91d3cf0cc92be8f0c2fa6d6b66f9a12942f5a92646109152292464f3e63d354701c7848d9fc3b8880'
    ),
    N => pack(
      'H*', '6034c65b66e4cd7a49b0edec3e3c9ccc4588afd8cf324e29f0a84a072531c4dbf97ff9af195ed714a689251f08f8e06e2d1f24a0ffc0146600'
    ),
  },
);

sub new {
  my ( $class, %opt ) = @_;

  $opt{nil} = '';
  $opt{curve_name} //= 'prime256v1';
  $opt{curve_hr}   //= Crypt::Perl::ECDSA::EC::DB::get_curve_data_by_name( $opt{curve_name} );
  $opt{curve}      //= Crypt::Perl::ECDSA::EC::Curve->new( @{ $opt{curve_hr} }{ 'p', 'a', 'b' } );
  $opt{P}          //= $opt{curve}->decode_point( @{ $opt{curve_hr} }{ 'gx', 'gy' } );
  $opt{hash_name}  //= 'SHA256';

  $opt{kdf} //= sub {
    my ( $Ka, $salt, $dst_len, $info ) = @_;

    #  $okm2 = hkdf($password, $salt, $hash_name, $len, $info);
    hkdf( $Ka, $salt, $opt{hash_name}, $dst_len, $info );
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

  $self->{$label} = $self->decode_ec_point( $X );
  return $self->{$label};
}

sub encode_ec_point {
  my ( $self, $point ) = @_;

  my $biX = $point->get_x()->to_bigint();
  my $biY = $point->get_y()->to_bigint();

  my $key_hex_len = 2 * Crypt::Perl::Math::ceil( $self->{curve}->keylen() / 8 );

  my ( $hx, $hy ) = map { substr( $_->as_hex(), 2 ) } $biX, $biY;
  $_ = sprintf "%0${key_hex_len}s", $_ for ( $hx, $hy );

  my $s = pack( "H*", join( '', '04', $hx, $hy ) );
  return $s;
}

sub decode_ec_point {
  my ( $self, $point_s ) = @_;
  my $point      = Crypt::Perl::ECDSA::EncodedPoint->new( $point_s );
  my $point_un_s = $point->get_uncompressed( $self->{curve_hr} );
  my $len        = ( length( $point_un_s ) - 1 ) / 2;
  my $x          = substr $point_un_s, 1, $len;
  my $y          = substr $point_un_s, $len + 1;

  my $x_int = Crypt::Perl::BigInt->from_hex( unpack( "H*", $x ) );
  my $y_int = Crypt::Perl::BigInt->from_hex( unpack( "H*", $y ) );
  my $x_fe  = $self->{curve}->from_bigint( $x_int );
  my $y_fe  = $self->{curve}->from_bigint( $y_int );

  my $ec_point = Crypt::Perl::ECDSA::EC::Point->new(
    $self->{curve},
    $x_fe, $y_fe,
  );

  return $ec_point;
} ## end sub decode_ec_point

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
  $w->bmod( $self->{curve_hr}->{n} );
}

sub bmod_w0_w1_alt {

  #w0 = [ w0s mod (p-1) ]  + 1
  #w1 = [ w1s mod (p-1) ]  + 1
  my ( $self, $w ) = @_;
  my $m = Math::BigInt->bone( '-' );
  $m->badd( $self->{curve_hr}->{n} );
  $w->bmod( $m )->binc();
}

sub calc_w0_w1 {

  #w0s || w1s = PBKDF(len(pw) || pw || len(A) || A || len(B) || B)
  #len(A) = len(B) = 0, w0s || w1s = PBKDF(pw)
  my ( $self, $bmod_w0_w1_sub, $pw, $A, $B, @pbkdf_args ) = @_;

  my $s = $pw;
  $s = $self->concat_data( $pw, $A, $B ) if ( ( defined $A and length( $A ) > 0 ) or ( defined $B and length( $B ) > 0 ) );

  my $okm = $self->{pbkdf}->( $s, @pbkdf_args );

  my ( $w0s, $w1s ) = $self->split_key( $okm );

  my $w0 = Crypt::Perl::BigInt->from_hex( unpack( "H*", $w0s ) );
  $w0 = $bmod_w0_w1_sub->( $self, $w0 );

  my $w1 = Crypt::Perl::BigInt->from_hex( unpack( "H*", $w1s ) );
  $w1 = $bmod_w0_w1_sub->( $self, $w1 );

  return ( $w0, $w1 );
} ## end sub calc_w0_w1

sub calc_L {

  # A, B: w0, w1, L = w1*P
  #w1: Crypt::Perl::BigInt
  my ( $self, $w1 ) = @_;
  my $L = $self->{P}->multiply( $w1 );
  return $L;
}

sub random_le_p {

  # G has order p*h
  my ( $self ) = @_;
  my $p        = $self->{curve_hr}->{n};           #order of P
  my $r        = Crypt::Perl::Math::randint( $p );
  return $r;
}

sub A_calc_X {

# A : X = x*P + w0*M
  my ( $self, $w0, $x ) = @_;
  my $X = $self->{P}->multiply( $x )->add( $self->{M}->multiply( $w0 ) );
  return $X;
}

sub B_calc_Y {

# B : Y = y*P + w0*N
  my ( $self, $w0, $y ) = @_;
  my $Y = $self->{P}->multiply( $y )->add( $self->{N}->multiply( $w0 ) );
  return $Y;
}

sub is_X_or_Y_suitable {
  my ( $self, $U ) = @_;
  my $UU = $U->multiply( $self->{curve_hr}->{h} );
  return if ( $UU->is_infinity() );
  return 1;
}

sub A_calc_ZV {

  # A: Z = h*x*(Y - w0*N), V = h*w1*(Y - w0*N)
  my ( $self, $w0, $w1, $x, $Y ) = @_;

  return unless ( $self->is_X_or_Y_suitable( $Y ) );

  my $temp = $Y->add( $self->{N}->multiply( $w0 )->negate() )->multiply( $self->{curve_hr}->{h} );  # temp = h*(Y - w0*N)
  my $Z    = $temp->multiply( $x );
  my $V    = $temp->multiply( $w1 );
  return ( $Z, $V );
}

sub B_calc_ZV {

  # B: Z = h*y*(X - w0*M), V = h*y*L
  my ( $self, $w0, $L, $y, $X ) = @_;

  return unless ( $self->is_X_or_Y_suitable( $X ) );

  my $Z = $X->add( $self->{M}->multiply( $w0 )->negate() )->multiply( $y )->multiply( $self->{curve_hr}->{h} );
  my $V = $L->multiply( $y )->multiply( $self->{curve_hr}->{h} );
  return ( $Z, $V );
}

sub generate_TT {
  my ( $self, $Context, $A, $B, $X, $Y, $Z, $V, $w0 ) = @_;

  my @points = map { $self->encode_ec_point( $_ ) } ( $self->{M}, $self->{N}, $X, $Y, $Z, $V );

  my $TT = $self->concat_data( $Context, $A, $B, @points, pack( "H*", $w0->to_hex() ) );
  return $TT;
}

sub generate_TT_alt {
  my ( $self, $X, $Y, $Z, $V, $w0 ) = @_;

  my @points = map { $self->encode_ec_point( $_ ) } ( $X, $Y, $Z, $V );

  my $TT = $self->concat_data( @points, pack( "H*", $w0->to_hex() ) );
  return $TT;
}

sub calc_Ka_and_Ke {

  #Ka || Ke = Hash(TT)
  my ( $self, $TT ) = @_;
  my $TT_digest = digest_data( $self->{hash_name}, $TT );
  my ( $Ka, $Ke ) = $self->split_key( $TT_digest );

  return ( $Ka, $Ke );
}

sub calc_KcA_and_KcB {

  #KcA || KcB = KDF(nil, Ka, "ConfirmationKeys" || aad)
  my ( $self, $Ka, $kdf_dst_len, $aad ) = @_;

  $kdf_dst_len //= Crypt::Digest::hashsize( $self->{hash_name} );
  $aad         //= '';

  my $Kc = $self->{kdf}->( $Ka, '', $kdf_dst_len, "ConfirmationKeys" . $aad );
  my ( $KcA, $KcB ) = $self->split_key( $Kc );
  return ( $KcA, $KcB );
}

sub A_calc_MacA {

  #cA = MAC(KcA, ...)
  my ( $self, $KcA, $Y ) = @_;
  return $self->{mac}->( $KcA, $Y );
}

sub B_calc_MacB {

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
