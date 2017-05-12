## no critic (RCS,VERSION,encapsulation,Module)
use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'Dependency testing only applies to Win32'
        unless $^O eq 'MSWin32';
    use_ok 'Win32';
    use_ok 'Win32::API';
    use_ok 'Win32::API::Type';
}

done_testing();
