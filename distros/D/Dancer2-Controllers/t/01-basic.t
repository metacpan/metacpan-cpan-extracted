package Test::Controller;

use strict;
use warnings;
use Moose;

BEGIN { extends 'Dancer2::Controllers::Controller' }

sub hello_world : Route(get => /) {
    return "Hello World!";
}

sub foo : Route(get => /foo) {
    return 'Foo!';
}

1;

package main;

use Test::More;
use Test::Exception;
use Plack::Test;
use HTTP::Request::Common;
use Dancer2;
use strict;
use warnings;
use Dancer2::Controllers qw(controllers);

lives_ok { controllers( ['Test::Controller'] ) };

my $app = to_app;

my $test = Plack::Test->create($app);

my $response = $test->request( GET '/' );

ok( $response->is_success, 'Success' );
is( $response->content, 'Hello World!', 'Correct content' );

$response = $test->request( GET '/foo' );

ok( $response->is_success, 'Success' );
is( $response->content, 'Foo!', 'Correct content' );

done_testing
