#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use JSON ();

use Business::GoCardless::Client;

use_ok( 'Business::GoCardless::MandateImport' );
isa_ok(
    my $Import = Business::GoCardless::MandateImport->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            api_version => 2,
            base_url    => 'https://api.gocardless.com',
        ),
        id     => 'ID123',
    ),
    'Business::GoCardless::MandateImport'
);

can_ok(
    $Import,
    qw/
        endpoint
        created_at
        id
        links
        scheme
        status

        submit
        cancel

        created
        submitted
        cancelled
        processing
        processed
    /,
);

is( $Import->endpoint,'/mandate_imports/%s','endpoint' );
is( $Import->uri,'https://api.gocardless.com/mandate_imports/ID123','->uri' );

note( "status checks" );

ok( ! $Import->created,'! ->created when no status' );

my @statuses = qw/ created submitted cancelled processing processed /;

foreach my $status ( @statuses ) {
    $Import->status( $status );
    ok( $Import->$status,"->$status" );
    ok( ! $Import->$_,"! ->$_ when $status" )
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

$mock->mock( 'content',sub { '{"mandate_imports":{"id":"ID123","status":"after submit"}}' } );

isa_ok(
    $Import->submit,
    'Business::GoCardless::MandateImport',
    '->submit'
);
is( $request->method,'POST','->submit POSTs' );
like( $request->uri,qr!/mandate_imports/ID123/actions/submit$!,'->submit request path' );
ok( ! length( $request->content ),'->submit has no request body' );
is( $Import->status,'after submit','->submit updates the object' );

$mock->mock( 'content',sub { '{"mandate_imports":{"id":"ID123","status":"after cancel"}}' } );

isa_ok(
    $Import->cancel,
    'Business::GoCardless::MandateImport',
    '->cancel'
);
is( $request->method,'POST','->cancel POSTs' );
like( $request->uri,qr!/mandate_imports/ID123/actions/cancel$!,'->cancel request path' );
ok( ! length( $request->content ),'->cancel has no request body' );
is( $Import->status,'after cancel','->cancel updates the object' );

done_testing();

# vim: ts=4:sw=4:et
