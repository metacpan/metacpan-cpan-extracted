use strict;
use warnings;
use Test::More;
use Business::UPS;

# Capture deprecation warnings
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# Mock LWP::UserAgent to avoid real HTTP requests
my @mock_responses;

{
    no warnings 'redefine';
    *LWP::UserAgent::new = sub { bless {}, 'LWP::UserAgent' };
    *LWP::UserAgent::get = sub {
        my ( $self, $url ) = @_;
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

# The old UPS CGI returned %-delimited fields:
#   0=server 1=product 2=origzip 3=origcountry 4=destzip 5=destcountry
#   6=zone 7=weight 8=subtotal 9=addt_charges 10=total
my $success_response = 'UPSOnLine3%GNDCOM%23606%US%23607%US%002%50%7.50%0.25%7.75';
my $error_response   = 'UPSOnLine3%GNDCOM%23606%US%00000%%0%50%0%0%0';

subtest 'getUPS emits deprecation warning' => sub {
    @warnings = ();
    @mock_responses = (
        MockResponse->new( success => 1, content => $success_response ),
    );

    getUPS(qw/GNDCOM 23606 23607 50/);

    is( scalar @warnings, 1, 'exactly one warning emitted' );
    like( $warnings[0], qr/deprecated/i, 'warning mentions deprecation' );
    like( $warnings[0], qr/qcostcgi/,    'warning mentions retired endpoint' );
};

subtest 'getUPS returns shipping cost and zone on success' => sub {
    @warnings = ();
    @mock_responses = (
        MockResponse->new( success => 1, content => $success_response ),
    );

    my ( $shipping, $zone, $error ) = getUPS(qw/GNDCOM 23606 23607 50/);

    is( $shipping, '7.75', 'total shipping cost' );
    is( $zone,     '002',  'UPS zone' );
    is( $error,    undef,  'no error on success' );
};

subtest 'getUPS returns error when UPS reports failure' => sub {
    @mock_responses = (
        MockResponse->new( success => 1, content => $error_response ),
    );

    my ( $shipping, $zone, $error ) = getUPS(qw/GNDCOM 23606 00000 50/);

    is( $shipping, undef, 'no shipping on error' );
    is( $zone,     undef, 'no zone on error' );
    ok( defined $error,   'error message returned' );
};

subtest 'getUPS dies on HTTP failure' => sub {
    @mock_responses = (
        MockResponse->new( success => 0, content => '' ),
    );

    eval { getUPS(qw/GNDCOM 23606 23607 50/) };
    like( $@, qr/Failed/i, 'dies on HTTP failure' );
};

subtest 'getUPS passes optional parameters' => sub {
    my $captured_url;
    {
        no warnings 'redefine';
        *LWP::UserAgent::get = sub {
            my ( $self, $url ) = @_;
            $captured_url = $url;
            return MockResponse->new( success => 1, content => $success_response );
        };
    }

    getUPS( 'XPR', '23606', 'B67JH', '10', 'GB', 'Regular Daily Pickup',
        '12', '8', '6', undef, undef );

    like( $captured_url, qr/22_destCountry=GB/,                'country param' );
    like( $captured_url, qr/47_rate_chart=Regular/,            'rate chart param' );
    like( $captured_url, qr/25_length=12/,                     'length param' );
    like( $captured_url, qr/26_width=8/,                       'width param' );
    like( $captured_url, qr/27_height=6/,                      'height param' );

    # Restore normal mock
    no warnings 'redefine';
    *LWP::UserAgent::get = sub {
        my ( $self, $url ) = @_;
        return shift @mock_responses;
    };
};

subtest 'getUPS defaults country to US' => sub {
    my $captured_url;
    {
        no warnings 'redefine';
        *LWP::UserAgent::get = sub {
            my ( $self, $url ) = @_;
            $captured_url = $url;
            return MockResponse->new( success => 1, content => $success_response );
        };
    }

    getUPS(qw/GNDCOM 23606 23607 50/);

    like( $captured_url, qr/22_destCountry=US/, 'defaults to US' );
};

subtest 'getUPS includes oversized and COD flags' => sub {
    my $captured_url;
    {
        no warnings 'redefine';
        *LWP::UserAgent::get = sub {
            my ( $self, $url ) = @_;
            $captured_url = $url;
            return MockResponse->new( success => 1, content => $success_response );
        };
    }

    # Args: product, origin, dest, weight, country, rate_chart, length, width, height, oversized, cod
    getUPS( 'GNDCOM', '23606', '23607', '50', 'US', '', '', '', '', 1, 1 );

    like( $captured_url, qr/29_oversized=1/, 'oversized flag' );
    like( $captured_url, qr/30_cod=1/,       'COD flag' );
};

done_testing();
