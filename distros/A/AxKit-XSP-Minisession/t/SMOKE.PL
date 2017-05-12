#!perl
# $Id: /local/CPAN/AxKit-XSP-Minisession/t/SMOKE.PL 1418 2005-03-05T18:07:22.924154Z claco  $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestSmoke ();

Apache::TestSmoke->new(@ARGV)->run;
