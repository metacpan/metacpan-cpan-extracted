use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestApp;

eval {
    map { TestApp->controller($_) } TestApp->controllers;
};

ok(!$@, 'lives ok');

done_testing;