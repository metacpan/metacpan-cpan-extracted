use strict;
use warnings;

use App::HL7::Send;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::HL7::Send->new;
isa_ok($obj, 'App::HL7::Send');
