use strict;
use warnings;
use Test::More;
use Business::UPS;

# Mock LWP::UserAgent to avoid real HTTP requests
my @mock_responses;

{
    no warnings 'redefine';
    *LWP::UserAgent::new = sub { bless {}, 'LWP::UserAgent' };
    *LWP::UserAgent::post = sub {
        my ( $self, $url, @args ) = @_;
        my $resp = shift @mock_responses;
        return $resp;
    };
}

# Helper to create a mock HTTP::Response-like object
{
    package MockResponse;
    sub new {
        my ( $class, %args ) = @_;
        bless \%args, $class;
    }
    sub is_success { return $_[0]->{success} }
    sub content    { return $_[0]->{content} }
}

# Sample JSON response mimicking UPS tracking API
my $delivered_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z12345E0205271688",
      "packageStatus": "Delivered",
      "deliveredDate": "Wednesday, 01/14/2026",
      "deliveredTime": "11:57 A.M.",
      "receivedBy": "SMITH",
      "leftAt": "Front Door",
      "shipToAddress": {
        "city": "ANYTOWN",
        "state": "CA",
        "country": "US"
      },
      "weight": {
        "weight": "5.00",
        "unitOfMeasurement": "LBS"
      },
      "service": "UPS Ground",
      "shipmentProgressActivities": [
        {
          "date": "January 14, 2026",
          "time": "11:57 A.M.",
          "location": "ANYTOWN, CA, US",
          "activityScan": "Delivered"
        },
        {
          "date": "January 13, 2026",
          "time": "6:30 A.M.",
          "location": "ANYTOWN, CA, US",
          "activityScan": "Out For Delivery Today"
        },
        {
          "date": "January 12, 2026",
          "time": "9:15 P.M.",
          "location": "ONTARIO, CA, US",
          "activityScan": "Arrival Scan"
        }
      ]
    }
  ]
}
JSON

subtest 'UPStrack returns delivered package details' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $delivered_json ),
    );

    my %result = UPStrack("1Z12345E0205271688");

    is( $result{'Current Status'}, 'Delivered', 'status is Delivered' );
    is( $result{'Service Type'},   'UPS Ground', 'service type' );
    is( $result{'Weight'},         '5.00 LBS', 'weight' );
    is( $result{'Signed By'},      'SMITH', 'signed by / received by' );
    like( $result{'Shipped To'}, qr/ANYTOWN.*CA.*US/, 'shipped to address' );
    is( $result{'Activity Count'}, 3, 'activity count' );

    my %scanning = %{ $result{'Scanning'} };
    is( $scanning{1}{'activity'}, 'Delivered', 'first activity' );
    is( $scanning{1}{'date'},     'January 14, 2026', 'first activity date' );
    is( $scanning{1}{'time'},     '11:57 A.M.', 'first activity time' );
    like( $scanning{1}{'location'}, qr/ANYTOWN/, 'first activity location' );

    is( $scanning{3}{'activity'}, 'Arrival Scan', 'third activity' );

    ok( exists $result{'Notice'}, 'notice exists' );
};

my $in_transit_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z12345E0205271688",
      "packageStatus": "In Transit",
      "scheduledDeliveryDate": "Thursday, 01/15/2026",
      "shipToAddress": {
        "city": "NEW YORK",
        "state": "NY",
        "country": "US"
      },
      "weight": {
        "weight": "10.00",
        "unitOfMeasurement": "LBS"
      },
      "service": "2nd Day Air",
      "shipmentProgressActivities": [
        {
          "date": "January 13, 2026",
          "time": "3:00 P.M.",
          "location": "CHICAGO, IL, US",
          "activityScan": "Departure Scan"
        }
      ]
    }
  ]
}
JSON

subtest 'UPStrack returns in-transit package details' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $in_transit_json ),
    );

    my %result = UPStrack("1Z12345E0205271688");

    is( $result{'Current Status'}, 'In Transit', 'status is In Transit' );
    is( $result{'Delivery Date'},  'Thursday, 01/15/2026', 'scheduled delivery date' );
    is( $result{'Activity Count'}, 1, 'one activity' );
};

subtest 'UPStrack dies on HTTP failure' => sub {
    @mock_responses = (
        MockResponse->new( success => 0, content => '' ),
    );

    eval { UPStrack("1Z12345E0205271688") };
    like( $@, qr/UPS/i, 'dies on HTTP failure' );
};

subtest 'UPStrack dies on missing tracking number' => sub {
    eval { UPStrack("") };
    like( $@, qr/tracking/i, 'dies on empty tracking number' );
};

subtest 'UPStrack dies on invalid JSON response' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => 'not json' ),
    );

    eval { UPStrack("1Z12345E0205271688") };
    like( $@, qr/parse|JSON/i, 'dies on invalid JSON' );
};

subtest 'UPStrack dies when trackDetails missing' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => '{"error":"not found"}' ),
    );

    eval { UPStrack("INVALID") };
    like( $@, qr/tracking/i, 'dies on missing trackDetails' );
};

done_testing();
