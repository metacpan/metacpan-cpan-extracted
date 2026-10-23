#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::CustomerNotification' );
isa_ok(
    my $Notification = Business::GoCardless::CustomerNotification->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::CustomerNotification'
);

can_ok(
    $Notification,
    qw/
        endpoint
        action_taken
        action_taken_at
        action_taken_by
        id
        links
        type

        handle
    /,
);

is( $Notification->endpoint,'/customer_notifications/%s','endpoint' );
is( $Notification->uri,'https://api.gocardless.com/customer_notifications/ID123','->uri' );

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

$mock->mock( 'content',sub { '{"customer_notifications":{"id":"ID123","action_taken":"after handle"}}' } );

isa_ok(
    $Notification->handle,
    'Business::GoCardless::CustomerNotification',
    '->handle'
);
is( $request->method,'POST','->handle POSTs' );
like( $request->uri,qr!/customer_notifications/ID123/actions/handle$!,'->handle request path' );
ok( ! length( $request->content ),'->handle has no request body' );
is( $Notification->action_taken,'after handle','->handle updates the object' );

done_testing();

# vim: ts=4:sw=4:et
