#!perl

package TestApp;
use strict;
use warnings;
use Catalyst;

TestApp->setup;

sub hello_world {
    return 'Hello, world.';
}

1;
