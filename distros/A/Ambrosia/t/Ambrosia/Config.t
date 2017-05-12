#!/usr/bin/perl

use Test::More tests => 9;
use Test::Exception;
use Test::Deep;
use lib qw(lib t ../..);

BEGIN {
    use_ok( 'Ambrosia::Config' ); #test #1
}
require_ok( 'Ambrosia::Config' ); #test #2

instance Ambrosia::Config( test => { param1 => 123, param2 => [1,2,3] } );

cmp_ok(config('test')->param1, '==', 123, 'config(test)->param1 is ok'); #test #3
cmp_deeply(config('test')->param2, [1,2,3], 'config(test)->param2 is ok'); #test #4

Ambrosia::Config::assign 'test';

cmp_ok(config->param1, '==', 123, 'config(test)->param1 is ok'); #test #5
cmp_deeply(config->param2, [1,2,3], 'config(test)->param2 is ok'); #test #6

my $v = config->param3 = 456;
cmp_ok(config->param3, '==', 456, 'add param to config is ok'); #test #7
cmp_ok($v, '==', 456, 'return adding value to param is ok'); #test #8

throws_ok { new Ambrosia::Config( test_throws => { param1 => 1 } ); } 'Ambrosia::error::Exception::BadUsage', 'Ambrosia::error::Exception::BadUsage exception thrown'; #test #9
