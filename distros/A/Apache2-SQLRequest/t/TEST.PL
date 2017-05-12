#!perl

use warnings FATAL => 'all';
use strict;

use Apache::TestRunPerl ();
Apache::TestRunPerl->new->run(@ARGV);
