#!perl

use strict;
use warnings FATAL => 'all';

use lib qw(t/lib lib ../Apache-Test/lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
