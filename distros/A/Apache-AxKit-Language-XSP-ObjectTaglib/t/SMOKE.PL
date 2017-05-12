#!perl
# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/t/SMOKE.PL 1502 2005-03-05T17:38:53.550891Z claco  $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestSmoke ();

Apache::TestSmoke->new(@ARGV)->run;
