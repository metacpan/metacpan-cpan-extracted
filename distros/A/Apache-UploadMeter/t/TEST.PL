#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use lib qw(lib);

use Apache::TestRunPerl ();
use base 'Apache::TestRun';
#$Apache::TestTrace::Level = 'debug';

main::->new->run(@ARGV);
  