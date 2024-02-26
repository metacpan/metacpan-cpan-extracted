package MyApp::Controller;

use Moo;

use strict;
use warnings;

with 'Dancer2::Controllers::Controller';

sub hello_world {
    "Hello World!";
}

sub foo {
    "Foo!";
}

sub routes {
    return [
        [ 'get' => '/'    => 'hello_world' ],
        [ 'get' => '/foo' => 'foo' ],

        # Or, pass inline subs
        [ 'get' => '/inline' => sub { 'Inline!!!' } ]
    ];
}

1;

use Dancer2;
use Dancer2::Controllers;

set port => 8080;

controllers( ['MyApp::Controller'] );

dance;
