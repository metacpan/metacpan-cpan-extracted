#!perl
# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/t/TEST.PL 1497 2005-03-05T17:05:21.898763Z claco  $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);
