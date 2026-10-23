#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::OutboundPayment' );
isa_ok(
    my $OutboundPayment = Business::GoCardless::OutboundPayment->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::OutboundPayment'
);

can_ok(
    $OutboundPayment,
    qw/
        endpoint
        amount
        created_at
        currency
        description
        execution_date
        id
        is_withdrawal
        links
        metadata
        reference
        scheme
        status
        verifications

        update
        approve
        cancel

        verifying
        pending_approval
        scheduled
        executing
        executed
        cancelled
        failed
    /,
);

is( $OutboundPayment->endpoint,'/outbound_payments/%s','endpoint' );
is( $OutboundPayment->uri,'https://api.gocardless.com/outbound_payments/ID123','->uri' );

note( "status checks" );

ok( ! $OutboundPayment->verifying,'! ->verifying when no status' );

my @statuses = qw/ verifying pending_approval scheduled executing executed cancelled failed /;

foreach my $status ( @statuses ) {
    $OutboundPayment->status( $status );
    ok( $OutboundPayment->$status,"->$status" );
    ok( ! $OutboundPayment->$_,"! ->$_ when $status" )
        for grep { $_ ne $status } @statuses;
}

note( "operations" );

# monkey patching LWP here to make this test work without
# having to actually hit the endpoints or use credentials
no warnings 'redefine';
no warnings 'once';
my $mock = Test::MockObject->new;
my $request;
$mock->mock( 'is_success',sub { 1 } );
$mock->mock( 'header',sub {} );
*LWP::UserAgent::request = sub { $request = $_[1]; $mock };

$mock->mock( 'content',sub { '{"outbound_payments":{"id":"ID123","status":"after update"}}' } );

isa_ok(
    $OutboundPayment->update( metadata => { foo => 'bar' } ),
    'Business::GoCardless::OutboundPayment',
    '->update'
);
is( $request->method,'PUT','->update PUTs' );
like( $request->uri,qr!/outbound_payments/ID123$!,'->update request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { outbound_payments => { metadata => { foo => 'bar' } } },
    '->update request body'
);
is( $OutboundPayment->status,'after update','->update updates the object' );

$mock->mock( 'content',sub { '{"outbound_payments":{"id":"ID123","status":"after approve"}}' } );

isa_ok(
    $OutboundPayment->approve,
    'Business::GoCardless::OutboundPayment',
    '->approve'
);
is( $request->method,'POST','->approve POSTs' );
like( $request->uri,qr!/outbound_payments/ID123/actions/approve$!,'->approve request path' );
ok( ! length( $request->content ),'->approve has no request body' );
is( $OutboundPayment->status,'after approve','->approve updates the object' );

$mock->mock( 'content',sub { '{"outbound_payments":{"id":"ID123","status":"after cancel"}}' } );

isa_ok(
    $OutboundPayment->cancel( metadata => { reason => 'test' } ),
    'Business::GoCardless::OutboundPayment',
    '->cancel'
);
is( $request->method,'POST','->cancel POSTs' );
like( $request->uri,qr!/outbound_payments/ID123/actions/cancel$!,'->cancel request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { data => { metadata => { reason => 'test' } } },
    '->cancel request body'
);
is( $OutboundPayment->status,'after cancel','->cancel updates the object' );

done_testing();

# vim: ts=4:sw=4:et
