use lib qw(lib/perl5/site_perl/5.8.5/i686-linux-thread-multi/);
use Boost::Graph::Directed;

my $bg = new Boost::Graph::Directed;
$bg->_addNode(0);
$bg->_addEdge(0,1,2.5);



