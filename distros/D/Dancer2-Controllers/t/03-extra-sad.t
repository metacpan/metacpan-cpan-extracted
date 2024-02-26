package ControllerGuy;

use Moose;

BEGIN { extends 'Dancer2::Controllers::Controller' }

sub foo : Route {
    "foo";
}

1;

package main;

use Dancer2::Controllers;
use Dancer2 qw(!pass);
use Test::More;
use Test::Exception;
use strict;
use warnings;

dies_ok { controllers("foo!") } 'Dies when not array ref';
dies_ok { controllers( ['ControllerGuy'] ) }
'Dies when action is bad';
dies_ok { controllers( ['Dont::Exist'] ) }
'Dies when module does not exist';

done_testing;
