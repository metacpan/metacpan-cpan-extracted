use Log::Log4perl qw(:easy);
use Clustericious::Log::CommandLine ':all',
                               ':loginit' => { layout => '[%-5p] %c %m%n' };

use lib '.';
use SampleModule;
use SampleModule2;

SampleModule::test();
SampleModule2::test();

TRACE "trace message";
DEBUG "debug message";
INFO  "info  message";
WARN  "warn  message";
ERROR "error message";
FATAL "fatal message";
