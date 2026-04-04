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

# Minimal response — only required fields present
my $minimal_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z999AA10123456784",
      "packageStatus": "Label Created"
    }
  ]
}
JSON

subtest 'UPStrack handles minimal response (no optional fields)' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $minimal_json ),
    );

    my %result = UPStrack("1Z999AA10123456784");

    is( $result{'Current Status'}, 'Label Created', 'status from minimal response' );
    ok( !exists $result{'Service Type'},   'no service type when missing' );
    ok( !exists $result{'Weight'},         'no weight when missing' );
    ok( !exists $result{'Shipped To'},     'no shipped-to when missing' );
    ok( !exists $result{'Delivery Date'},  'no delivery date when both dates missing' );
    ok( !exists $result{'Signed By'},      'no signed-by when missing' );
    ok( !exists $result{'Location'},       'no location when missing' );
    is( $result{'Activity Count'}, 0,      'zero activities' );
    is_deeply( $result{'Scanning'}, {},    'empty scanning hash' );
};

# Response with empty shipmentProgressActivities array
my $empty_activities_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z999AA10123456784",
      "packageStatus": "In Transit",
      "service": "UPS Ground",
      "scheduledDeliveryDate": "Monday, 01/20/2026",
      "shipmentProgressActivities": []
    }
  ]
}
JSON

subtest 'UPStrack handles empty activities array' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $empty_activities_json ),
    );

    my %result = UPStrack("1Z999AA10123456784");

    is( $result{'Current Status'},  'In Transit',            'status present' );
    is( $result{'Delivery Date'},   'Monday, 01/20/2026',    'scheduled delivery date' );
    is( $result{'Activity Count'},  0,                       'zero activities from empty array' );
    is_deeply( $result{'Scanning'}, {},                      'empty scanning hash' );
};

# Response with deliveredDate but no scheduledDeliveryDate
my $delivered_only_date_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z999AA10123456784",
      "packageStatus": "Delivered",
      "deliveredDate": "Friday, 01/17/2026",
      "shipToAddress": {
        "city": "PORTLAND"
      }
    }
  ]
}
JSON

subtest 'UPStrack uses deliveredDate as fallback' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $delivered_only_date_json ),
    );

    my %result = UPStrack("1Z999AA10123456784");

    is( $result{'Delivery Date'}, 'Friday, 01/17/2026', 'falls back to deliveredDate' );
    is( $result{'Shipped To'},    'PORTLAND',            'partial address (city only)' );
};

# Response with weight hash but no unitOfMeasurement
my $weight_no_unit_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z999AA10123456784",
      "packageStatus": "In Transit",
      "weight": {
        "weight": "12.50"
      }
    }
  ]
}
JSON

subtest 'UPStrack handles weight without unitOfMeasurement' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $weight_no_unit_json ),
    );

    my %result = UPStrack("1Z999AA10123456784");

    is( $result{'Weight'}, '12.50', 'weight value without trailing unit or space' );
};

# Response with weight hash but no weight value (only unit)
my $weight_no_value_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z999AA10123456784",
      "packageStatus": "In Transit",
      "weight": {
        "unitOfMeasurement": "KGS"
      }
    }
  ]
}
JSON

subtest 'UPStrack omits weight when weight value is missing' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $weight_no_value_json ),
    );

    my %result = UPStrack("1Z999AA10123456784");

    ok( !exists $result{'Weight'}, 'no weight key when weight value is missing' );
};

# Response with shipToAddress containing empty strings
my $empty_address_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z999AA10123456784",
      "packageStatus": "In Transit",
      "shipToAddress": {
        "city": "",
        "state": "",
        "country": "US"
      }
    }
  ]
}
JSON

subtest 'UPStrack filters empty address components' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $empty_address_json ),
    );

    my %result = UPStrack("1Z999AA10123456784");

    is( $result{'Shipped To'}, 'US', 'only non-empty address parts included' );
};

# Response with trackDetails as empty array
my $empty_details_json = '{"trackDetails": []}';

subtest 'UPStrack dies on empty trackDetails array' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $empty_details_json ),
    );

    eval { UPStrack("1Z999AA10123456784") };
    like( $@, qr/tracking/i, 'dies on empty trackDetails array' );
};

# Response with activity missing some fields
my $partial_activity_json = <<'JSON';
{
  "trackDetails": [
    {
      "trackingNumber": "1Z999AA10123456784",
      "packageStatus": "In Transit",
      "shipmentProgressActivities": [
        {
          "date": "January 15, 2026",
          "activityScan": "Departure Scan"
        }
      ]
    }
  ]
}
JSON

subtest 'UPStrack handles activities with missing fields' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $partial_activity_json ),
    );

    my %result = UPStrack("1Z999AA10123456784");

    is( $result{'Activity Count'}, 1, 'one activity' );
    my %scanning = %{ $result{'Scanning'} };
    is( $scanning{1}{'date'},     'January 15, 2026', 'date present' );
    is( $scanning{1}{'activity'}, 'Departure Scan',   'activity present' );
    ok( !exists $scanning{1}{'time'},     'time not present when missing' );
    ok( !exists $scanning{1}{'location'}, 'location not present when missing' );
};

subtest 'UPStrack dies on undef tracking number' => sub {
    eval { UPStrack(undef) };
    like( $@, qr/tracking/i, 'dies on undef tracking number' );
};

done_testing();
