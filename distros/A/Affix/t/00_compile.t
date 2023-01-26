use strict;
use Test::More 0.98;
use lib '../lib', 'lib';
use_ok $_ for qw[Affix];
#
diag 'supported features:';
diag '    syscall: ' . ( Affix::Feature::Syscall()   ? 'yes' : 'no' );
diag '  aggrbyval: ' . ( Affix::Feature::AggrByVal() ? 'yes' : 'no' );
#
done_testing;
