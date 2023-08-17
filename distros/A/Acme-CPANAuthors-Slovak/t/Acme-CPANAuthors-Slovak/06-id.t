use strict;
use warnings;

use Acme::CPANAuthors;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Acme::CPANAuthors->new('Slovak');
my @ret = $obj->id;
my @right_ret = ('BARNEY', 'JKUTEJ', 'KOZO', 'LKUNDRAK', 'PALI', 'SAMSK');
is_deeply(\@ret, \@right_ret, 'CPAN authors ids.');
