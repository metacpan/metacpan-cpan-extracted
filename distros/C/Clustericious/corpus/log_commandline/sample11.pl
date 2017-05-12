use Log::Log4perl qw(:easy);
use Clustericious::Log::CommandLine qw(:all :noinit handlelogoptions);

Log::Log4perl->easy_init($FATAL);

handlelogoptions();

TRACE "trace message";
DEBUG "debug message";
INFO  "info  message";
WARN  "warn  message";
ERROR "error message";
FATAL "fatal message";

Log::Log4perl::init('log4perl.conf');

handlelogoptions();

TRACE "trace message 2";
DEBUG "debug message 2";
INFO  "info  message 2";
WARN  "warn  message 2";
ERROR "error message 2";
FATAL "fatal message 2";
