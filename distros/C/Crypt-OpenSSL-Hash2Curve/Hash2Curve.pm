package Crypt::OpenSSL::Hash2Curve;

use strict;
use warnings;
use bignum;

use Carp;

require Exporter;
use AutoLoader;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::Base::Func;
use Math::BigInt;
use POSIX;
#use Data::Dump qw/dump/;
#use Smart::Comments;

our $VERSION = '0.031';

our @ISA = qw(Exporter);

our @EXPORT = qw(
  sgn0_m_eq_1
  clear_cofactor
  CMOV

  calc_c1_c2_for_sswu
  map_to_curve_sswu_not_straight_line
  map_to_curve_sswu_straight_line

  sn2z
  sn2k_m
  get_hash2curve_params
  expand_message_xmd
  hash_to_field
  map_to_curve
  encode_to_curve
  hash_to_curve
);

our @EXPORT_OK = @EXPORT;


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

    my $ec_params_r = get_ec_params($group_name);

    $ec_params_r->{h2f} = $H2C_CNF{$group_name}{h2f};

    if($type){
        my $z = sn2z( $group_name, $type );

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
  my @res = hash_to_field( $msg, $count, $DST, $h2c_r->{p}, $h2c_r->{h2f}{m}, $h2c_r->{h2f}{k}, $hash_name, $expand_message_func );

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
  my @res = hash_to_field( $msg, $count, $DST, $h2c_r->{p}, $h2c_r->{h2f}{m}, $h2c_r->{h2f}{k}, $hash_name, $expand_message_func );

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

  my $Q = Crypt::OpenSSL::EC::EC_POINT::new( $params_ref->{group} );
  Crypt::OpenSSL::EC::EC_POINT::new( $params_ref->{group} );
  EC_POINT_set_affine_coordinates( $params_ref->{group}, $Q, $x, $y, $params_ref->{ctx} );

  return $Q unless ( $clear_cofactor_flag );

  my $P = Crypt::OpenSSL::EC::EC_POINT::new( $params_ref->{group} );
  clear_cofactor( $params_ref->{group}, $P, $Q, $params_ref->{ctx} );
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

  my $L = Math::BigInt->from_bytes( $p_bin );
  $L = $L->blog( 2 )->bceil()->numify();
  $L = ceil(($L + $k)/8);

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
      ### $elm_offset
      ### $L
      ### tv: unpack("H*", $tv)
      my $tv_bn      = Math::BigInt->from_bytes( $tv );           # from hexadecimal
      $tv_bn->bmod( $p_bigint );

      #my $e_j = $tv_bn->to_hex();
      my $e_j   = $tv_bn->to_bytes();
      ### e_j: unpack("H*", $e_j)
      my $e_j_u = Crypt::OpenSSL::Bignum->new_from_bin( $e_j );

      ### e_j_u hex: $e_j_u->to_hex()
      ### e_j_u decimal: $e_j_u->to_decimal()
      
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
  ### DST: unpack("H*", $DST)
  ### $DST_len
  ### DST_len_hex: unpack("H*", $DST_len_hex)
  ### DST_prime: unpack("H*", $DST_prime)
  
  #my $rn    = $h_r->block_size() * 2;
  my $rn    = EVP_MD_block_size( $h_r ) * 2;
  my $Z_pad = pack( "H$rn", '00' );

  my $l_i_b_str = pack( "S>", $len_in_bytes );

  my $zero = pack( "H*", '00' );

  my $msg_prime = $Z_pad . $msg . $l_i_b_str . $zero . $DST_prime;
  ### msg_prime: unpack("H*", $msg_prime)
  
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

