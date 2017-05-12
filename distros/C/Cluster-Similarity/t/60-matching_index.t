use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $class1 = [ { a => 1, b => 1, c => 1 }, { d => 1, e => 1, f => 1 } ];
my $class2 = [ { a => 1, b => 1 }, { c => 1, d => 1, e => 1 }, { f => 1 } ];

my $sim = Cluster::Similarity->new();

$sim->load_data($class1, $class2);

my $matching_index = sprintf('%.5f', $sim->matching_index());

my $exp_matching = sprintf('%.5f', 4/sqrt(96));

ok($matching_index == $exp_matching, "matching index: got $matching_index, expected $exp_matching");

$sim->load_data($class1, $class1);

$matching_index = sprintf('%.5f', $sim->matching_index());

ok($matching_index == 1, "Matching index for twice classification 1: $matching_index");

$sim->load_data($class2, $class2);

$matching_index = sprintf('%.5f', $sim->matching_index());

ok($matching_index == 1, "Matching index for twice classification 2: $matching_index");

1;
