#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::InstalmentSchedule' );
isa_ok(
    my $Schedule = Business::GoCardless::InstalmentSchedule->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
        links  => {
            customer => 'CU123',
            mandate  => 'MD123',
        },
    ),
    'Business::GoCardless::InstalmentSchedule'
);

can_ok(
    $Schedule,
    qw/
        endpoint
        created_at
        currency
        id
        links
        metadata
        name
        payment_errors
        status
        total_amount

        update
        cancel

        pending
        active
        creation_failed
        completed
        cancelled
        errored

        customer_id
        mandate_id
    /,
);

is( $Schedule->endpoint,'/instalment_schedules/%s','endpoint' );
is( $Schedule->uri,'https://api.gocardless.com/instalment_schedules/ID123','->uri' );

note( "status checks" );

ok( ! $Schedule->pending,'! ->pending when no status' );

my @statuses = qw/ pending active creation_failed completed cancelled errored /;

foreach my $status ( @statuses ) {
    $Schedule->status( $status );
    ok( $Schedule->$status,"->$status" );
    ok( ! $Schedule->$_,"! ->$_ when $status" )
        for grep { $_ ne $status } @statuses;
}

note( "links" );

is( $Schedule->customer_id,'CU123','->customer_id' );
is( $Schedule->mandate_id,'MD123','->mandate_id' );

$Schedule->links( undef );
ok( ! $Schedule->customer_id,'! ->customer_id when no links' );

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

$mock->mock( 'content',sub { '{"instalment_schedules":{"id":"ID123","status":"after update"}}' } );

isa_ok(
    $Schedule->update( metadata => { foo => 'bar' } ),
    'Business::GoCardless::InstalmentSchedule',
    '->update'
);
is( $request->method,'PUT','->update PUTs' );
like( $request->uri,qr!/instalment_schedules/ID123$!,'->update request path' );
cmp_deeply(
    JSON->new->decode( $request->content ),
    { instalment_schedules => { metadata => { foo => 'bar' } } },
    '->update request body'
);
is( $Schedule->status,'after update','->update updates the object' );

$mock->mock( 'content',sub { '{"instalment_schedules":{"id":"ID123","status":"after cancel"}}' } );

isa_ok(
    $Schedule->cancel,
    'Business::GoCardless::InstalmentSchedule',
    '->cancel'
);
is( $request->method,'POST','->cancel POSTs' );
like( $request->uri,qr!/instalment_schedules/ID123/actions/cancel$!,'->cancel request path' );
ok( ! length( $request->content ),'->cancel has no request body' );
is( $Schedule->status,'after cancel','->cancel updates the object' );

done_testing();

# vim: ts=4:sw=4:et
