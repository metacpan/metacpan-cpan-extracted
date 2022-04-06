#ABSTRACT: Oblivious Pseudorandom Functions (OPRFs) using Prime-Order Groups
package Crypt::OPRF;

use strict;
use warnings;
use bignum;

require Exporter;

#use List::Util qw/min/;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::Hash2Curve;
use Crypt::OpenSSL::Base::Func;

#use Smart::Comments;

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
    my ($prefix, $mode, $suite_id) = @_;

    my $s = $prefix.i2osp($mode, 1).i2osp($suite_id, 2);
    return $s;
}

sub derive_key_pair {
    my ($group_name, $seed, $info, $context_string, $hash_name, $expand_message_func) = @_;

    my $group_params_ref = get_hash2curve_params($group_name);
    my ($group, $c1, $c2, $p, $a, $b, $z, $ctx) = @$group_params_ref;

    my $l = length($info);
    my $derive_input = join("", $seed, i2osp($l, 2), $info);
    ### derive_input: unpack("H*", $derive_input)
    ### p ref: ref($p)

    my $order = Crypt::OpenSSL::Bignum->new();
    Crypt::OpenSSL::EC::EC_GROUP::get_order($group, $order, $ctx);

    my $counter = 0;
    my $skS = 0;
    while(! $skS ){
        if($counter>255){
            return;
        }

        my ($k, $m) = sn2k_m($group_name); 

        my $msg = $derive_input.i2osp($counter, 1); 
        my $DST = "DeriveKeyPair".$context_string;
        ### msg: unpack("H*", $msg)
        ### DST: unpack("H*", $DST)
        my @skS_arr = hash_to_field(
            $msg,
            1, 
            $DST, 
            $order,
            $m, 
            $k, 
            $hash_name, 
            $expand_message_func, 
        );

        $skS = $skS_arr[0][0];
        $counter++;
    }

    ### skS hex: $skS->to_hex()
    ### skS decimal: $skS->to_decimal()

    my $skS_key = Crypt::OpenSSL::EC::EC_KEY::new();
    $skS_key->set_group($group);
    $skS_key->set_private_key($skS);

    my $pkS_point = Crypt::OpenSSL::EC::EC_KEY::get0_public_key($skS_key);
    #my $pkS_key = Crypt::OpenSSL::EC::EC_KEY::new();
    #Crypt::OpenSSL::EC::EC_KEY::set_group($pkS_key, $group);
    #Crypt::OpenSSL::EC::EC_KEY::set_public_key($pkS_key, $pkS_point);

    #return ($skS_key, $pkS_key);
    return ($skS, $pkS_point);
}

sub blind {
    my ($input, $blind, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag) = @_;

    my $group_params_ref = get_hash2curve_params($group_name);
    my ($group, $c1, $c2, $p, $a, $b, $z, $ctx) = @$group_params_ref;

    if(!$blind){
        $blind = Crypt::OpenSSL::Bignum->rand_range( $p );
        return if($blind->is_zero);
    }

    my $P = hash_to_curve( $input, $DSI, $group_name, $type, $hash_name, $expand_message_func, $clear_cofactor_flag );
    return if(Crypt::OpenSSL::EC::EC_POINT::is_at_infinity( $group, $P ));

    my $zero = Crypt::OpenSSL::Bignum->zero;
    my $blindedElement    = Crypt::OpenSSL::EC::EC_POINT::new( $group );
    Crypt::OpenSSL::EC::EC_POINT::mul( $group, $blindedElement, $zero, $P, $blind, $ctx );

    return ($blind, $blindedElement);
}

sub evaluate {
    my ($group, $blindedElement, $skS, $ctx) = @_;
    my $zero = Crypt::OpenSSL::Bignum->zero; 
    my $evaluationElement    = Crypt::OpenSSL::EC::EC_POINT::new( $group );
    Crypt::OpenSSL::EC::EC_POINT::mul( $group, $evaluationElement, $zero, $blindedElement, $skS, $ctx );
    return $evaluationElement;
}

sub finalize {
    my ($group, $order, $input, $blind, $evaluationElement, $hash_name, $ctx) = @_;

    my $blind_inv = $blind->mod_inverse($order, $ctx);

    my $unblindedElement = evaluate($group, $evaluationElement, $blind_inv, $ctx);

    my $unblindedElement_hex = Crypt::OpenSSL::EC::EC_POINT::point2hex($group, $unblindedElement, 2, $ctx);
    ### $unblindedElement_hex
    my $unblindedElement_bin = pack("H*", $unblindedElement_hex);

    my $msg = join("", map { i2osp(length($_), 2).$_ } ($input, $unblindedElement_bin))."Finalize";    
    ### msg: unpack("H*", $msg)

    my $h_r = EVP_get_digestbyname( $hash_name );
    my $dgst        = digest( $h_r, $msg );

    return $dgst;
}

1;
