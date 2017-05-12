# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { use_ok( 'Business::iDEAL::Adyen' ); }

my $ideal = Business::iDEAL::Adyen->new ({ 
    shared_secret   => 'Kah942*$7sdp0)',
    skinCode        => '4aD37dJA',
    merchantAccount => 'TestMerchant',
});

isa_ok ($ideal, 'Business::iDEAL::Adyen');

my %args = (
    paymentAmount       => 10000,
    currencyCode        => 'GBP',
    shipBeforeDate      => '2007-10-20',
    merchantReference   => 'Internet Order 12345',
    sessionValidity     => '2007-10-11T11:00:00Z',
);

my $hmac = $ideal->_sign_req(\%args);

is($hmac, 'x58ZcRVL1H6y+XSeBGrySJ9ACVo=', 'signature');
