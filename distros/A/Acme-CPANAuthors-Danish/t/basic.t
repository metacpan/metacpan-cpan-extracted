use strict;
use warnings;
use Test::More;

use Acme::CPANAuthors;
use Acme::CPANAuthors::Danish;

my $authors = Acme::CPANAuthors->new('Danish');

# we can't be too broken if this works. testing for the individual authors
# would be silly.
isa_ok($authors, 'Acme::CPANAuthors');

is($authors->count, 15, 'How many Danish authors are there?');

done_testing;
