#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) PFPRO_VENDOR PFPRO_USER PFPRO_PWD and CLIENTCERTID (for X-VPS-VIT-CLIENT-CERTIFICATION-ID); "
  . " (optional) PFPRO_PARTNER PFPRO_CERT_PATH";

plan(
      ( $ENV{"PFPRO_USER"} && $ENV{"PFPRO_VENDOR"} && $ENV{"PFPRO_PWD"} )
    ? ( tests => 56 )
    : ( skip_all => $runinfo )
);

my %opts = (
    "debug"   => 0,
    "vendor"  => $ENV{PFPRO_VENDOR},
    "partner" => $ENV{PFPRO_PARTNER} || "verisign",
    "client_certification_id" => $ENV{CLIENTCERTID},
);

my %content = (
    login       => $ENV{"PFPRO_USER"},
    password    => $ENV{"PFPRO_PWD"},
    action      => "Normal Authorization",
    type        => "VISA",
    description => "Business::OnlinePayment::PayflowPro test",
    card_number => "4111111111111111",
    cvv2        => "123",
    expiration  => "12/" . strftime( "%y", localtime ),
    amount      => "0.01",
    first_name  => "Tofu",
    last_name   => "Beast",
    email       => 'ivan-payflowpro@420.am',
    address     => "123 Anystreet",
    city        => "Anywhere",
    state       => "GA",
    zip         => "30004",
    country     => "US",
);

{    # valid card number test
    my $tx = new Business::OnlinePayment( "PayflowPro", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid card_number",
        is_success    => 1,
        result_code   => 0,
        error_message => "Approved",
        authorization => "010101",
        avs_code      => "Y",
        cvv2_response => "Y",
    );
}

{    # invalid card number test

    my $tx = new Business::OnlinePayment( "PayflowPro", %opts );
    $tx->content( %content, card_number => "4111111111111112" );
    tx_check(
        $tx,
        desc          => "invalid card_number",
        is_success    => 0,
        result_code   => 23,
        error_message => "Invalid account number",
        authorization => undef,
        avs_code      => undef,
        cvv2_response => undef,
    );
}


SKIP: {    # avs_code() / AVSZIP and AVSADDR tests

    skip "AVS tests broken", 28;

    my $tx = new Business::OnlinePayment( "PayflowPro", %opts );

    # IF first 3 chars of STREET <= 334 and >= 666 THEN AVSADDR == "N"
    $tx->content( %content, "address" => "500 Any street" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=Y",
        is_success    => 0,
        result_code   => 126,
        error_message => "Under review by Fraud Service",
        authorization => "010101",
        avs_code      => "Z",
        cvv2_response => "Y",
    );

    # IF first 3 chars of STREET >= 667 THEN AVSADDR == "X" (and AVSZIP="X")
    $tx = new Business::OnlinePayment( "PayflowPro", %opts );
    $tx->content( %content, "address" => "700 Any street" );
    tx_check(
        $tx,
        desc          => "AVSADDR=X,AVSZIP=X",
        is_success    => 1,
        result_code   => 0,
        error_message => "Approved",
        authorization => "010101",
        avs_code      => "",
        cvv2_response => "Y",
    );

#    # IF ZIP <= 50001 and >= 99999 THEN AVSZIP == "N"
    $tx = new Business::OnlinePayment( "PayflowPro", %opts );
    $tx->content( %content, "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=Y,AVSZIP=N",
        is_success    => 0,
        result_code   => 126,
        error_message => "Under review by Fraud Service",
        authorization => "010101",
        avs_code      => "A",
        cvv2_response => "Y",
    );

    # Both AVSADDR and AVSZIP == "N"
    $tx = new Business::OnlinePayment( "PayflowPro", %opts );
    $tx->content( %content, "address" => "500 Any street", "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=N",
        is_success    => 0,
        result_code   => 126,
        error_message => "Under review by Fraud Service",
        authorization => "010101",
        avs_code      => "N",
        cvv2_response => "Y",
    );
}

SKIP: {    # cvv2_response() / CVV2MATCH

    skip "CVV2 tests broken", 14;

    my $tx = new Business::OnlinePayment( "PayflowPro", %opts );

    # IF CVV2 >= 301 and <= 600 THEN CVV2MATCH == "N"
    $tx->content( %content, "cvv2" => "301" );
    tx_check(
        $tx,
        desc          => "cvv2(301)",
        is_success    => 0,
        result_code   => 126,
        error_message => "Under review by Fraud Service",
        authorization => "010101",
        avs_code      => "Y",
        cvv2_response => "N",
    );

    # IF CVV2 >= 601 THEN CVV2MATCH == "X"
    $tx = new Business::OnlinePayment( "PayflowPro", %opts );
    $tx->content( %content, "cvv2" => "601" );
    tx_check(
        $tx,
        desc          => "cvv2(601)",
        is_success    => 0,
        result_code   => 126,
        error_message => "Under review by Fraud Service",
        authorization => "010101",
        avs_code      => "Y",
        cvv2_response => "X",
    );
}

sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->test_transaction(1);
    $tx->submit;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    is( $tx->error_message, $o{error_message}, "error_message() / RESPMSG" );
    is( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
    is( $tx->avs_code,  $o{avs_code},  "avs_code() / AVSADDR and AVSZIP" );
    is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
    like( $tx->order_number, qr/^\w{12}/, "order_number() / PNREF" );
}

sub tx_info {
    my $tx = shift;

    no warnings 'uninitialized';

    return (
        join( "",
            "is_success(",     $tx->is_success,    ")",
            " order_number(",  $tx->order_number,  ")",
            " error_message(", $tx->error_message, ")",
            " result_code(",   $tx->result_code,   ")",
            " auth_info(",     $tx->authorization, ")",
            " avs_code(",      $tx->avs_code,      ")",
            " cvv2_response(", $tx->cvv2_response, ")",
        )
    );
}
