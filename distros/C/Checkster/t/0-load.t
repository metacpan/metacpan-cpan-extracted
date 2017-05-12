use strict;
use warnings;

use Test::More;

BEGIN {
    eval{ use Checkster 'check' };
    ok !$@, 'use ok';
}

done_testing;
