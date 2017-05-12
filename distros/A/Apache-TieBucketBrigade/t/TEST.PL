#file:t/TEST.PL
#--------------
#!perl
use strict;
use warnings FATAL => 'all';
use lib qw(lib);
use Apache2 ();
use Apache::TestRunPerl ();
Apache::TestRunPerl->new->run(@ARGV);
