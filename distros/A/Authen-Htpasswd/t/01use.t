#!perl

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More 'no_plan';

use_ok('Authen::Htpasswd');
