use strict;
use warnings;
use Test::More;

use lib qw(./lib);
use Acme::Travigator;

my $directions = Acme::Travigator->travigate;
isnt($directions, undef, 'Got the directions');

done_testing;
