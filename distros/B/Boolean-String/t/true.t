use strict;
use warnings;
use 5.010;

use Test::More tests => 3;

use Boolean::String;

is true('blue'), 'blue', 'should leave strings intact';

ok true('1'), 'should keep nonempty strings true';

ok true(''), 'should make empty strings true';

