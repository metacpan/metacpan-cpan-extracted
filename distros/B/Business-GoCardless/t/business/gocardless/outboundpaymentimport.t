#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::OutboundPaymentImport' );
isa_ok(
    my $Import = Business::GoCardless::OutboundPaymentImport->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::OutboundPaymentImport'
);

can_ok(
    $Import,
    qw/
        endpoint
        amount_sum
        authorisation_url
        created_at
        currency
        entry_counts
        id
        links
        status

        created
        validating
        invalid
        valid
        processing
        processed
        cancelled
    /,
);

is( $Import->endpoint,'/outbound_payment_imports/%s','endpoint' );
is( $Import->uri,'https://api.gocardless.com/outbound_payment_imports/ID123','->uri' );

note( "status checks" );

ok( ! $Import->created,'! ->created when no status' );

my @statuses = qw/ created validating invalid valid processing processed cancelled /;

foreach my $status ( @statuses ) {
    $Import->status( $status );
    ok( $Import->$status,"->$status" );
    ok( ! $Import->$_,"! ->$_ when $status" )
        for grep { $_ ne $status } @statuses;
}

done_testing();

# vim: ts=4:sw=4:et
