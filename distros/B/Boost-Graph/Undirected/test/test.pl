use lib qw(lib/perl5/site_perl/5.8.5/i686-linux-thread-multi/);
use Boost::Graph::Undirected;
use Data::Dumper;

my $bg = new Boost::Graph::Undirected;
$bg->_addNode(0);
$bg->_addEdge(0,1,2.5);
$bg->_addEdge(1,2,1);
$bg->_addEdge(2,3,4);
my $ret = $bg->allPairsShortestPathsJohnson(0,3);
print Dumper $ret;

