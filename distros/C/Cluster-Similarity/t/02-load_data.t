use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Cluster::Similarity;

my $class1 = [ { a => 1, b => 1, c => 1 }, { d => 1, e => 1, f => 1 } ];
my $class2 = [ { a => 1, b => 1 }, { c => 1, d => 1, e => 1 }, { f => 1 } ];

my $sim = Cluster::Similarity->new();

$sim->load_data($class1, $class2);

my $ret_class1 = $sim->get_classification_1();

my $exp_class1 = { map { my $index = $_+1; "c_$index" => $class1->[$_] } 0 .. $#{ $class1 } };


is_deeply($ret_class1, $exp_class1, 'data set is same as data got');

1;
