#!perl

use strict;
use warnings FATAL => 'all';

use lib qw(./lib ./LIBRA);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
