#!perl

use Test::NoWarnings;
use Test::More tests => 16 + 1;

use lib qw(t/);
use testlib;

my $tracking = Business::UPS::Tracking->new(
    AccessLicenseNumber  => 'license',
    UserId => 'username',
    Password => 'password',
);

isa_ok( $tracking, 'Business::UPS::Tracking' );
is( $tracking->url, 'https://wwwcie.ups.com/ups.app/xml/Track', 'Check url' );
is( $tracking->AccessLicenseNumber,  'license',  'Check license accessor' );
is( $tracking->UserId, 'username', 'Check username accessor' );
is( $tracking->Password, 'password', 'Check password accessor' );
isa_ok( $tracking->_ua, 'LWP::UserAgent' );

my $ua = LWP::UserAgent->new( agent => "TEST", );
$tracking->_ua($ua);
is( $tracking->_ua->agent, 'TEST', 'Check new user agent' );

my $access_request = $tracking->access_request;
like( $access_request, qr|<UserId>username</UserId>|,
    'Check access request username' );
like(
    $access_request,
    qr|<AccessLicenseNumber>license</AccessLicenseNumber>|,
    'Check access request license'
);
like(
    $access_request,
    qr|<Password>password</Password>|,
    'Check access request password'
);

my $request1 = $tracking->request( TrackingNumber => '1Z12345E1111111114' );
isa_ok( $request1, 'Business::UPS::Tracking::Request' );
is( $request1->TrackingNumber, '1Z12345E1111111114',
    'Check TrackingNumber accesor' );
is( $request1->tracking, $tracking, 'Check tracking accesor' );
like(
    $request1->tracking_request,
    qr|<TrackRequest><Request><RequestAction>Track</RequestAction><RequestOption>activity</RequestOption></Request><TrackingNumber>1Z12345E1111111114</TrackingNumber></TrackRequest>|,
    'Check track request 1'
);

my $request2 = $tracking->request(
    ReferenceNumber        => 'testreference',
    PickupDateRangeBegin   => '20090101',
    PickupDateRangeEnd     => DateTime->today,
    ShipperNumber          => '12345',
    DestinationPostalCode  => '1070',
    DestinationCountryCode => 'AT',
    OriginPostalCode       => '91058',
    OriginCountryCode      => 'DE',
    CustomerContext        => 'testcontext',
);
my $datecheck = DateTime->today->ymd('');
like(
    $request2->tracking_request,
    qr|<TrackRequest><Request><RequestAction>Track</RequestAction><RequestOption>activity</RequestOption><TransactionReference><CustomerContext>testcontext</CustomerContext></TransactionReference></Request><ReferenceNumber><Value>testreference</Value></ReferenceNumber><ShipperNumber>12345</ShipperNumber><DestinationPostalCode>1070</DestinationPostalCode><DestinationCountryCode>AT</DestinationCountryCode><OriginPostalCode>91058</OriginPostalCode><OriginCountryCode>DE</OriginCountryCode><PickupDateRange><BeginDate>20090101</BeginDate><EndDate>$datecheck</EndDate></PickupDateRange><ShipmentType><Code>01</Code></ShipmentType></TrackRequest>|,
    'Check track request 2'
);

my $request3
    = $tracking->request( ShipmentIdentificationNumber => '1234567890', );
like(
    $request3->tracking_request,
    qr|<TrackRequest><Request><RequestAction>Track</RequestAction><RequestOption>activity</RequestOption></Request><ShipmentIdentificationNumber>1234567890</ShipmentIdentificationNumber></TrackRequest>|,
    'Check track request 3'
);

