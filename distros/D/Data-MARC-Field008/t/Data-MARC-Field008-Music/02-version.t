use strict;
use warnings;

use Data::MARC::Field008::Music;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Field008::Music::VERSION, 0.03, 'Version.');
