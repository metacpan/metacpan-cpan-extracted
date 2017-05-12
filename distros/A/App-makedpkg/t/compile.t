use strict;
use warnings;
use Test::More;
 
like(qx{$^X -c bin/makedpkg 2>&1}, qr{makedpkg syntax OK}ms, q{compiles});

done_testing;
