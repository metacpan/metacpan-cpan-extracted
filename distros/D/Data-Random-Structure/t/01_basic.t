use Test::More;

use strict;
use warnings;

use Data::Random::Structure;

my $g = Data::Random::Structure->new();

my $ref = $g->generate();

diag explain $ref;

ok(1);

done_testing();
