use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('Apophis') }

ok($Apophis::VERSION, 'version is set');

diag("Testing Apophis $Apophis::VERSION, Perl $], $^X");
