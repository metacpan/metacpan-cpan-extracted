#!perl

use strict;
use warnings FATAL => 'all';
use lib 'lib';

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
