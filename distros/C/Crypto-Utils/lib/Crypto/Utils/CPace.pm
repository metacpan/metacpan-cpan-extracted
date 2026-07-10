#ABSTRACT: CPace protocol
package Crypto::Utils::CPace;

use strict;
use warnings;
use bignum;

require Exporter;

use List::Util qw/min/;
use Crypto::Utils::OpenSSL;
use Crypto::Utils::Hash2Curve;

our $VERSION = 0.014;

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
    return lexiographically_larger( $bytes1, $bytes2 )
      ? $bytes1 . $bytes2
      : $bytes2 . $bytes1;
}

sub lexiographically_larger {
    my ( $bytes1, $bytes2 ) = @_;
    my $min_len = min( length($bytes1), length($bytes2) );

    for my $m ( 0 .. $min_len - 1 ) {
        my $m1 = substr $bytes1, $m, 1;
        my $m2 = substr $bytes2, $m, 1;

        my $c = $m1 cmp $m2;

        return 1 if ( $c > 0 );
        return 0 if ( $c < 0 );
    }
    my $larger = length($bytes1) > length($bytes2) ? 1 : 0;
    return $larger;
}

sub generator_string {
    my ( $DSI, $PRS, $CI, $sid, $s_in_bytes ) = @_;

    my $Z_pad = '';
    my $rn =
      $s_in_bytes - 1 -
      length( prepend_len($PRS) ) -
      length( prepend_len($DSI) );
    $rn *= 2;
    $Z_pad = pack( "H$rn", '00' ) if ( $rn > 0 );

    my $res = prefix_free_cat( $DSI, $PRS, $Z_pad, $CI, $sid );
    return $res;
}

sub prefix_free_cat {
    my @data = @_;
    my $res  = join( "", map { prepend_len($_) } @data );
    return $res;
}

sub prepend_len {
    my ($data) = @_;

    my $length_encoded = "";

    my $len = length($data);
    do {
        if ( $len < 128 ) {
            $length_encoded .= pack( "C*", $len );
        }
        else {
            my $l = $len & 0x7f;
            $l += 0x80;
            $length_encoded .= pack( "C*", $l );
        }
        $len = int( $len >> 7 );

    } while ( $len > 0 );
    return $length_encoded . $data;
} ## end sub prepend_len

sub calculate_generator {
    my ( $DSI, $PRS, $CI, $sid, $group_name, $type, $hash_name,
        $expand_message_xmd_func, $clear_cofactor_flag )
      = @_;
    my $hash_r = EVP_get_digestbyname($hash_name);
    my $gen_str =
      generator_string( $DSI, $PRS, $CI, $sid, EVP_MD_get_block_size($hash_r) );

    #$DSI= 'QUUX-V01-CS02-with-P256_XMD:SHA-256_SSWU_NU_';
    my ( $G, $params_ref ) =
      encode_to_curve( $gen_str, $DSI, $group_name, $type, $hash_name,
        $expand_message_xmd_func, $clear_cofactor_flag );
    return ( $G, $params_ref );
}

sub sample_scalar {
    my ( $group, $ctx ) = @_;

    my $order = BN_new();
    EC_GROUP_get_order( $group, $order, $ctx );

    my $two = BN_new();
    BN_hex2bn( $two, "02" );

    BN_sub( $order, $order, $two );

    my $rnd = BN_new();
    BN_rand_range( $rnd, $order );

    my $one = BN_new();
    BN_hex2bn( $one, "01" );
    BN_add( $rnd, $rnd, $one );

    #$rnd->add( $one );

    return $rnd;
}

sub scalar_mult {
    my ( $group, $G, $rnd, $ctx ) = @_;

    $rnd = sample_scalar( $group, $ctx ) unless ($rnd);

    my $zero = BN_new();
    BN_zero($zero);

    my $R = EC_POINT_new($group);
    EC_POINT_mul( $group, $R, $zero, $G, $rnd, $ctx );

    return wantarray ? ( $R, $rnd ) : $R;
}

sub scalar_mult_vfy {
    my ( $group, $P, $rnd, $ctx ) = @_;

    return if EC_POINT_is_at_infinity( $group, $P );
    return unless EC_POINT_is_on_curve( $group, $P, $ctx );

    my $zero = BN_new();
    BN_zero($zero);

    my $R = EC_POINT_new($group);
    EC_POINT_mul( $group, $R, $zero, $P, $rnd, $ctx );

    return if EC_POINT_is_at_infinity( $group, $R );
    return unless EC_POINT_is_on_curve( $group, $R, $ctx );

    my $x = BN_new();
    BN_zero($x);

    my $y = BN_new();
    BN_zero($y);

    EC_POINT_get_affine_coordinates( $group, $R, $x, $y, $ctx );
    return $x;
} ## end sub scalar_mult_vfy

sub prepare_send_msg {
    my ( $group, $G, $rnd, $point_hex_type, $ctx, $AD ) = @_;

    my $point = EC_POINT_new($group);
    ( $point, $rnd ) = scalar_mult( $group, $G, $rnd, $ctx );

    my $point_hex = EC_POINT_point2hex( $group, $point, $point_hex_type, $ctx );
    my $msg       = prefix_free_cat( pack( "H*", $point_hex ), $AD );

    return ( $msg, $point, $rnd );
}

