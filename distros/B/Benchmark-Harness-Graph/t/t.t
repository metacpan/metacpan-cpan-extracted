
use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

print "1..2\n";

use Benchmark::Harness;
print "ok Benchmark::Harness\n";
use GD::Graph::lines;
print "ok GD::Graph::lines\n";

1;
