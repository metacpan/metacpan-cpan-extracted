use Test::More qw( no_plan );
use Test::Deep;

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $class1 = [ { a => 1, b => 1, c => 1 }, { d => 1, e => 1, f => 1 } ];
my $class2 = [ { a => 1, b => 1 }, { c => 1, d => 1, e => 1 }, { f => 1 } ];

my $sim = Cluster::Similarity->new();

$sim->load_data($class1, $class2);

my $objects = [ keys %{ $sim->objects() } ];

my $exp_objects = [ qw(a b c d e f) ];

cmp_bag($objects, $exp_objects, "classification objects");

my $nbr_of_objects = $sim->object_number();

ok($nbr_of_objects eq 6, 'number of classification objects'); 

1;
