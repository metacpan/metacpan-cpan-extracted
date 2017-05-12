use Log::Log4perl qw(:easy);
use Clustericious::Log::CommandLine qw(:all);

use lib '.';
use SampleModule;

SampleModule::test();

TRACE "trace message";
DEBUG "debug message";
INFO  "info  message";
WARN  "warn  message";
ERROR "error message";
FATAL "fatal message";
