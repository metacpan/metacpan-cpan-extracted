#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::BankAuthorisation' );
isa_ok(
    my $BankAuthorisation = Business::GoCardless::BankAuthorisation->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::BankAuthorisation'
);

can_ok(
    $BankAuthorisation,
    qw/
        endpoint
        authorisation_type
        authorised_at
        created_at
        expires_at
        id
        last_visited_at
        links
        qr_code_url
        redirect_uri
        url
    /,
);

is( $BankAuthorisation->endpoint,'/bank_authorisations/%s','endpoint' );
is( $BankAuthorisation->uri,'https://api.gocardless.com/bank_authorisations/ID123','->uri' );

done_testing();

# vim: ts=4:sw=4:et
