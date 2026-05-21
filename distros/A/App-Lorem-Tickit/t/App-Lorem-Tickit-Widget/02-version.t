use strict;
use warnings;

use App::Lorem::Tickit::Widget;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Lorem::Tickit::Widget::VERSION, 0.01, 'Version.');
