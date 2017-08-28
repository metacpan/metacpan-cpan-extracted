use Test::More tests => 52;

use lib '../blib/lib','../blib/arch';

use_ok ("Algorithm::Cluster");
require_ok ("Algorithm::Cluster");


#########################

#------------------------------------------------------
# Tests
#

my $node;

my $node1 = Algorithm::Cluster::Node->new(1,2,3.1);
my $node2 = Algorithm::Cluster::Node->new(-1,3,5.3);
my $node3 = Algorithm::Cluster::Node->new(4,0,5.9);
my $node4 = Algorithm::Cluster::Node->new(-2,-3,7.8);
my @nodes = [$node1,$node2,$node3,$node4];

my $tree = Algorithm::Cluster::Tree->new(@nodes);
is ($tree->length, 4);

$node = $tree->get(0);
is ($node->left, 1);
is ($node->right, 2);
is (sprintf ("%7.4f", $node->distance), ' 3.1000');

$node = $tree->get(1);
is ($node->left, -1);
is ($node->right, 3);
is (sprintf ("%7.4f", $node->distance), ' 5.3000');

$node = $tree->get(2);
is ($node->left, 4);
is ($node->right, 0);
is (sprintf ("%7.4f", $node->distance), ' 5.9000');

$node = $tree->get(3);
is ($node->left, -2);
is ($node->right, -3);
is (sprintf ("%7.4f", $node->distance), ' 7.8000');

my @indices = $tree->sort();
is ($indices[0], 1);
is ($indices[1], 2);
is ($indices[2], 3);
is ($indices[3], 4);
is ($indices[4], 0);

my $order =  [ 3,4,5,1,2 ];
@indices = $tree->sort($order);

$node = $tree->get(0);
is ($node->left, 1);
is ($node->right, 2);
is (sprintf ("%7.4f", $node->distance), ' 3.1000');

$node = $tree->get(1);
is ($node->left, 3);
is ($node->right, -1);
is (sprintf ("%7.4f", $node->distance), ' 5.3000');

$node = $tree->get(2);
is ($node->left, 4);
is ($node->right, 0);
is (sprintf ("%7.4f", $node->distance), ' 5.9000');

$node = $tree->get(3);
is ($node->left, -3);
is ($node->right, -2);
is (sprintf ("%7.4f", $node->distance), ' 7.8000');

is ($indices[0], 4);
is ($indices[1], 0);
is ($indices[2], 3);
is ($indices[3], 1);
is ($indices[4], 2);

my @clusterids = $tree->cut(1);
is ($clusterids[0], 0);
is ($clusterids[1], 0);
is ($clusterids[2], 0);
is ($clusterids[3], 0);
is ($clusterids[4], 0);

@clusterids = $tree->cut();
is ($clusterids[0], 1);
is ($clusterids[1], 3);
is ($clusterids[2], 4);
is ($clusterids[3], 2);
is ($clusterids[4], 0);

@clusterids = $tree->cut(3);
is ($clusterids[0], 1);
is ($clusterids[1], 2);
is ($clusterids[2], 2);
is ($clusterids[3], 2);
is ($clusterids[4], 0);
