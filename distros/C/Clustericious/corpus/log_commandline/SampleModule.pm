package SampleModule;

use strict;
use warnings;
use Log::Log4perl qw(:easy);

sub test
{
  TRACE "test trace message";
  DEBUG "test debug message";
  INFO  "test info  message";
  WARN  "test warn  message";
  ERROR "test error message";
  FATAL "test fatal message";
}

1;
