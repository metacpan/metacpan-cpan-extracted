#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) ELAVON_ACCOUNT, ELAVON_USERID, and ELAVON_PASSWORD"
  . " (optional) DEBUG, ELAVON_SERVER, and ELAVON_PATH";

plan(
      (   $ENV{"ELAVON_ACCOUNT"}
       && $ENV{"ELAVON_USERID"}
       && $ENV{"ELAVON_PASSWORD"} )
    ? ( tests => 42 )
    : ( skip_all => $runinfo )
);

my %opts = (
    "debug"                      => $ENV{"DEBUG"} || 0,
    "default_ssl_user_id"        => $ENV{"ELAVON_USERID"},
    "default_ssl_salestax"       => "0.00",
    "default_ssl_customer_code"  => "TESTCUSTOMER",
);

my %content = (
    login          => $ENV{"ELAVON_ACCOUNT"},
    password       => $ENV{"ELAVON_PASSWORD"},
    action         => "Normal Authorization",
    type           => "VISA",
    description    => "Business::OnlinePayment::ElavonVirtualMerchant test",
    card_number    => "4111111111111111",
    cvv2           => "123",
    expiration     => "12/" . strftime( "%y", localtime ),
    amount         => "0.01",
    invoice_number => "Test1",
    first_name     => "Tofu",
    last_name      => "Beast",
    email          => 'nobody@example.com',
    address        => "123 Anystreet",
    city           => "Anywhere",
    state          => "GA",
    zip            => "30004",
    country        => "US",
);

{    # valid card number test
    my $tx = new Business::OnlinePayment( "ElavonVirtualMerchant", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid card_number",
        is_success    => 1,
        result_code   => "0",
        authorization => "123456",
        avs_code      => "X",
        cvv2_response => "P",
        order_number  => "00000000-0000-0000-0000-00000000000",
    );
}

{    # invalid card number test

    my $tx = new Business::OnlinePayment( "ElavonVirtualMerchant", %opts );
    $tx->content( %content, card_number => "4111111111111112" );
    tx_check(
        $tx,
        desc          => "invalid card_number",
        is_success    => 0,
        result_code   => 5000,
        authorization => undef,
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => undef,
    );
}


SKIP: {    # avs_code() / AVSZIP and AVSADDR tests

    skip "AVS tests broken", 18;

    my $tx = new Business::OnlinePayment( "ElavonVirtualMerchant", %opts );

    $tx->content( %content, "address" => "500 Any street" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=Y",
        is_success    => 1,
        result_code   => "0",
        authorization => "123456",
        avs_code      => "Z",
        cvv2_response => "P",
        order_number  => "00000000-0000-0000-0000-00000000000",
    );

    $tx = new Business::OnlinePayment( "ElavonVirtualMerchant", %opts );
    $tx->content( %content, "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=Y,AVSZIP=N",
        is_success    => 1,
        result_code   => "0",
        authorization => "123456",
        avs_code      => "A",
        cvv2_response => "P",
        order_number  => "00000000-0000-0000-0000-00000000000",
    );

    $tx = new Business::OnlinePayment( "ElavonVirtualMerchant", %opts );
    $tx->content( %content, "address" => "500 Any street", "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=N",
        is_success    => 1,
        result_code   => "0",
        authorization => "123456",
        avs_code      => "N",
        cvv2_response => "P",
        order_number  => "00000000-0000-0000-0000-00000000000",
    );
}

SKIP: {    # cvv2_response() / CVV2MATCH

    skip "CVV2 tests broken", 6;

    my $tx = new Business::OnlinePayment( "ElavonVirtualMerchant", %opts );

    $tx->content( %content, "cvv2" => "301" );
    tx_check(
        $tx,
        desc          => "wrong cvv2",
        is_success    => 1,
        result_code   => "0",
        authorization => "123456",
        avs_code      => "X",
        cvv2_response => "N",
        order_number  => "00000000-0000-0000-0000-00000000000",
    );

}

SKIP: {    # refund test

    skip "credit/refund tests broken", 6;

    my $tx = new Business::OnlinePayment( "ElavonVirtualMerchant", %opts );
    $tx->content( %content, 'action' => "Credit",
                            'card_number' => "4444333322221111",
                );
    tx_check(
        $tx,
        desc          => "refund/credit",
        is_success    => 1,
        result_code   => "0",
        authorization => undef,
        avs_code      => undef,
        cvv2_response => undef,
        order_number  => "00000000-0000-0000-0000-00000000000",
    );
}

sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->test_transaction(1);
    $tx->server($ENV{"ELAVON_SERVER"}) if defined($ENV{"ELAVON_SERVER"});
    $tx->path($ENV{"ELAVON_PATH"}) if defined($ENV{"ELAVON_PATH"});
    $tx->submit;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    is( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
    is( $tx->avs_code,  $o{avs_code},  "avs_code() / AVSADDR and AVSZIP" );
    is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
    is( $tx->order_number, $o{order_number}, "order_number() / PNREF" );
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
