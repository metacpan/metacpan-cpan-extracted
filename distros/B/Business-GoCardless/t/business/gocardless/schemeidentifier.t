#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::SchemeIdentifier' );
isa_ok(
    my $SchemeIdentifier = Business::GoCardless::SchemeIdentifier->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::SchemeIdentifier'
);

can_ok(
    $SchemeIdentifier,
    qw/
        endpoint
        address_line1
        address_line2
        address_line3
        can_specify_mandate_reference
        city
        country_code
        created_at
        currency
        email
        id
        minimum_advance_notice
        name
        phone_number
        postal_code
        reference
        region
        scheme
        status

        pending
        active
    /,
);

is( $SchemeIdentifier->endpoint,'/scheme_identifiers/%s','endpoint' );
is( $SchemeIdentifier->uri,'https://api.gocardless.com/scheme_identifiers/ID123','->uri' );

note( "status checks" );

ok( ! $SchemeIdentifier->pending,'! ->pending when no status' );

my @statuses = qw/ pending active /;

foreach my $status ( @statuses ) {
    $SchemeIdentifier->status( $status );
    ok( $SchemeIdentifier->$status,"->$status" );
    ok( ! $SchemeIdentifier->$_,"! ->$_ when $status" )
        for grep { $_ ne $status } @statuses;
}

done_testing();

# vim: ts=4:sw=4:et
