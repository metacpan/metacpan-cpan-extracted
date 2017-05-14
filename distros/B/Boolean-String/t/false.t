use strict;
use warnings;
use 5.010;

use Test::More tests => 3;

use Boolean::String;

is false('blue'), 'blue', 'should leave strings intact';

ok !false('perl normally considers this true'), 'should make nonempty strings false';

ok !false(''), 'should keep empty strings false';

