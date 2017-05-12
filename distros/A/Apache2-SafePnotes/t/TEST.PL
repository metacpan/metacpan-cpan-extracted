#file:t/TEST.PL
#--------------
#!perl

use strict;
use warnings FATAL => 'all';

use lib qw(lib t);

use Apache::TestRunPerl ();

my $I=Apache::TestRunPerl->new;

$I->run(@ARGV);
