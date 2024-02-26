package MyController;

use Moose;
BEGIN { extends 'Dancer2::Controllers::Controller' }

sub foo : Route(get => /users/:id[Int]) {
    shift->request->params->{id};
}

1;

package main;

use Dancer2::Controllers;
use Dancer2 qw(!pass);
use Plack::Test;
use HTTP::Request::Common;
use Test::More;
use Test::Exception;
use strict;
use warnings;

lives_ok { controllers( ['MyController'] ) };

my $app = to_app;

my $test = Plack::Test->create($app);

my $response = $test->request( GET '/users/123' );

ok( $response->is_success, 'Success' );
is( $response->content, '123', 'Correct content' );

done_testing;
