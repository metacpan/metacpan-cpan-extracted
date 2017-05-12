#!perl
# $Id: /local/CPAN/AxKit-XSP-Currency/t/SMOKE.PL 1434 2005-03-05T01:08:13.559154Z claco  $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestSmoke ();

Apache::TestSmoke->new(@ARGV)->run;
