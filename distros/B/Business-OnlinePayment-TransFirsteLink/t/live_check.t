#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) ELINK_ACH_ACCOUNT, ELINK_ACH_PASSWORD"
  . " ELINK_ROUTING_CODE, ELINK_BANK_ACCOUNT, ELINK_ACH_NAME"
  . " ELINK_ACH_ADDRESS, ELINK_ACH_CITY, ELINK_ACH_STATE"
  . " ELINK_ACH_ZIP, ELINK_ACH_PHONE, ELINK_DO_LIVE";

plan(
      ( $ENV{"ELINK_ACH_ACCOUNT"} && $ENV{"ELINK_ACH_PASSWORD"} &&
        $ENV{"ELINK_ROUTING_CODE"} && $ENV{"ELINK_BANK_ACCOUNT"} &&
        $ENV{"ELINK_ACH_NAME"} && $ENV{"ELINK_ACH_ADDRESS"} &&
        $ENV{"ELINK_ACH_CITY"} && $ENV{"ELINK_ACH_STATE"} &&
        $ENV{"ELINK_ACH_ZIP"} && $ENV{"ELINK_ACH_PHONE"} &&
        $ENV{"ELINK_DO_LIVE"}
      )
    ? ( tests => 12 )
    : ( skip_all => $runinfo )
);

my %opts = (
    "debug"    => 0,
    "merchantcustservnum" => "8005551212",
);

my %content = (
    login          => $ENV{"ELINK_ACH_ACCOUNT"},
    password       => $ENV{"ELINK_ACH_PASSWORD"},
    action         => "Normal Authorization",
    type           => "CHECK",
    description    => "Business::OnlinePayment::TransFirsteLink live test",
    routing_code   => $ENV{"ELINK_ROUTING_CODE"},
    account_number => $ENV{"ELINK_BANK_ACCOUNT"},
    check_number   => "99",
    amount         => "1.01",
    invoice_number => "LiveTest",
    customer_id    => "LiveTestCust",
    account_name   => $ENV{"ELINK_ACH_NAME"},
    address        => $ENV{"ELINK_ACH_ADDRESS"},
    city           => $ENV{"ELINK_ACH_CITY"},
    state          => $ENV{"ELINK_ACH_STATE"},
    zip            => $ENV{"ELINK_ACH_ZIP"},
    phone          => $ENV{"ELINK_ACH_PHONE"},
);

{    # valid account test
    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid account",
        is_success    => 1,
        result_code   => "P00",
    );
}

SKIP: {    # invalid account test

    skip "invalid account tests broken", 4;

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, routing_code   => "052000113",
                            account_number => "000000000001",
                );

    tx_check(
        $tx,
        desc          => "invalid account",
        is_success    => 0,
        result_code   => 214,
    );
}

{    # credit/refund test

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, action => "Credit");

    tx_check(
        $tx,
        desc          => "credit/refund",
        is_success    => 1,
        result_code   => "ACCEPTED",
    );
}

sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->submit;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    is( scalar(@{$tx->junk}), 0, "junk() / JUNK " );
    like( $tx->order_number, qr/^(\d{9}|)$/, "order_number() / PNREF" );
}

sub tx_info {
    my $tx = shift;

    no warnings 'uninitialized';

    return (
        join( "",
            "is_success(",     $tx->is_success,    ")",
            " order_number(",  $tx->order_number,  ")",
            " result_code(",   $tx->result_code,   ")",
            $tx->junk ? " junk(". join('|', @{$tx->junk}). ")" : '',
        )
    );
}
