#ABSTRACT: SPEKE protocol
#see also https://arxiv.org/pdf/1802.04900
package Crypto::Utils::SPEKE;

use strict;
use warnings;
use bignum;

require Exporter;

use List::Util qw/min/;
use Crypto::Utils::OpenSSL;
use Crypto::Utils::Hash2Curve;
use CBOR::XS qw/encode_cbor decode_cbor/;
use Crypto::Utils::CPace
  qw/sample_scalar scalar_mult scalar_mult_vfy lexiographically_larger /;

our $VERSION = 0.001;

our @ISA    = qw(Exporter);
our @EXPORT = qw/
  prepare_send_msg
  calc_K
  /;

our @EXPORT_OK = @EXPORT;

sub prepare_send_msg {
    my ( $group, $G, $point_hex_type, $ctx, $ID ) = @_;

    my $rnd = sample_scalar( $group, $ctx );

    my $point = EC_POINT_new($group);
    ( $point, $rnd ) = scalar_mult( $group, $G, $rnd, $ctx );

    my $point_hex = EC_POINT_point2hex( $group, $point, $point_hex_type, $ctx );
    my $msg       = encode_cbor [ $ID, pack( "H*", $point_hex ) ];

    return ( $msg, $point, $rnd );
}

sub calc_K {
    my ( $group, $rnd, $msg_send, $msg_recv, $hash_name, $ctx ) = @_;

    my $msg_recv_data = decode_cbor $msg_recv;
    my $identity      = $msg_recv_data->[0];
    my $point_hex     = unpack( "H*", $msg_recv_data->[1] );

    my $nid        = EC_GROUP_get_curve_name($group);
    my $group_name = OBJ_nid2sn($nid);

    #print "nid,", $nid, "group, ", $group_name, ",\n";
    my $point_recv = hex2point( $group_name, $point_hex );

    my $Z = scalar_mult_vfy( $group, $point_recv, $rnd, $ctx );
    return unless ($Z);

    my $msg_send_h = digest( $hash_name, $msg_send );
    my $msg_recv_h = digest( $hash_name, $msg_recv );
    my $SID =
      lexiographically_larger( $msg_send_h, $msg_recv_h )
      ? $msg_send_h . $msg_recv_h
      : $msg_recv_h . $msg_send_h;

    my $Prepare_K = $SID . BN_bn2bin($Z);

    #my $md  = EVP_get_digestbyname( $hash_name );
    my $K = digest( $hash_name, $Prepare_K );

    return $K;
} ## end sub calc_K

1;

__END__

=pod

=encoding utf8

=head1 NAME

L<Crypto::Utils::SPEKE> 

=head2 PROTOCOL

L<https://arxiv.org/pdf/1802.04900>

=head2 EXAMPLE


	use Crypto::Utils::OpenSSL;
	use Crypto::Utils::Hash2Curve;
	use Crypto::Utils::SPEKE;

	# a, b with same info
	my $PRS = 'Password';

	my $DSI = 'SPEKEP256_XMD:SHA-256_SSWU_NU_';
	my $group_name = 'prime256v1';
	my $type = 'sswu';
	my $hash_name = 'SHA256';

	# a, b calculate_generator G
	my ($G, $params_ref) = encode_to_curve( $PRS, $DSI, $group_name, $type, $hash_name, \&expand_message_xmd, 1);
	my ($group, $ctx) = @{$params_ref}{qw/group ctx/};
	my $G_hex = EC_POINT_point2hex($group, $G, 4, $ctx);
	print "G=", $G_hex, "\n\n";

	# a send MSGa
	my $IDa  = "IDa";
	my ($MSGa, $X, $x) = prepare_send_msg($group, $G, 4, $ctx, $IDa);
	print "x=", BN_bn2hex($x), "\n";
	print "X=", EC_POINT_point2hex($group, $X, 4, $ctx), "\n";
	print "MSGa: ", unpack( "H*", $MSGa ), "\n\n";

	# b send Msgb
	my $IDb  = "IDb";
	my ($MSGb, $Y, $y) = prepare_send_msg($group, $G,  4, $ctx, $IDb);
	print "y=", BN_bn2hex($y), "\n";
	print "Y=", EC_POINT_point2hex($group, $Y, 4, $ctx), "\n";
	print "MSGb: ", unpack( "H*", $MSGb ), "\n\n";

	# a recv Msgb, calc K
	my $Ka = calc_K($group, $x, $MSGa, $MSGb, 'SHA256', $ctx);
	print "a calc K: ", unpack("H*", $Ka), "\n";

	# b recv Msga, calc K
	my $Kb = calc_K( $group, $y, $MSGb, $MSGa, 'SHA256', $ctx);
	print "b calc K: ", unpack("H*", $Kb), "\n";


=head1 FUNCTION


=head2 prepare_send_msg
    
   my ($msg, $point, $rnd) = prepare_send_msg( $group, $G, $point_hex_type, $ctx, $ID );

=head2 calc_K

   my $K = calc_K( $group, $rnd, $msg_send, $msg_recv, $hash_name, $ctx );

=cut