sub parse_recv_msg {
    my ($msg_recv) = @_;

    my @data;
    my $len;
    my $i       = 0;
    my $msg_len = length($msg_recv);
    while ( $i < $msg_len ) {
        my $main_len = 0;
        while (1) {
            $len = substr $msg_recv, $i, 1;
            $len = hex( "0x" . unpack( "H*", $len ) );
            if ( $len & 0x80 ) {
                $main_len += $len - 0x80;
            }
            else {
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
    my (
        $DSI,      $sid,          $group,      $rnd,       $msg_send,
        $msg_recv, $is_initiator, $is_unorder, $hash_name, $ctx
    ) = @_;

    my @msg_recv_data = parse_recv_msg($msg_recv);

    my $point_hex = unpack( "H*", $msg_recv_data[0] );

    my $nid        = EC_GROUP_get_curve_name($group);
    my $group_name = OBJ_nid2sn($nid);

    #print "nid,", $nid, "group, ", $group_name, ",\n";
    my $point_recv = hex2point( $group_name, $point_hex );

    my $K = scalar_mult_vfy( $group, $point_recv, $rnd, $ctx );
    return unless ($K);

    my $trans;
    if ($is_unorder) {
        $trans = ocat( $msg_send, $msg_recv );
    }
    else {
        $trans = $is_initiator ? $msg_send . $msg_recv : $msg_recv . $msg_send;
    }

    my $Prepare_ISK =
      prefix_free_cat( $DSI . '_ISK', $sid, BN_bn2bin($K) ) . $trans;

    #my $md  = EVP_get_digestbyname( $hash_name );
    my $ISK = digest( $hash_name, $Prepare_ISK );

    return $ISK;
} ## end sub prepare_ISK

1;

__END__

=pod

=encoding utf8

=head1 NAME

L<Crypto::Utils::CPace> 

=head2 PROTOCOL

L<https://datatracker.ietf.org/doc/draft-irtf-cfrg-cpace/>

=head2 EXAMPLE

    
    use Crypto::Utils::OpenSSL;
    use Crypto::Utils::CPace;

    # a, b with same info
    my $PRS = 'Password';
    my $sid = pack("H*", "34b36454cab2e7842c389f7d88ecb7df");

    my $DSI = 'CPaceP256_XMD:SHA-256_SSWU_NU_';
    my $CI= "\nAinitiator\nBresponder";
    my $group_name = 'prime256v1';
    my $type = 'sswu';
    my $hash_name = 'SHA256';

    # a, b calculate_generator G
    my ($G, $params_ref) = calculate_generator($DSI, $PRS, $CI, $sid, $group_name, $type, $hash_name, \&expand_message_xmd, 1);
    my ($group, $c1, $c2, $p, $a, $b, $z, $ctx) = @$params_ref;
    my $G_hex = EC_POINT_point2hex($group, $G, 4, $ctx);
    print "G=", $G_hex, "\n\n";

    # a send MSGa
    my $ADa  = "ADa";
    my $ya;
    my $Ya;
    my $MSGa;
    ($MSGa, $Ya, $ya) = prepare_send_msg($group, $G, $ya, 4, $ctx, $ADa);
    print "ya=", BN_bn2hex($ya), "\n";
    print "Ya=", EC_POINT_point2hex($group, $Ya, 4, $ctx), "\n";
    print "MSGa: ", unpack( "H*", $MSGa ), "\n\n";

    # b send Msgb
    my $ADb  = "ADb";
    my $yb;
    my $Yb;
    my $MSGb;
    ($MSGb, $Yb, $yb) = prepare_send_msg($group, $G, $yb, 4, $ctx, $ADb);
    print "yb=", BN_bn2hex($yb), "\n";
    print "Yb=", EC_POINT_point2hex($group, $Yb, 4, $ctx), "\n";
    print "MSGb: ", unpack( "H*", $MSGb ), "\n\n";

    # a recv Msgb, calc ISK
    my $ISKa_order = prepare_ISK($DSI, $sid, $group, $ya, $MSGa, $MSGb, 1, 0, 'SHA256', $ctx);
    print "order isk a: ", unpack("H*", $ISKa_order), "\n";

    my $ISKa_unorder = prepare_ISK($DSI, $sid, $group, $ya, $MSGa, $MSGb, 1, 1, 'SHA256', $ctx);
    print "unorder isk: ", unpack("H*", $ISKa_unorder), "\n\n";

    # b recv Msga, calc ISK
    my $ISKb_order = prepare_ISK($DSI, $sid, $group, $yb, $MSGb, $MSGa, 0, 0, 'SHA256', $ctx);
    print "order isk b: ", unpack("H*", $ISKb_order), "\n";

    my $ISKb_unorder = prepare_ISK($DSI, $sid, $group, $yb, $MSGb, $MSGa, 0, 1, 'SHA256', $ctx);
    print "unorder isk b: ", unpack("H*", $ISKb_unorder), "\n\n";


=head1 FUNCTIONS

=head2 lexiographically_larger

    my $bool = lexiographically_larger($str_a, $str_b);

=head2 ocat

    my $octets = ocat(@items);

=head2 prepend_len

    my $len_prepended = prepend_len($data);

=head2 prefix_free_cat

    my $prefix_free_concat = prefix_free_cat(@items);

=head2 generator_string

    my $gen_str = generator_string($DSI, $PRS, $CI, $sid);

=head2 calculate_generator

    my ($G, $params_ref) = calculate_generator( $DSI, $PRS, $CI, $sid, $group_name, $type, $hash_name, $expand_message_xmd_func, $clear_cofactor_flag );

=head2 prepare_send_msg
    
    my ($msg, $point, $rnd) = prepare_send_msg( $group, $G, $rnd, $point_hex_type, $ctx, $AD);

=head2 parse_recv_msg

    my ($point_bytes, $AD) = parse_recv_msg($msg_recv);

=head2 prepare_ISK

    my $ISK = prepare_ISK( $DSI, $sid, $group, $rnd, $msg_send, $msg_recv, $is_initiator, $is_unorder, $hash_name, $ctx );

=cut
