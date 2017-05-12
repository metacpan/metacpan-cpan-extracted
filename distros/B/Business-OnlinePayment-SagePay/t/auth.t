#!/usr/bin/perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Business::OnlinePayment;

use Test::Business::OnlinePayment::SagePay qw(create_transaction);

BEGIN {
    if (defined $ENV{SAGEPAY_VENDOR}) {
        plan tests => 8;
    }
    else {
        plan skip_all => 'SAGEPAY_VENDOR environemnt variable not defined}';
    }

    use_ok('Business::OnlinePayment::SagePay');
}

my $tx = Business::OnlinePayment->new(
    'SagePay',
    vendor      => $ENV{SAGEPAY_VENDOR},
    protocol    => '3.00',
    currency    => 'gbp',
);
ok($tx, 'Transaction object');

$tx->content( create_transaction() );

$tx->set_server('simulator');

ok($tx->submit, 'Transaction submitted');

ok($tx->is_success, 'Transaction success');

SKIP: {
    skip 'SAGEPAY_SIMULATOR_3DSECURE environment variable not defined', 4
        unless defined($ENV{SAGEPAY_SIMULATOR_3DSECURE}); 

    is($tx->result_code, $tx->SAGEPAY_STATUS_3DSECURE, '3DSecure response');

    SKIP: {
        eval 'use WWW::Mechanize; 1';
        skip 'WWW::Mechanize not available', 3 if $@;

        my $mech = WWW::Mechanize->new;

        $mech->post(
            $tx->forward_to, 
            {
                PaReq   => $tx->pareq,
                MD      => $tx->cross_reference,
                TermUrl => 'http://localhost',
            }
        );

        $mech->submit_form(
            form_name   => 'txreleaseform',
            fields      => { clickedButton   => 'ok' },
        );

        ok($mech->success, 'Submitted 3DSecure response');

        my $form = $mech->form_name('form');

        $tx->content(
            cross_reference => $form->value('MD'),
            pares           => $form->value('PaRes'),
        );

        $tx->submit_3d;

        my $tx_response = $tx->server_response;

        ok($tx->is_success, '3D secure transaction success');
        is($tx_response->{'3DSecureStatus'}, $tx->SAGEPAY_STATUS_OK, '3D secure status OK');
    }
}

done_testing();

