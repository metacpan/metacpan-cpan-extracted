use strict;
use warnings;

use DateTime::Format::PDF;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = DateTime::Format::PDF->new;
isa_ok($obj, 'DateTime::Format::PDF');
