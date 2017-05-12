use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $class1 = [ { a => 1, b => 1, c => 1 }, { d => 1, e => 1, f => 1 } ];
my $class2 = [ { a => 1, b => 1 }, { c => 1, d => 1, e => 1 }, { f => 1 } ];

my $sim = Cluster::Similarity->new();

$sim->load_data($class1, $class2);

my $rand_adj = sprintf('%.5f', $sim->rand_adjusted());

# my $exp_rand_adj = sprintf('%.5f', (2-8/5)/(5-8/5));
my $exp_rand_adj = sprintf('%.5f', (2-8/5)/(4-8/5));

ok($rand_adj == $exp_rand_adj, "rand index adjusted: got $rand_adj, expected $exp_rand_adj");

$sim->load_data($class1, $class1);

$rand_adj = sprintf('%.5f', $sim->rand_adjusted());

ok($rand_adj == 1, "Rand index adjusted for same classification: $rand_adj");

1;
