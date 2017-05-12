#!perl

use strict;
use warnings FATAL => 'all';
no  warnings 'uninitialized';

use lib qw(lib);

use Apache::TestTrace;
use Apache::TestRunPerl ();

$Apache::TestTrace::Level = 'emerg';
  
Apache::TestRunPerl->new->run(@ARGV);

