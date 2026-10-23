#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::Block' );
isa_ok(
    my $Block = Business::GoCardless::Block->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::Block'
);

can_ok(
    $Block,
    qw/
        endpoint
        active
        block_type
        created_at
        id
        reason_description
        reason_type
        resource_reference
        updated_at

        disable
        enable
    /,
);

is( $Block->endpoint,'/blocks/%s','endpoint' );
is( $Block->uri,'https://api.gocardless.com/blocks/ID123','->uri' );

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

$mock->mock( 'content',sub { '{"blocks":{"id":"ID123","active":"after disable"}}' } );

isa_ok(
    $Block->disable,
    'Business::GoCardless::Block',
    '->disable'
);
is( $request->method,'POST','->disable POSTs' );
like( $request->uri,qr!/blocks/ID123/actions/disable$!,'->disable request path' );
ok( ! length( $request->content ),'->disable has no request body' );
is( $Block->active,'after disable','->disable updates the object' );

$mock->mock( 'content',sub { '{"blocks":{"id":"ID123","active":"after enable"}}' } );

isa_ok(
    $Block->enable,
    'Business::GoCardless::Block',
    '->enable'
);
is( $request->method,'POST','->enable POSTs' );
like( $request->uri,qr!/blocks/ID123/actions/enable$!,'->enable request path' );
ok( ! length( $request->content ),'->enable has no request body' );
is( $Block->active,'after enable','->enable updates the object' );

done_testing();

# vim: ts=4:sw=4:et
