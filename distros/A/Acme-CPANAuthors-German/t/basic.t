use strict;
use warnings;
use Test::More;

use Acme::CPANAuthors;
use Acme::CPANAuthors::German;
use Acme::CPANAuthors::Austrian;

my $authors = Acme::CPANAuthors->new('German');

# we can't be too broken if this works. testing for the individual authors
# would be silly.
isa_ok($authors, 'Acme::CPANAuthors');

my $oesies = Acme::CPANAuthors->new('Austrian');
ok($oesies->count < $authors->count, 'motivate the austrian guy to break us');

done_testing;
