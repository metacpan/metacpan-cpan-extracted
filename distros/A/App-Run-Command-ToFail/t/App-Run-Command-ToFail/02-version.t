use strict;
use warnings;

use App::Run::Command::ToFail;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Run::Command::ToFail::VERSION, 0.06, 'Version.');
