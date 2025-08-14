use strict;
use warnings;

use CAD::Format::DWG::Version;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = CAD::Format::DWG::Version->new;
isa_ok($obj, 'CAD::Format::DWG::Version');
