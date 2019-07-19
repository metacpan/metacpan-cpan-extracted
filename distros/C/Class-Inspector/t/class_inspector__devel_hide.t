use strict;
use warnings;
use Test::More;
use Class::Inspector;

eval { require Devel::Hide };
plan skip_all => 'test requires Devel::Hide' if $@;
plan tests => 2;

ok(   Class::Inspector->installed('Class::Inspector')        );
ok( ! Class::Inspector->installed('Class::Inspector::Bogus') );
