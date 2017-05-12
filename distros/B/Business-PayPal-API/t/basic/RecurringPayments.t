# -*- mode: cperl -*-
use Test::More;
if ( !$ENV{WPP_TEST} || !-f $ENV{WPP_TEST} ) {
    plan skip_all =>
        'No WPP_TEST env var set. Please see README to run tests';
}
else {
    plan tests => 3;
}

use_ok('Business::PayPal::API::RecurringPayments');
#########################

require 't/API.pl';

my %args = do_args();

my $pp = new Business::PayPal::API::RecurringPayments(%args);

#$Business::PayPal::API::Debug = 1;
my %response = $pp->SetCustomerBillingAgreement(
    BillingType                 => 'RecurringPayments',
    BillingAgreementDescription => '10.00 per month for 1 year',
    ReturnURL                   => 'http://www.google.com/',
    CancelURL                   => 'http://www.google.com/',
    BuyerEmail                  => $args{BuyerEmail},
);

#$Business::PayPal::API::Debug = 0;

my $token = $response{Token};

ok( $token, "Got token" );
like( $response{Ack}, qr/Success/, "SetCustomerBillingAgreement successful" );

exit;

die
    "No token from PayPal! Check your authentication information and try again."
    unless $token;

my $pp_url
    = "https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_customer-billing-agreement&token=$token";

=pod

print STDERR <<"_TOKEN_";

Now paste the following URL into your browser (you'll need to have
another browser window already logged into the PayPal developer site):

  $pp_url

Login to PayPal as the Buyer you specified in '$ENV{WPP_TEST}' and
proceed to checkout (this authorizes the transaction represented by
the token). When finished, PayPal will redirect you to a non-existent
URL:

  http://localhost/return.html?token=$token&PayerID=XXXXXXXXXXXXX

Notice the *PayerID* URL argument (XXXXXXXXXXXXX) on the redirect from
PayPal.
_TOKEN_

print STDERR "\nType or paste that PayerID here and hit Enter: \n";

my $payerid = <STDIN>; chomp $payerid;

die "Need a PayerID.\n" unless $payerid;

=cut

## CreateRecurringPaymentsProfile
#$Business::PayPal::API::Debug = 1;
my %profile = $pp->CreateRecurringPaymentsProfile(
    Token => $token,

    ## RecurringPaymentProfileDetails
    SubscriberName => 'Joe Schmoe',

    SubscriberShipperName            => 'Schmoe House',
    SubscriberShipperStreet1         => '1234 Street St.',
    SubscriberShipperCityName        => 'Orem',
    SubscriberShipperStateOrProvince => 'UT',
    SubscriberShipperPostalCode      => '84222',
    SubscriberShipperCountry         => 'USA',
    SubscriberShipperPhone           => '123-123-1234',

    BillingStartDate => '2009-12-01Z',
    ProfileReference => 'BH12341234',

    ## ScheduleDetails
    Description => '12 Month Hosting Package: We Love You!',

    InitialAmount => '12.34',

    TrialBillingPeriod      => 'Month',
    TrialBillingFrequency   => 1,
    TrialTotalBillingCycles => 1,
    TrialAmount             => 0.00,
    TrialShippingAmount     => 0.00,
    TrialTaxAmount          => 0.00,

    PaymentBillingPeriod      => 'Year',
    PaymentBillingFrequency   => 1,
    PaymentTotalBillingCycles => 1,
    PaymentAmount             => 95.40,
    PaymentShippingAmount     => 0.00,
    PaymentTaxAmount          => 0.00,

    #    MaxFailedPayments         => 1,
    #    AutoBillOutstandingAmount => 'AddToNextBilling',
);

#$Business::PayPal::API::Debug = 0;

## GetBillingAgreementCustomerDetails
#$Business::PayPal::API::Debug = 1;
my %details = $pp->GetBillingAgreementCustomerDetails($token);

#$Business::PayPal::API::Debug = 0;

like( $details{Ack}, qr/Success/, "details ok" );

