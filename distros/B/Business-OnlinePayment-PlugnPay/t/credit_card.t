#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) PNP_ACCOUNT and PNP_PASSWORD";

plan(
      (   $ENV{"PNP_ACCOUNT"}
       && $ENV{"PNP_PASSWORD"} )
    ? ( tests => 30 )
    : ( skip_all => $runinfo )
);

my %opts = (
    "debug"                      => 0,
);

my %content = (
    login          => $ENV{"PNP_ACCOUNT"},
    password       => $ENV{"PNP_PASSWORD"},
    action         => "Normal Authorization",
    type           => "VISA",
    description    => "Business::OnlinePayment::PlugnPay test",
    card_number    => "4111111111111111",
    expiration     => "12/" . strftime( "%y", localtime ),
    amount         => "0.01",
    name           => "cardtest",
    cvv2           => "123",
    invoice_number => "Test1",
    email          => 'plugnpay@weasellips.com',
    address        => "123 Anystreet",
    city           => "Anywhere",
    state          => "GA",
    zip            => "30004",
    country        => "US",
    ship_first_name=> "Tofu",
    ship_last_name => "Beast",
    ship_address   => "456 Anystreet",
    ship_city      => "Somewhere",
    ship_state     => "CA",
    ship_zip       => "90004",
    ship_country   => "US",
);

{    # valid card number test
    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid card_number",
        is_success    => 1,
        result_code   => "00",
        authorization => "TSTAUT",
        avs_code      => "U",
        cvv2_response => "M",
        order_number  => qr/^([0-9]{19})$/,
    );
}

{    # invalid card number test

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, card_number => "4111111111111112" );
    tx_check(
        $tx,
        desc          => "invalid card_number",
        is_success    => 0,
        result_code   => "P66",
        authorization => "",
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => qr/^([0-9]{19})$/,
    );
}

{    # dubious faked bad card test

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, amount => "1000.01" );
    tx_check(
        $tx,
        desc          => "faked bad card",
        is_success    => 0,
        result_code   => "P30",
        authorization => "",
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => qr/^([0-9]{19})$/,
    );
}

{    # dubious faked problem test

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, amount => "2000.01" );
    tx_check(
        $tx,
        desc          => "faked problem",
        is_success    => 0,
        result_code   => "P35",
        authorization => "",
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => qr/^([0-9]{19})$/,
    );
}


SKIP: {    # refund test

    skip "credit/refund tests broken", 6;

    my $tx = new Business::OnlinePayment( "PlugnPay", %opts );
    $tx->content( %content, 'action' => "Credit",
                );
    tx_check(
        $tx,
        desc          => "refund/credit",
        is_success    => 0,    # :\
        result_code   => undef,
        authorization => undef,
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
    is( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
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
