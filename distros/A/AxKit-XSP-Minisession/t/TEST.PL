#!perl
# $Id: /local/CPAN/AxKit-XSP-Minisession/t/TEST.PL 1410 2005-02-03T23:54:06.055916Z claco  $

use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
