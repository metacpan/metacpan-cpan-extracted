#ABSTRACT: CPace protocol
package Crypt::Protocol::CPace;

use strict;
use warnings;
use bignum;

require Exporter;

use List::Util qw/min/;
use Crypt::OpenSSL::BaseFunc;

#use Smart::Comments;

our $VERSION=0.014;

our @ISA    = qw(Exporter);
our @EXPORT = qw/
  lexiographically_larger
  ocat
  generator_string
  prefix_free_cat
  prepend_len
  calculate_generator
  sample_scalar
  scalar_mult
  scalar_mult_vfy
  prepare_send_msg
  parse_recv_msg
  prepare_ISK
  /;

our @EXPORT_OK = @EXPORT;

sub ocat {
  my ( $bytes1, $bytes2 ) = @_;
  return lexiographically_larger( $bytes1, $bytes2 ) ? $bytes1 . $bytes2 : $bytes2 . $bytes1;
}

sub lexiographically_larger {
  my ( $bytes1, $bytes2 ) = @_;
  my $min_len = min( length( $bytes1 ), length( $bytes2 ) );

  for my $m ( 0 .. $min_len - 1 ) {
    my $m1 = substr $bytes1, $m, 1;
    my $m2 = substr $bytes2, $m, 1;

    my $c = $m1 cmp $m2;

    return 1 if ( $c > 0 );
    return 0 if ( $c < 0 );
  }
  my $larger = length( $bytes1 ) > length( $bytes2 ) ? 1 : 0;
  return $larger;
}

sub generator_string {
  my ( $DSI, $PRS, $CI, $sid, $s_in_bytes ) = @_;

  my $Z_pad = '';
  my $rn    = $s_in_bytes - 1 - length( prepend_len( $PRS ) ) - length( prepend_len( $DSI ) );
  $rn *= 2;
  $Z_pad = pack( "H$rn", '00' ) if ( $rn > 0 );

  my $res = prefix_free_cat( $DSI, $PRS, $Z_pad, $CI, $sid );
  return $res;
}

sub prefix_free_cat {
  my @data = @_;
  my $res  = join( "", map { prepend_len( $_ ) } @data );
  return $res;
}

sub prepend_len {
  my ( $data ) = @_;

  my $length_encoded = "";

  my $len = length( $data );
  do {
    if ( $len < 128 ) {
      $length_encoded .= pack( "C*", $len );
    } else {
      my $l = $len & 0x7f;
      $l += 0x80;
      $length_encoded .= pack( "C*", $l );
    }
    $len = int( $len >> 7 );

  } while ( $len > 0 );
  return $length_encoded . $data;
} ## end sub prepend_len

sub calculate_generator {
  my ( $DSI, $PRS, $CI, $sid, $group_name, $type, $hash_name, $expand_message_xmd_func, $clear_cofactor_flag ) = @_;
  my $h_r     = EVP_get_digestbyname( $hash_name );
  my $gen_str = generator_string( $DSI, $PRS, $CI, $sid, EVP_MD_get_block_size( $h_r ) );

  #$DSI= 'QUUX-V01-CS02-with-P256_XMD:SHA-256_SSWU_NU_';
  my ( $G, $params_ref ) =
    encode_to_curve( $gen_str, $DSI, $group_name, $type, $hash_name, $expand_message_xmd_func, $clear_cofactor_flag );
  return ( $G, $params_ref );
}

sub sample_scalar {
  my ( $group, $ctx ) = @_;

  my $order = Crypt::OpenSSL::Bignum->new();
  Crypt::OpenSSL::EC::EC_GROUP::get_order( $group, $order, $ctx );
  my $two = Crypt::OpenSSL::Bignum->new_from_word( 2 );
  $order->sub( $two );

  my $rnd = Crypt::OpenSSL::Bignum->rand_range( $order );
  my $one = Crypt::OpenSSL::Bignum->one;
  $rnd->add( $one );

  return $rnd;
}

sub scalar_mult {
  my ( $group, $G, $rnd, $ctx ) = @_;

  $rnd = sample_scalar( $group, $ctx ) unless ( $rnd );

  my $zero = Crypt::OpenSSL::Bignum->zero;
  my $R    = Crypt::OpenSSL::EC::EC_POINT::new( $group );
  Crypt::OpenSSL::EC::EC_POINT::mul( $group, $R, $zero, $G, $rnd, $ctx );

  return wantarray ? ( $R, $rnd ) : $R;
}

