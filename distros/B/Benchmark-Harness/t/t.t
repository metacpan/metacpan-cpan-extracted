
use vars qw($CVS_VERSION); $CVS_VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

print "1..3\n";

use Benchmark::Harness::Trace;
print "ok Benchmark::Harness::Trace\n";
use Benchmark::Harness::TraceHighRes;
print "ok Benchmark::Harness::TraceHighRes\n";
use Benchmark::Harness::ValuesHighRes;
print "ok Benchmark::Harness::TraceHighRes\n";

1;
