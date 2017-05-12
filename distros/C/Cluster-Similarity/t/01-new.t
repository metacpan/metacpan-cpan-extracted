use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $sim = Cluster::Similarity->new();

isa_ok($sim, 'Cluster::Similarity', 'built Cluster::Similarity object');

1;
