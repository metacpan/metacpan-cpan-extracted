use strict;
use warnings;

use Data::MARC::Field008::ComputerFile;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Field008::ComputerFile::VERSION, 0.03, 'Version.');
