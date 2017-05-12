#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) VIAKLIX_ACCOUNT, VIAKLIX_PASSWORD, VIAKLIX_CARD,"
  . " VIAKLIX_CVV2, VIAKLIX_EXP, VIAKLIX_CARD_NAME, VIAKLIX_CARD_ADDRESS,"
  . " VIAKLIX_CARD_CITY, VIAKLIX_CARD_STATE, VIAKLIX_CARD_ZIP, and VIAKLIX_DO_LIVE ";

plan(
      ( $ENV{"VIAKLIX_ACCOUNT"} && $ENV{"VIAKLIX_PASSWORD"} &&
        $ENV{"VIAKLIX_CARD"} && $ENV{"VIAKLIX_CVV2"} &&
        $ENV{"VIAKLIX_EXP"} && $ENV{"VIAKLIX_CARD_NAME"} &&
        $ENV{"VIAKLIX_CARD_ADDRESS"} && $ENV{"VIAKLIX_CARD_CITY"} &&
        $ENV{"VIAKLIX_CARD_STATE"} && $ENV{"VIAKLIX_CARD_ZIP"} &&
        $ENV{"VIAKLIX_DO_LIVE"}
      )
    ? ( tests => 42 )
    : ( skip_all => $runinfo )
);

my %opts = (
    "debug"                      => 2,
    "default_ssl_user_id"        => $ENV{"VIAKLIX_USERID"},
    "default_ssl_salestax"       => "0.00",
    "default_ssl_customer_code"  => "LIVETESTCUSTOMER",
);

my %content = (
    login          => $ENV{"VIAKLIX_ACCOUNT"},
    password       => $ENV{"VIAKLIX_PASSWORD"},
    action         => "Normal Authorization",
    type           => "CC",
    description    => "Business::OnlinePayment::viaKLIX live test",
    card_number    => $ENV{"VIAKLIX_CARD"},
    cvv2           => $ENV{"VIAKLIX_CVV2"},
    expiration     => $ENV{"VIAKLIX_EXP"},
    amount         => "0.01",
    invoice_number => "LiveTest",
    name           => $ENV{"VIAKLIX_CARD_NAME"},
    address        => $ENV{"VIAKLIX_CARD_ADDRESS"},
    city           => $ENV{"VIAKLIX_CARD_CITY"},
    state          => $ENV{"VIAKLIX_CARD_STATE"},
    zip            => $ENV{"VIAKLIX_CARD_ZIP"},
);

my $credit_amount = 0;

{    # valid card number test
    my $tx = new Business::OnlinePayment( "viaKLIX", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid card_number",
        is_success    => 1,
        result_code   => "0",
        authorization => qr/^\w{6}$/,
        avs_code      => "Y",
        cvv2_response => "M",
        order_number  => qr/^([0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12})$/,
    );
   $credit_amount += $content{amount} if $tx->is_success;
}

{    # invalid card number test

    my $tx = new Business::OnlinePayment( "viaKLIX", %opts );
    $tx->content( %content, card_number => "4111111111111112" );
    tx_check(
        $tx,
        desc          => "invalid card_number",
        is_success    => 0,
        result_code   => 4000,
        authorization => qr/^$/,
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => qr/^$/,
    );
}


{    # avs_code() / AVSZIP and AVSADDR tests

    my $tx = new Business::OnlinePayment( "viaKLIX", %opts );

    $tx->content( %content, "address" => "500 Any street" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=Y",
        is_success    => 1,
        result_code   => "0",
        authorization => qr/^\w{6}$/,
        avs_code      => "Z",
        cvv2_response => "M",
        order_number  => qr/^([0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12})$/,
    );
    $credit_amount += $content{amount} if $tx->is_success;

    $tx = new Business::OnlinePayment( "viaKLIX", %opts );
    $tx->content( %content, "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=Y,AVSZIP=N",
        is_success    => 1,
        result_code   => "0",
        authorization => qr/^\w{6}$/,
        avs_code      => "A",
        cvv2_response => "M",
        order_number  => qr/^([0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12})$/,
    );
    $credit_amount += $content{amount} if $tx->is_success;

    $tx = new Business::OnlinePayment( "viaKLIX", %opts );
    $tx->content( %content, "address" => "500 Any street", "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=N",
        is_success    => 1,
        result_code   => "0",
        authorization => qr/^\w{6}$/,
        avs_code      => "N",
        cvv2_response => "M",
        order_number  => qr/^([0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12})$/,
    );
    $credit_amount += $content{amount} if $tx->is_success;
}

{    # cvv2_response() / CVV2MATCH

    my $tx = new Business::OnlinePayment( "viaKLIX", %opts );

    $tx->content( %content, "cvv2" => $content{cvv2}+1 );
    tx_check(
        $tx,
        desc          => "wrong cvv2",
        is_success    => 1,
        result_code   => "0",
        authorization => qr/^\w{6}$/,
        avs_code      => "Y",
        cvv2_response => "N",
        order_number  => qr/^([0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12})$/,
    );
    $credit_amount += $content{amount} if $tx->is_success;

}

SKIP: {    # refund test

    skip "Refund tests require account with refund capability", 6;

    my $tx = new Business::OnlinePayment( "viaKLIX", %opts );
    $tx->content( %content, 'action' => "Credit",
                            'amount' => sprintf("%.2f", $credit_amount),
                );
    tx_check(
        $tx,
        desc          => "refund/credit",
        is_success    => 1,
        result_code   => "0",
        authorization => qr/^$/,
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => qr/^$/,
    );
}

sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->submit;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    like( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
    is( $tx->avs_code,  $o{avs_code},  "avs_code() / AVSADDR and AVSZIP" );
    is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
    like( $tx->order_number, $o{order_number}, "order_number() / PNREF" );
}

sub tx_info {
    my $tx = shift;

    no warnings 'uninitialized';

    return (
        join( "",
            "is_success(",     $tx->is_success,    ")",
            " order_number(",  $tx->order_number,  ")",
            " result_code(",   $tx->result_code,   ")",
            " auth_info(",     $tx->authorization, ")",
            " avs_code(",      $tx->avs_code,      ")",
            " cvv2_response(", $tx->cvv2_response, ")",
        )
    );
}
