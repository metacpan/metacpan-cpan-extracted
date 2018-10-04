use strict;
use warnings;

use Test::Most;
use API::DeutscheBahn::Fahrplan;


# SETUP

note 'basic object tests';

my $fahrplan_free = API::DeutscheBahn::Fahrplan->new;
isa_ok $fahrplan_free, 'API::DeutscheBahn::Fahrplan';

my $fahrplan_plus = API::DeutscheBahn::Fahrplan->new( access_token => '123' );
isa_ok $fahrplan_plus, 'API::DeutscheBahn::Fahrplan';


# construct the user agent string
my $user_agent = sprintf 'Perl-API::DeutscheBahn::Fahrplan::%s',
    $API::DeutscheBahn::Fahrplan::VERSION;


cmp_deeply $fahrplan_free->_client->default_headers,
    { Accept => 'application/json', 'User-Agent' => $user_agent },
    'set correct headers for Fahrplan free';

cmp_deeply $fahrplan_plus->_client->default_headers,
    {
    Accept        => 'application/json',
    'User-Agent'  => $user_agent,
    Authorization => 'Bearer 123',
    },
    'set correct headers for Fahrplan plus';


note 'testing uri generation';


my @uri_tests = (

    # Successful

    {    #
        method => 'location',
        params => { name => 'Berlin' },
        regex  => qr!/location/Berlin$!,
    },
    {    #
        method => 'arrival_board',
        params => { id => '8596008', date => '2018-10-2' },
        regex  => qr!/arrivalBoard/8596008\?date=2018-10-2$!,
    },
    {    #
        method => 'departure_board',
        params => { id => '8596008', date => '2018-10-23T11:34::00' },
        regex => qr!/departureBoard/8596008\?date=2018-10-23T11%3A34%3A%3A00!,
    },
    {    #
        method => 'journey_details',
        params => { id => '8596008' },
        regex  => qr!/journeyDetails/8596008$!,
    },

    # Failures

    {    #
        method       => 'location',
        params       => {},
        throws       => 1,
        throws_regex => qr/Missing path parameter: name/,
    },
    {    #
        method       => 'departure_board',
        params       => { id => '8596008' },
        throws       => 1,
        throws_regex => qr/Missing query parameter: date/,
    }
);

for (@uri_tests) {

    my ( $method, %params ) = ( $_->{method}, %{ $_->{params} } );

    if ( $_->{throws} ) {
        throws_ok { $fahrplan_free->_create_uri( $method, %params ) }
        $_->{throws_regex}, 'error thrown successfully'
            and next;
    }

    my ( undef, $uri ) = $fahrplan_free->_create_uri( $method, %params );

    is $uri->scheme, 'https', 'uri scheme set to https';
    is $uri->host, 'api.deutschebahn.com', 'uri host set';

    like $uri->path_query, $_->{regex},
        sprintf 'successfully created uri for %s', $method;
}

done_testing;
