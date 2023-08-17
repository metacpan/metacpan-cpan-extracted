use strict;
use warnings;

use App::Wikidata::Print;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Wikidata::Print->new;
isa_ok($obj, 'App::Wikidata::Print');
