use strict;
use warnings;

use Acme::CPANAuthors;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Acme::CPANAuthors->new('Slovak');
my $ret = $obj->count;
is($ret, 6, 'Count of Slovak CPAN authors.');
