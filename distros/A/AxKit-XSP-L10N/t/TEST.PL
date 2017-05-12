#!perl
# $Id: /local/CPAN/AxKit-XSP-L10N/t/TEST.PL 1396 2005-03-25T03:58:41.995755Z claco  $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
