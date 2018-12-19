use strict;
use warnings;

use Test::More;

plan(tests => 3);

sleep(1);
pass("$0-1");
sleep(1);
pass("$0-2");
sleep(1);
pass("$0-3");

done_testing();
