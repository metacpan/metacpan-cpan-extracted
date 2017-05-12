#!perl -T

use Test::More tests => 4;

BEGIN {
    unshift @INC, q(./t);
    use_ok( 'TestConfig', qw(one two) );
}

is($one{Pear}, 'yellow', 'data');
is(ref $two{Cars}, 'ARRAY', 'Config Options');
isa_ok(TestConfig->AppConfig, AppConfig);
