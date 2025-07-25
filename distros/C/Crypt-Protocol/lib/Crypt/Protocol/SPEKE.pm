#ABSTRACT: SPEKE protocol
#see also https://arxiv.org/pdf/1802.04900
package Crypt::Protocol::SPEKE;

use strict;
use warnings;
use bignum;

require Exporter;

use List::Util qw/min/;
use Crypt::OpenSSL::BaseFunc;
use CBOR::XS qw/encode_cbor decode_cbor/;
use Crypt::Protocol::CPace
  qw/sample_scalar scalar_mult scalar_mult_vfy lexiographically_larger /;

#use Smart::Comments;

our $VERSION = 0.001;

our @ISA    = qw(Exporter);
our @EXPORT = qw/
  prepare_send_msg
  calc_K
  /;

our @EXPORT_OK = @EXPORT;

sub prepare_send_msg {
    my ( $group, $G, $point_hex_type, $ctx, $ID ) = @_;

    my $rnd = sample_scalar($group, $ctx);

    my $point = Crypt::OpenSSL::EC::EC_POINT::new($group);
    ( $point, $rnd ) = scalar_mult( $group, $G, $rnd, $ctx );

    my $point_hex =
      Crypt::OpenSSL::EC::EC_POINT::point2hex( $group, $point, $point_hex_type,
        $ctx );
    my $msg = encode_cbor [ $ID, pack( "H*", $point_hex ) ];

    return ( $msg, $point, $rnd );
}

sub calc_K {
    my ( $group, $rnd, $msg_send, $msg_recv, $hash_name, $ctx ) = @_;

    my $msg_recv_data = decode_cbor $msg_recv;
    my $identity      = $msg_recv_data->[0];
    my $point_hex     = unpack( "H*", $msg_recv_data->[1] );

#my $point_recv = Crypt::OpenSSL::EC::EC_POINT::new( $group );
#$point_recv = Crypt::OpenSSL::EC::EC_POINT::hex2point( $group, $point_hex, $point_recv, $ctx );
    my $nid        = Crypt::OpenSSL::EC::EC_GROUP::get_curve_name($group);
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

    my $Prepare_K = $SID . $Z->to_bin();

    #my $md  = EVP_get_digestbyname( $hash_name );
    my $K = digest( $hash_name, $Prepare_K );

    return $K;
} ## end sub calc_K

1;
