use strict;
use warnings;

use App::CPAN::Search;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::CPAN::Search->new;
isa_ok($obj, 'App::CPAN::Search');
