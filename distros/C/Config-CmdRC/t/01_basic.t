use strict;
use warnings;
use Test::More;

use Config::CmdRC ('share/.foorc');

is RC->{bar}, 'baz';
is RC->{qux}, 123;

done_testing;
