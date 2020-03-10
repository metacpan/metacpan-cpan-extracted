use strict;
use warnings;

use Acme::CPANAuthors;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Acme::CPANAuthors->new('Slovak');
my @ret = $obj->id;
my @right_ret = ('BARNEY', 'JKUTEJ', 'PALI');
is_deeply(\@ret, \@right_ret, 'CPAN authors ids.');
