package Crypt::OpenSSL::Hash2Curve;

use 5.008005;
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

  sgn0_m_eq_1
  calc_c1_c2_for_sswu
  map_to_curve_sswu_not_straight_line
  map_to_curve_sswu_straight_line
  get_hash2curve_params
  map_to_curve
  encode_to_curve
  hash_to_curve
  clear_cofactor
  digest
  hash_to_field
  expand_message_xmd
  sn2z
  hex2point
);

our @EXPORT_OK = @EXPORT;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load( 'Crypt::OpenSSL::Hash2Curve', $VERSION );

our %H2C_CNF = (
  'prime256v1' => {
    'h2f' => {
      k => 0x80,
      m => 1,
    },
    'sswu' => {
      z                 => '-10',
      calc_c1_c2_func   => \&calc_c1_c2_for_sswu,
      map_to_curve_func => \&map_to_curve_sswu_straight_line,
    },
  },
);

sub get_hash2curve_params {
  my ( $group_name, $type ) = @_;

  my $nid   = OBJ_sn2nid( $group_name );
  my $group = Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name( $nid );
  my $ctx   = Crypt::OpenSSL::Bignum::CTX->new();


  my $p = Crypt::OpenSSL::Bignum->new();
  my $a = Crypt::OpenSSL::Bignum->new();
  my $b = Crypt::OpenSSL::Bignum->new();
  EC_GROUP_get_curve( $group, $p, $a, $b, $ctx );

  my $c1;
  my $c2;
  my $z;
  if($type){
      $z = sn2z( $group_name, $type );

      $c1 = Crypt::OpenSSL::Bignum->new();
      $c2 = Crypt::OpenSSL::Bignum->new();
      $H2C_CNF{$group_name}{$type}{calc_c1_c2_func}->( $c1, $c2, $p, $a, $b, $z, $ctx );
  }

  return [ $group, $c1, $c2, $p, $a, $b, $z, $ctx ];
} ## end sub get_hash2curve_params

sub hash_to_curve {
  my ( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag ) = @_;

  my $params_ref = get_hash2curve_params( $group_name, $type );
  my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

  my $count = 2;
  my ( $k, $m ) = sn2k_m( $group_name );
  my @res = hash_to_field( $msg, $count, $DST, $p, $m, $k, $hash_name, $expand_message_func );

  my $u0 = $res[0][0];
  my $Q0 = map_to_curve( $params_ref, $group_name, $type, $u0, $clear_cofactor_flag );

  my $u1 = $res[1][0];
  my $Q1 = map_to_curve( $params_ref, $group_name, $type, $u1, $clear_cofactor_flag );

  my $Q = Crypt::OpenSSL::EC::EC_POINT::new( $group );
  Crypt::OpenSSL::EC::EC_POINT::add( $group, $Q, $Q0, $Q1, $ctx );

  return $Q unless ( $clear_cofactor_flag );

  my $P = Crypt::OpenSSL::EC::EC_POINT::new( $group );
  clear_cofactor( $group, $P, $Q, $ctx );

  return wantarray ? ($P, $params_ref) : $P;
} ## end sub hash_to_curve

sub encode_to_curve {
  my ( $msg, $DST, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag ) = @_;

  my $params_ref = get_hash2curve_params( $group_name, $type );
  my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

  my $count = 1;
  my ( $k, $m ) = sn2k_m( $group_name );
  my @res = hash_to_field( $msg, $count, $DST, $p, $m, $k, $hash_name, $expand_message_func );

  my $u = $res[0][0];
  my $P = map_to_curve( $params_ref, $group_name, $type, $u, $clear_cofactor_flag );
  return wantarray ? ($P, $params_ref) : $P;
}

sub map_to_curve {
  my ( $params_ref, $group_name, $type, $u, $clear_cofactor_flag ) = @_;

  my ( $group, $c1, $c2, $p, $a, $b, $z, $ctx ) = @$params_ref;

  my $x = Crypt::OpenSSL::Bignum->new();
  my $y = Crypt::OpenSSL::Bignum->new();
  $H2C_CNF{$group_name}{$type}{map_to_curve_func}->( $c1, $c2, $p, $a, $b, $z, $u, $x, $y, $ctx );

  my $Q = Crypt::OpenSSL::EC::EC_POINT::new( $group );
  Crypt::OpenSSL::EC::EC_POINT::new( $group );
  EC_POINT_set_affine_coordinates( $group, $Q, $x, $y, $ctx );

  return $Q unless ( $clear_cofactor_flag );

  my $P = Crypt::OpenSSL::EC::EC_POINT::new( $group );
  clear_cofactor( $group, $P, $Q, $ctx );
  return $P;
} ## end sub map_to_curve

