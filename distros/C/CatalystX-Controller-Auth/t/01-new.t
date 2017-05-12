use strict;
use warnings;

use Test::More;
use Test::Exception;

use CatalystX::Controller::Auth;

my $controller;

lives_ok { $controller = CatalystX::Controller::Auth->new } "instantiated ok";



done_testing();
