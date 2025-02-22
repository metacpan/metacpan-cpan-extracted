#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 3;

BEGIN { use_ok('Array::Iterator') }

isa_ok(Array::Iterator->new(1..5), 'Array::Iterator', 'Creating Array::Iterator object with ARRAY');
isa_ok(Array::Iterator->new({ __array__ => [1..2] }), 'Array::Iterator', 'Creating Array::Iterator object with HASH');
# ok(!defined(Array::Iterator::new()));
