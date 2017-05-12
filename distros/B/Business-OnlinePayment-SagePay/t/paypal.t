#!/usr/bin/perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Business::OnlinePayment;
use WWW::Mechanize;

use Test::Business::OnlinePayment::SagePay qw(create_transaction);

BEGIN {
    if (defined $ENV{SAGEPAY_VENDOR} && $ENV{SAGEPAY_SIMULATOR_PAYPAL}) {
        plan tests => 7;
    }
    else {
        plan skip_all => 'SAGEPAY_VENDOR and/or SAGEPAY_SIMULATOR_PAYPAL environemnt variable not defined}';
    }

    use_ok('Business::OnlinePayment::SagePay');
}

my $tx = Business::OnlinePayment->new(
    'SagePay',
    vendor      => $ENV{SAGEPAY_VENDOR},
    protocol    => 2.23,
    currency    => 'gbp',
);
ok($tx, 'Transaction object');

$tx->content(
    create_transaction(),
    type => 'paypal',
    paypal_callback_uri => 'http://localhost',
    billing_agreement => 1,
);

$tx->set_server('simulator');

ok($tx->submit, 'Transaction submitted');

ok($tx->is_success, 'Transaction success');

my $vps_id = $tx->authorization;

is($tx->result_code, $tx->SAGEPAY_STATUS_PAYPAL_REDIRECT, 'PayPal redirect response');

SKIP: {
    eval 'use WWW::Mechanize; 1';
    skip 'WWW::Mechanize not available', 2 if $@;

    my $mech = WWW::Mechanize->new;

    $mech->get($tx->forward_to);

    # submit redirection to paypal
    $mech->submit_form(form_name => 'txreleaseform');

    # submit paypal ok button in simulator
    $mech->submit_form(
        form_name   => 'txreleaseform',
        fields      => { clickedButton => 'paypalok' },
    );

    $tx->content(
        authentication_id   => $vps_id,
        amount              => 10,
    );

    $tx->submit_paypal;

    ok($tx->is_success, 'PayPal transaction success');
    is($tx->result_code, $tx->SAGEPAY_STATUS_OK, 'Payment status OK');
}

done_testing();
