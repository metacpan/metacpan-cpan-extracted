# Tests with inline apps need to use Catalyst::Engine::Test
package TestApp;
use strict;
use warnings;

use Catalyst qw(Log::Colorful);
__PACKAGE__->setup();


package main;

use Test::More tests => 1;
use Catalyst::Test 'TestApp';

can_ok('Catalyst::Log', 'color');

1;
