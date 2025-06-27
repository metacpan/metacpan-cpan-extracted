use strict;
use warnings;

use Data::MARC::Field008::Book;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Field008::Book::VERSION, 0.03, 'Version.');
