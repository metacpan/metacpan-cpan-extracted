#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) ELINK_ACCOUNT and ELINK_PASSWORD";

plan(
      ( $ENV{"ELINK_ACCOUNT"} && $ENV{"ELINK_PASSWORD"} )
    ? ( tests => 56 )
    : ( skip_all => $runinfo )
);

my %opts = (
    "debug"    => 0,
    "merchantcustservnum" => "8005551212",
);

my %content = (
    login          => $ENV{"ELINK_ACCOUNT"},
    password       => $ENV{"ELINK_PASSWORD"},
    action         => "Normal Authorization",
    type           => "VISA",
    description    => "Business::OnlinePayment::TransFirsteLink test",
    card_number    => "4111111111111111",
    cvv2           => "123",
    expiration     => "12/" . strftime( "%y", localtime ),
    amount         => "0.01",
    invoice_number => "Test1",
    first_name     => "Tofu",
    last_name      => "Beast",
    email          => 'transfirst@weasellips.com',
    address        => "123 Anystreet",
    city           => "Anywhere",
    state          => "GA",
    zip            => "30004",
    country        => "US",
);

{    # valid card number test
    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid card_number",
        is_success    => 1,
        result_code   => "000",
        authorization => "999999",
        avs_code      => "9",      # useless
        cvv2_response => "99",     # doubly useless - docs say 1 char
    );
}

{    # invalid card number test

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, card_number => "4111111111111112" );
    tx_check(
        $tx,
        desc          => "invalid card_number",
        is_success    => 0,
        result_code   => 214,
        authorization => '',
        avs_code      => '',
        cvv2_response => '',
    );
}


SKIP: {    # avs_code() / AVSZIP and AVSADDR tests

    skip "AVS tests broken", 21;

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );

    $tx->content( %content, "address" => "500 Any street" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=Y",
        is_success    => 1,
        result_code   => "000",
        authorization => "999999",
        avs_code      => "Z",
        cvv2_response => "M",
    );

    $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=Y,AVSZIP=N",
        is_success    => 1,
        result_code   => "000",
        authorization => "999999",
        avs_code      => "A",
        cvv2_response => "M",
    );

    $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, "address" => "500 Any street", "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=N",
        is_success    => 1,
        result_code   => "000",
        authorization => "999999",
        avs_code      => "N",
        cvv2_response => "M",
    );
}

SKIP: {    # cvv2_response() / CVV2MATCH

    skip "CVV2 tests broken", 7;

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );

    $tx->content( %content, "cvv2" => "301" );
    tx_check(
        $tx,
        desc          => "wrong cvv2",
        is_success    => 1,
        result_code   => "000",
        authorization => "999999",
        avs_code      => "Y",
        cvv2_response => "N",
    );

}

SKIP: {    # refund test

    #skip "credit/refund tests broken", 7;

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, 'action' => "Credit",
                            'card_number' => "4444333322221111",
                );
    tx_check(
        $tx,
        desc          => "refund/credit",
        is_success    => 1,
        result_code   => "000",
        authorization => '',
        avs_code      => '',
        cvv2_response => '',
    );
}

SKIP: {    # void test

    #skip "void tests broken", 7;

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, 'action' => "Void",
                            'order_number' => "12345678901234",
                );
    tx_check(
        $tx,
        desc          => "void",
        is_success    => 1,
        result_code   => "000",
        authorization => '',
        avs_code      => '',
        cvv2_response => '',
    );
}

sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->test_transaction(1);
    $tx->submit;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    is( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
    is( $tx->avs_code,  $o{avs_code},  "avs_code() / AVSADDR and AVSZIP" );
    is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
    is( scalar(@{$tx->junk}), 0, "junk() / JUNK " );
    like( $tx->order_number, qr/^(\d{14}|)$/, "order_number() / PNREF" );
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
            $tx->junk ? " junk(". join('|', @{$tx->junk}). ")" : '',
        )
    );
}
