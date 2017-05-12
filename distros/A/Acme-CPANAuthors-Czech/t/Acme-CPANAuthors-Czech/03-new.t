# Pragmas.
use strict;
use warnings;

# Modules.
use Acme::CPANAuthors;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Acme::CPANAuthors->new('Czech');
isa_ok($obj, 'Acme::CPANAuthors');
