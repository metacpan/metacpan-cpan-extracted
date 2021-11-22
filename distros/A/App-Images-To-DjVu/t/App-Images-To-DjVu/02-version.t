use strict;
use warnings;

use App::Images::To::DjVu;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Images::To::DjVu::VERSION, 0.01, 'Version.');
