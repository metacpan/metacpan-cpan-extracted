#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) PNP_ACCOUNT, PNP_PASSWORD, PNP_CARD,"
  . " PNP_CVV2, PNP_EXP, PNP_CARD_NAME, PNP_CARD_ADDRESS,"
  . " PNP_CARD_CITY, PNP_CARD_STATE, PNP_CARD_ZIP, and PNP_DO_LIVE ";

plan(
      ( $ENV{"PNP_ACCOUNT"} && $ENV{"PNP_PASSWORD"} &&
        $ENV{"PNP_CARD"} && $ENV{"PNP_CVV2"} &&
        $ENV{"PNP_EXP"} && $ENV{"PNP_CARD_NAME"} &&
        $ENV{"PNP_CARD_ADDRESS"} && $ENV{"PNP_CARD_CITY"} &&
        $ENV{"PNP_CARD_STATE"} && $ENV{"PNP_CARD_ZIP"} &&
        $ENV{"PNP_DO_LIVE"}
      )
    ? ( tests => 48 )
    : ( skip_all => $runinfo )
);

my %opts = (
    "debug"                      => 0,
);

my %content = (
    login          => $ENV{"PNP_ACCOUNT"},
    password       => $ENV{"PNP_PASSWORD"},
    action         => "Normal Authorization",
    type           => "CC",
    description    => "Business::OnlinePayment::PlugnPay live test",
    card_number    => $ENV{"PNP_CARD"},
    cvv2           => $ENV{"PNP_CVV2"},
    expiration     => $ENV{"PNP_EXP"},
    amount         => "0.01",
    invoice_number => "LiveTest",
    name           => $ENV{"PNP_CARD_NAME"},
    address        => $ENV{"PNP_CARD_ADDRESS"},
    city           => $ENV{"PNP_CARD_CITY"},
    state          => $ENV{"PNP_CARD_STATE"},
    zip            => $ENV{"PNP_CARD_ZIP"},
);

my $voidable;
my $voidable_amount = 0;
my $credit_amount = 0;

{    # valid card number test
    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid card_number",
        is_success    => 1,
        result_code   => "A",              # wtf?
        authorization => qr/^\w{6}$/,
        avs_code      => "Y",
        cvv2_response => "M",
        order_number  => qr/^([0-9]{19})$/,
    );
   $voidable = $tx->order_number if $tx->is_success;
   $voidable_amount = $content{amount} if $tx->is_success;
}

{    # invalid card number test

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, card_number => "4111111111111112" );
    tx_check(
        $tx,
        desc          => "invalid card_number",
        is_success    => 0,
        result_code   => "P66",
        authorization => qr/^$/,
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => qr/^([0-9]{19})$/,
    );
}


{    # avs_code() / AVSZIP and AVSADDR tests

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );

    $tx->content( %content, "address" => "500 Any street" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=Y",
        is_success    => 1,
        result_code   => "A",
        authorization => qr/^\w{6}$/,
        avs_code      => "Z",
        cvv2_response => "M",
        order_number  => qr/^([0-9]{19})$/,
    );
    $credit_amount += $content{amount} if $tx->is_success;

    $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=Y,AVSZIP=N",
        is_success    => 1,
        result_code   => "A",
        authorization => qr/^\w{6}$/,
        avs_code      => "A",
        cvv2_response => "M",
        order_number  => qr/^([0-9]{19})$/,
    );
    $credit_amount += $content{amount} if $tx->is_success;

    $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, "address" => "500 Any street", "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=N",
        is_success    => 1,
        result_code   => "A",
        authorization => qr/^\w{6}$/,
        avs_code      => "N",
        cvv2_response => "M",
        order_number  => qr/^([0-9]{19})$/,
    );
    $credit_amount += $content{amount} if $tx->is_success;
}

{    # cvv2_response() / CVV2MATCH

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );

    $tx->content( %content, "cvv2" => $content{cvv2}+1 );
    tx_check(
        $tx,
        desc          => "wrong cvv2",
        is_success    => 0,
        result_code   => "P02",               # configurable?
        authorization => qr/^\w{6}$/,
        avs_code      => "Y",
        cvv2_response => "N",
        order_number  => qr/^([0-9]{19})$/,
    );
    #$credit_amount += $content{amount} if $tx->is_success;

}

SKIP: {    # void test

    #skip "Void tests require account with void capability", 6;

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, 'action' => "Void",
                            'order_number' => $voidable,
                );
    tx_check(
        $tx,
        desc          => "void",
        is_success    => 1,
        result_code   => undef,
        authorization => qr/^$/,
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => qr/^([0-9]{19})$/,
    );
    $credit_amount += $voidable_amount unless $tx->is_success;
}

SKIP: {    # refund test

    #skip "Refund tests require account with refund capability", 6;

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, 'action' => "Credit",
                            'amount' => sprintf("%.2f", $credit_amount),
                );
    tx_check(
        $tx,
        desc          => "refund/credit",
        is_success    => 1,
        result_code   => undef,
        authorization => qr/^$/,
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => qr/^([0-9]{19})$/,
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
