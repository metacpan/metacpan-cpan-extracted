package L;

use strict;
use warnings;

use Class::Accessor::Lite;
use Test::More tests => 1;

local $@;
eval {
    Class::Accessor::Lite->import(rw => "foo");
};
ok $@, $@;