sub sn2z {
  my ( $sn, $type ) = @_;
  my $z = Crypt::OpenSSL::Bignum->new_from_decimal( $H2C_CNF{$sn}{$type}{z} );
  return $z;
}

sub sn2k_m {
  my ( $sn ) = @_;
  my $k      = $H2C_CNF{$sn}{h2f}{k};
  my $m      = $H2C_CNF{$sn}{h2f}{m};
  return ( $k, $m );
}

#sub CMOV {
#my ($a, $b, $c) = @_;
#return $b if($c);
#return $a;
#}

sub hash_to_field {
  my ( $msg, $count, $DST, $p, $m, $k, $hash_name, $expand_message_func ) = @_;

  my $p_bin    = $p->to_bin();
  my $p_bigint = Math::BigInt->from_bytes( $p_bin );
  my $L        = scalar $p_bigint->blog( 2 )->bceil()->badd( $k )->bdiv( 8 )->bceil();

  my $len_in_bytes  = $count * $m * $L;
  my $uniform_bytes = $expand_message_func->( $msg, $DST, $len_in_bytes, $hash_name );

  my @res;
  for my $i ( 0 .. $count - 1 ) {
    my @u;
    for my $j ( 0 .. $m - 1 ) {
      my $elm_offset = $L * ( $j + $i * $m );
      my $tv         = substr( $uniform_bytes, $elm_offset, $L );
      my $tv_bn      = Math::BigInt->from_bytes( $tv );           # from hexadecimal
      $tv_bn->bmod( $p_bigint );

      #my $e_j = $tv_bn->to_hex();
      my $e_j   = $tv_bn->to_bytes();
      my $e_j_u = Crypt::OpenSSL::Bignum->new_from_bin( $e_j );
      push @u, $e_j_u;
    }
    push @res, \@u;
  }
  return @res;
} ## end sub hash_to_field

sub expand_message_xmd {
  my ( $msg, $DST, $len_in_bytes, $hash_name ) = @_;

  #my $h_r = Crypt::OpenSSL::EVP::MD->new( $hash_name );
  my $h_r = EVP_get_digestbyname( $hash_name );

  #my $ell = ceil( $len_in_bytes / $h_r->size() );
  my $ell = ceil( $len_in_bytes / EVP_MD_size( $h_r ) );
  return if ( $ell > 255 );

  my $DST_len     = length( $DST );
  my $DST_len_hex = pack( "C*", $DST_len );
  my $DST_prime   = $DST . $DST_len_hex;

  #my $rn    = $h_r->block_size() * 2;
  my $rn    = EVP_MD_block_size( $h_r ) * 2;
  my $Z_pad = pack( "H$rn", '00' );

  my $l_i_b_str = pack( "S>", $len_in_bytes );

  my $zero = pack( "H*", '00' );

  my $msg_prime = $Z_pad . $msg . $l_i_b_str . $zero . $DST_prime;
  my $len       = pack( "C*", 1 );
  my $b0        = digest( $h_r, $msg_prime );

  my $b1 = digest( $h_r, $b0 . $len . $DST_prime );

  #my $b0  = $h_r->digest( $msg_prime );
  #my $b1  = $h_r->digest( $b0 . $len . $DST_prime );

  my $b_prev        = $b1;
  my $uniform_bytes = $b1;
  for my $i ( 2 .. $ell ) {
    my $tmp = ( $b0 ^ $b_prev ) . pack( "C*", $i ) . $DST_prime;
    my $bi  = digest( $h_r, $tmp );
    $uniform_bytes .= $bi;
    $b_prev = $bi;
  }

  my $res = substr( $uniform_bytes, 0, $len_in_bytes );
  return $res;
} ## end sub expand_message_xmd

1;
__END__

