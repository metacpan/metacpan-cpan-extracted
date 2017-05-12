use strict;
use warnings;

use Test::More;
use autodie;

system 'sh -n eg/post-commit';

ok(1);

done_testing();
