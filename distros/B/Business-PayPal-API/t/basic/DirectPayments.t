#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;

if ( !$ENV{WPP_TEST} || !-f $ENV{WPP_TEST} ) {
    plan skip_all =>
        'No WPP_TEST env var set. Please see README to run tests';
}
else {
    plan tests => '7';
}

use Business::PayPal::API
    qw( DirectPayments CaptureRequest ReauthorizationRequest VoidRequest RefundTransaction );

my @methlist
    = qw( DirectPayments CaptureRequest ReauthorizationRequest VoidRequest RefundTransaction);
use_ok( 'Business::PayPal::API', @methlist );

require 't/API.pl';

my %args = do_args();

my ( $transale, $tranvoid, $tranbasic, $tranrefund );
my ( $ppsale, $ppvoid, $ppbasic, $pprefund, $pprefund1, $ppcap, $ppcap1 );
my (
    %respsale, %resprefund, %resprefund1, %respbasic,
    %respcap,  %respcap1,   %respvoid
);

#Test Full Refund on Sale

#$Business::PayPal::API::Debug=1;
$ppsale   = Business::PayPal::API->new(%args);
%respsale = $ppsale->DoDirectPaymentRequest(
    PaymentAction     => 'Sale',
    OrderTotal        => 11.87,
    TaxTotal          => 0.0,
    ItemTotal         => 0.0,
    CreditCardType    => 'Visa',
    CreditCardNumber  => '4561435600988217',
    ExpMonth          => '01',
    ExpYear           => +(localtime)[5] + 1901,
    CVV2              => '123',
    FirstName         => 'JP',
    LastName          => 'Morgan',
    Street1           => '1st Street LaCausa',
    Street2           => '',
    CityName          => 'La',
    StateOrProvince   => 'CA',
    PostalCode        => '90210',
    Country           => 'US',
    Payer             => 'mall@example.org',
    CurrencyID        => 'USD',
    IPAddress         => '10.0.0.1',
    MerchantSessionID => '10113301',
);

#$Business::PayPal::API::Debug=0;
if ( like( $respsale{'Ack'}, qr/Success/, 'Direct Payment Sale' ) ) {
    $transale = $respsale{'TransactionID'};

    #$Business::PayPal::API::Debug=1;
    $pprefund   = Business::PayPal::API->new(%args);
    %resprefund = $pprefund->RefundTransaction(
        TransactionID => $transale,
        RefundType    => 'Full',
        Memo          => 'Full direct sale refund',
    );

    #$Business::PayPal::API::Debug=0;
    like( $resprefund{'Ack'}, qr/Success/, 'Full Refund For Sale' );
}

#Basic Authorization and Capture

%args = do_args();

#$Business::PayPal::API::Debug=0;
$ppbasic   = Business::PayPal::API->new(%args);
%respbasic = $ppbasic->DoDirectPaymentRequest(
    PaymentAction     => 'Authorization',
    OrderTotal        => 13.87,
    TaxTotal          => 0.0,
    ItemTotal         => 0.0,
    CreditCardType    => 'Visa',
    CreditCardNumber  => '4561435600988217',
    ExpMonth          => '01',
    ExpYear           => +(localtime)[5] + 1901,
    CVV2              => '123',
    FirstName         => 'JP',
    LastName          => 'Morgan',
    Street1           => '1st Street LaCausa',
    Street2           => '',
    CityName          => 'La',
    StateOrProvince   => 'CA',
    PostalCode        => '90210',
    Country           => 'US',
    Payer             => 'mall@example.org',
    CurrencyID        => 'USD',
    IPAddress         => '10.0.0.1',
    MerchantSessionID => '10113301',
);

#$Business::PayPal::API::Debug=0;
if (
    like(
        $respbasic{'Ack'}, qr/Success/,
        'Direct Payment Basic Authorization'
    )
    ) {
    $tranbasic = $respbasic{'TransactionID'};

    #Test Partial Capture
    #$Business::PayPal::API::Debug=1;
    $ppcap = Business::PayPal::API->new(%args);

    %respcap = $ppcap->DoCaptureRequest(
        AuthorizationID => $tranbasic,
        CompleteType    => 'NotComplete',
        Amount          => '3.00',
        Note            => 'Partial Capture',
    );

    #$Business::PayPal::API::Debug=0;
    like( $respcap{'Ack'}, qr/Success/, 'Partial Capture' );

    #Test Full Capture
    #$Business::PayPal::API::Debug=1;
    $ppcap1   = Business::PayPal::API->new(%args);
    %respcap1 = $ppcap1->DoCaptureRequest(
        AuthorizationID => $tranbasic,
        CompleteType    => 'Complete',
        Amount          => '6.00',
    );

    #$Business::PayPal::API::Debug=0;
    like( $respcap1{'Ack'}, qr/Success/, 'Full Capture' );
}
else { skip( "direct payment auth failed", 2 ) }

#Test Void
$ppbasic   = Business::PayPal::API->new(%args);
%respbasic = $ppbasic->DoDirectPaymentRequest(
    PaymentAction     => 'Authorization',
    OrderTotal        => 17.37,
    TaxTotal          => 0.0,
    ItemTotal         => 0.0,
    CreditCardType    => 'Visa',
    CreditCardNumber  => '4561435600988217',
    ExpMonth          => '01',
    ExpYear           => +(localtime)[5] + 1901,
    CVV2              => '123',
    FirstName         => 'JP',
    LastName          => 'Morgan',
    Street1           => '1st Street LaCausa',
    Street2           => '',
    CityName          => 'La',
    StateOrProvince   => 'CA',
    PostalCode        => '90210',
    Country           => 'US',
    Payer             => 'mall@example.org',
    CurrencyID        => 'USD',
    IPAddress         => '10.0.0.1',
    MerchantSessionID => '10113301',
);

#$Business::PayPal::API::Debug=1;
$ppvoid   = Business::PayPal::API->new(%args);
%respvoid = $ppvoid->DoVoidRequest(
    AuthorizationID => $respbasic{TransactionID},
    Note            => 'Authorization Void',
);

#$Business::PayPal::API::Debug=0;
like( $respvoid{'Ack'}, qr/Success/, 'Authorization Voided' );
