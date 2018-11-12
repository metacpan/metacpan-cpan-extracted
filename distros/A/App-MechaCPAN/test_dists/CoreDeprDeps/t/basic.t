use strict;
use Test::More;
use CoreDeprDeps;

# Doing this in new versions of perl, which B::Debug is deprecated in, will
# cause a warn on use. If we make that warning a die, this dist test will fail
local $SIG{__WARN__} = sub { die @_ };
require B::Debug;

# replace with the actual test
ok 1;

done_testing;
