use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $class1 = [ { a => 1, b => 1, c => 1 }, { d => 1, e => 1, f => 1 } ];
my $class2 = [ { a => 1, b => 1 }, { c => 1, d => 1, e => 1 }, { f => 1 } ];

my $sim = Cluster::Similarity->new();

$sim->load_data($class1, $class2);

my $ri = sprintf('%.3f', $sim->rand_index());

my $exp_ri = sprintf('%.3f', 9/15);

ok($ri == $exp_ri, "rand index: got $ri, expected $exp_ri");

$sim->load_data($class1, $class1);

$ri = sprintf('%.3f', $sim->rand_index());

ok($ri == 1, "rand index of twice the same classification: $ri\n");

1;
