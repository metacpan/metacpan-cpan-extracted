#ABSTRACT: Oblivious Pseudorandom Functions (OPRFs) using Prime-Order Groups
package Crypto::Utils::OPRF;

use strict;
use warnings;
require Exporter;

use Crypto::Utils::OpenSSL;
use Crypto::Utils::Hash2Curve;

our $VERSION = 0.012;

our @ISA    = qw(Exporter);
our @EXPORT = qw/

  creat_context_string
  derive_key_pair
  blind
  evaluate
  finalize
  /;

our @EXPORT_OK = @EXPORT;

sub creat_context_string {
    my ( $prefix, $mode, $suite_id ) = @_;

    my $s = $prefix . i2osp( $mode, 1 ) . i2osp( $suite_id, 2 );
    return $s;
}

sub derive_key_pair {
    my ( $group_name, $seed, $info, $DST, $hash_name, $expand_message_func ) =
      @_;

    my $ec_params_r = get_ec_params($group_name);

    my $l            = length($info);
    my $derive_input = join( "", $seed, i2osp( $l, 2 ), $info );
    ### derive_input: unpack("H*", $derive_input)

    my $counter = 0;
    my $skS     = 0;
    while ( !$skS ) {
        if ( $counter > 255 ) {
            return;
        }

        my $k = sn2kv( $group_name, 'k' );
        my $m = sn2kv( $group_name, 'm' );

        my $msg = $derive_input . i2osp( $counter, 1 );

        #my $DST = "DeriveKeyPair".$context_string;
        ### msg: unpack("H*", $msg)
        ### DST: unpack("H*", $DST)
        my @skS_arr =
          hash_to_field( $msg, 1, $DST, $ec_params_r->{order}, $m, $k,
            $hash_name, $expand_message_func, );

        $skS = $skS_arr[0][0];
        $counter++;
    }

    my $ec_key_r = generate_ec_key( $group_name, BN_bn2hex($skS) );

    return $ec_key_r;
}

sub blind {
    my ( $input, $blind, $DSI, $group_name, $type, $hash_name,
        $expand_message_func, $clear_cofactor_flag )
      = @_;

    my $ec_params_r = get_ec_params($group_name);

    if ( !$blind ) {
        $blind = BN_new();
        BN_rand_range( $blind, $ec_params_r->{p} );
        return if ( $blind->is_zero );
    }

    my $P = hash_to_curve( $input, $DSI, $group_name, $type, $hash_name,
        $expand_message_func, $clear_cofactor_flag );
    return if ( EC_POINT_is_at_infinity( $ec_params_r->{group}, $P ) );

    my $zero = BN_new();
    BN_zero($zero);

    my $blindedElement = EC_POINT_new( $ec_params_r->{group} );
    EC_POINT_mul( $ec_params_r->{group}, $blindedElement, $zero, $P, $blind,
        $ec_params_r->{ctx} );

    return ( $blind, $blindedElement );
}

sub evaluate {
    my ( $group, $blindedElement, $skS, $ctx ) = @_;

    my $zero = BN_new();
    BN_zero($zero);

    my $evaluationElement = EC_POINT_new($group);
    EC_POINT_mul( $group, $evaluationElement, $zero, $blindedElement, $skS,
        $ctx );
    return $evaluationElement;
}

sub finalize {
    my ( $group, $order, $input, $blind, $evaluationElement, $hash_name, $ctx )
      = @_;

    my $blind_inv = BN_mod_inverse( undef, $blind, $order, $ctx );

    my $unblindedElement =
      evaluate( $group, $evaluationElement, $blind_inv, $ctx );

    my $unblindedElement_hex =
      EC_POINT_point2hex( $group, $unblindedElement, 2, $ctx );
    ### $unblindedElement_hex
    my $unblindedElement_bin = pack( "H*", $unblindedElement_hex );

    my $msg = join( "",
        map { i2osp( length($_), 2 ) . $_ } ( $input, $unblindedElement_bin ) )
      . "Finalize";
    ### msg: unpack("H*", $msg)

    #my $h_r = EVP_get_digestbyname( $hash_name );
    my $dgst = digest( $hash_name, $msg );

    return $dgst;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

L<Crypto::Utils::OPRF> 

=head2 PROTOCOL

L<https://datatracker.ietf.org/doc/draft-irtf-cfrg-voprf/>

=head2 EXAMPLE

    use Crypt::Utils::OpenSSL;
    use Crypt::Utils::OPRF;

    my $prefix         = "VOPRF09-";
    my $mode           = 0x00;
    my $suite_id       = 0x0003;
    my $context_string = creat_context_string( $prefix, $mode, $suite_id );
    my $DSI            = "HashToGroup-" . $context_string;
    my $group_name     = 'prime256v1';
    my $type           = 'sswu';

    my $hash_name           = 'SHA256';
    my $expand_message_func = \&expand_message_xmd;
    my $clear_cofactor_flag = 1;

    my $input = pack( "H*", '00' );

    my $blind_bn = BN_new();
    BN_hex2bn($blind_bn, 'f70cf205f782fa11a0d61b2f5a8a2a1143368327f3077c68a1545e9aafbba6aa');
    my $blindedElement;
    ( $blind, $blindedElement ) = blind( $input, $blind, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );

    my $params_ref = get_ec_params( $group_name );
    my ( $group, $order, $ctx ) = @{$params_ref}{qw/group order ctx/};

    my $bn = EC_POINT_point2hex( $group, $blindedElement, 2, $ctx );
    print "$bn\n";

    my $skS               = BN_new();
    BN_hex2bn($skS, '88a91851d93ab3e4f2636babc60d6ce9d1aee2b86dece13fa8590d955a08d987');
    my $evaluationElement = evaluate( $group, $blindedElement, $skS, $ctx );
    my $bn_ev             = EC_POINT_point2hex( $group, $evaluationElement, 2, $ctx );
    print "$bn_ev\n";

    my $dgst = finalize( $group, $order, $input, $blind, $evaluationElement, $hash_name, $ctx );
    print unpack( "H*", $dgst ), "\n";

=head1 FUNCTION

=head2 creat_context_string

    my $s  = creat_context_string($prefix, $mode, $suite_id);

=head2 derive_key_pair

    my $DST = "DeriveKeyPair".$context_string;
    my $ec_key_r = derive_key_pair($group_name, $seed, $info, $DST, $hash_name, $expand_message_func);

=head2  blind

    my ($blind, $blindedElement) = blind($input, $blind, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag);

=head2 evaluate

    my $evaluationElement = evaluate($group, $blindedElement, $skS, $ctx);

=head2 finalize

    my $output = finalize($group, $order, $input, $blind, $evaluationElement, $hash_name, $ctx); 

=cut
