#!perl

use strict;
use warnings FATAL => 'all';

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