sub scalar_mult_vfy {
  my ( $group, $P, $rnd, $ctx ) = @_;

  return if Crypt::OpenSSL::EC::EC_POINT::is_at_infinity( $group, $P );
  return unless Crypt::OpenSSL::EC::EC_POINT::is_on_curve( $group, $P, $ctx );

  my $zero = Crypt::OpenSSL::Bignum->zero;
  my $R    = Crypt::OpenSSL::EC::EC_POINT::new( $group );
  Crypt::OpenSSL::EC::EC_POINT::mul( $group, $R, $zero, $P, $rnd, $ctx );

  return if Crypt::OpenSSL::EC::EC_POINT::is_at_infinity( $group, $R );
  return unless Crypt::OpenSSL::EC::EC_POINT::is_on_curve( $group, $R, $ctx );

  my $x = Crypt::OpenSSL::Bignum->zero;
  my $y = Crypt::OpenSSL::Bignum->zero;
  EC_POINT_get_affine_coordinates( $group, $R, $x, $y, $ctx );
  return $x;
} ## end sub scalar_mult_vfy

sub prepare_send_msg {
  my ( $group, $G, $rnd, $point_hex_type, $ctx, $AD ) = @_;

  my $point = Crypt::OpenSSL::EC::EC_POINT::new( $group );
  ( $point, $rnd ) = scalar_mult( $group, $G, $rnd, $ctx );

  my $point_hex = Crypt::OpenSSL::EC::EC_POINT::point2hex( $group, $point, $point_hex_type, $ctx );
  my $msg       = prefix_free_cat( pack( "H*", $point_hex ), $AD );

  return ( $msg, $point, $rnd );
}

sub parse_recv_msg {
  my ( $msg_recv ) = @_;

  my @data;
  my $len;
  my $i       = 0;
  my $msg_len = length( $msg_recv );
  while ( $i < $msg_len ) {
    my $main_len = 0;
    while ( 1 ) {
      $len = substr $msg_recv, $i, 1;
      $len = hex( "0x" . unpack( "H*", $len ) );
      if ( $len & 0x80 ) {
        $main_len += $len - 0x80;
      } else {
        $main_len += $len;
        last;
      }
      $i++;
    }

    $i++;
    my $point_bytes = substr $msg_recv, $i, $main_len;

    #my $point_hex = unpack("H*", $point_bytes);
    push @data, $point_bytes;
    $i += $main_len;
  } ## end while ( $i < $msg_len )

  return @data;
} ## end sub parse_recv_msg

sub prepare_ISK {
  my ( $DSI, $sid, $group, $rnd, $msg_send, $msg_recv, $is_initiator, $is_unorder, $hash_name, $ctx ) = @_;

  my @msg_recv_data = parse_recv_msg( $msg_recv );

  my $point_hex  = unpack( "H*", $msg_recv_data[0] );

  #my $point_recv = Crypt::OpenSSL::EC::EC_POINT::new( $group );
  #$point_recv = Crypt::OpenSSL::EC::EC_POINT::hex2point( $group, $point_hex, $point_recv, $ctx );
  my $nid = Crypt::OpenSSL::EC::EC_GROUP::get_curve_name($group);
  my $group_name = OBJ_nid2sn($nid);
  print "nid,", $nid, "group, ", $group_name, ",\n";
  my $point_recv = hex2point($group_name, $point_hex);

  my $K = scalar_mult_vfy( $group, $point_recv, $rnd, $ctx );
  return unless($K);

  my $trans;
  if ( $is_unorder ) {
    $trans = ocat( $msg_send, $msg_recv );
  } else {
    $trans = $is_initiator ? $msg_send . $msg_recv : $msg_recv . $msg_send;
  }

  my $Prepare_ISK = prefix_free_cat( $DSI.'_ISK', $sid, $K->to_bin() ) . $trans;

  #my $md  = EVP_get_digestbyname( $hash_name );
  my $ISK = digest( $hash_name, $Prepare_ISK );

  return $ISK;
} ## end sub prepare_ISK

1;
