#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) ELINK_ACCOUNT, ELINK_PASSWORD, ELINK_CARD,"
  . " ELINK_CVV2, ELINK_EXP, ELINK_CARD_NAME, ELINK_CARD_ADDRESS,"
  . " ELINK_CARD_CITY, ELINK_CARD_STATE, ELINK_CARD_ZIP, and ELINK_DO_LIVE ";

plan(
      ( $ENV{"ELINK_ACCOUNT"} && $ENV{"ELINK_PASSWORD"} &&
        $ENV{"ELINK_CARD"} && $ENV{"ELINK_CVV2"} &&
        $ENV{"ELINK_EXP"} && $ENV{"ELINK_CARD_NAME"} &&
        $ENV{"ELINK_CARD_ADDRESS"} && $ENV{"ELINK_CARD_CITY"} &&
        $ENV{"ELINK_CARD_STATE"} && $ENV{"ELINK_CARD_ZIP"} &&
        $ENV{"ELINK_DO_LIVE"}
      )
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
    type           => "CC",
    description    => "Business::OnlinePayment::TransFirsteLink live test",
    card_number    => $ENV{"ELINK_CARD"},
    cvv2           => $ENV{"ELINK_CVV2"},
    expiration     => $ENV{"ELINK_EXP"},
    amount         => "0.01",
    invoice_number => "LiveTest",
    name           => $ENV{"ELINK_CARD_NAME"},
    address        => $ENV{"ELINK_CARD_ADDRESS"},
    city           => $ENV{"ELINK_CARD_CITY"},
    state          => $ENV{"ELINK_CARD_STATE"},
    zip            => $ENV{"ELINK_CARD_ZIP"},
);

my $voidable;
my $credit_amount = 0;

{    # valid card number test
    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid card_number",
        is_success    => 1,
        result_code   => "000",
        authorization => qr/^\w{6}$/,
        avs_code      => "Y",      # useless
        cvv2_response => "M",
    );
   $voidable = $tx->order_number if $tx->is_success;
}

{    # invalid card number test

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, card_number => "4111111111111112" );
    tx_check(
        $tx,
        desc          => "invalid card_number",
        is_success    => 0,
        result_code   => 214,
        authorization => qr/^$/,
        avs_code      => '',
        cvv2_response => '',
    );
}


{    # avs_code() / AVSZIP and AVSADDR tests

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );

    $tx->content( %content, "address" => "500 Any street" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=Y",
        is_success    => 1,
        result_code   => "000",
        authorization => qr/^\w{6}$/,
        avs_code      => "Z",
        cvv2_response => "M",
    );
    $credit_amount += $content{amount} if $tx->is_success;

    $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=Y,AVSZIP=N",
        is_success    => 1,
        result_code   => "000",
        authorization => qr/^\w{6}$/,
        avs_code      => "A",
        cvv2_response => "M",
    );
    $credit_amount += $content{amount} if $tx->is_success;

    $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, "address" => "500 Any street", "zip" => "99999" );
    tx_check(
        $tx,
        desc          => "AVSADDR=N,AVSZIP=N",
        is_success    => 1,
        result_code   => "000",
        authorization => qr/^\w{6}$/,
        avs_code      => "N",
        cvv2_response => "M",
    );
    $credit_amount += $content{amount} if $tx->is_success;
}

{    # cvv2_response() / CVV2MATCH

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );

    $tx->content( %content, "cvv2" => $content{cvv2}+1 );
    tx_check(
        $tx,
        desc          => "wrong cvv2",
        is_success    => 1,
        result_code   => "000",
        authorization => qr/^\w{6}$/,
        avs_code      => "Y",
        cvv2_response => "N",
    );

}

{    # refund test

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, 'action' => "Credit",
                            'amount' => sprintf("%.2f", $credit_amount),
                );
    tx_check(
        $tx,
        desc          => "refund/credit",
        is_success    => 1,
        result_code   => "000",
        authorization => qr/^$/,
        avs_code      => '',
        cvv2_response => '',
    );
}

{    # void test

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, 'action' => "Void",
                            'order_number' => $voidable
                );
    tx_check(
        $tx,
        desc          => "void",
        is_success    => 1,
        result_code   => "000",
        authorization => qr/^$/,
        avs_code      => '',
        cvv2_response => '',
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
