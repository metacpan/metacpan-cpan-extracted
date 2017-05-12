#!perl

use strict;
use warnings FATAL => 'all';

use lib qw(lib t/lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
