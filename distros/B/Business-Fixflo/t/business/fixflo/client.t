#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;

use_ok( 'Business::Fixflo::Client' );
isa_ok(
    my $Client = Business::Fixflo::Client->new(
        username      => 'foo',
        password      => 'baz',
        custom_domain => 'boz',
    ),
    'Business::Fixflo::Client'
);

can_ok(
    $Client,
    qw/
        api_key
        username
        password
        custom_domain
    /,
);

throws_ok(
    sub { Business::Fixflo::Client->new( custom_domain => 'foo' ) },
    qr/api_key or username \+ password required/,
    'Client->new throws api_key or username + password not set'
);

throws_ok(
    sub { Business::Fixflo::Client->new(
        custom_domain => 'foo',
        username      => 'foo',
    ) },
    qr/api_key or username \+ password required/,
    'Client->new throws api_key or username + password not set'
);

throws_ok(
    sub { Business::Fixflo::Client->new(
        custom_domain => 'foo',
        password      => 'foo',
    ) },
    qr/api_key or username \+ password required/,
    'Client->new throws api_key or username + password not set'
);

# monkey patching LWP here to make this test work without
# having to actually hit the endpoints or use credentials
no warnings 'redefine';
no warnings 'once';
my $mock = Test::MockObject->new;
$mock->mock( 'is_success',sub { 1 } );
$mock->mock( 'headers',sub { $mock } );
$mock->mock( 'header',sub { 'application/json' } );
$mock->mock( 'content',sub { '{ "Id" : 1 }' } );
*LWP::UserAgent::request = sub { $mock };

cmp_deeply(
    $Client->api_get( 'Issue' ),
    { Id => 1 },
    'api_get'
);

cmp_deeply(
    $Client->api_post( 'Issue' ),
    { Id => 1 },
    'api_post'
);

cmp_deeply(
    $Client->api_delete( 'Issue' ),
    { Id => 1 },
    'api_delete'
);

done_testing();

# vim: ts=4:sw=4:et
