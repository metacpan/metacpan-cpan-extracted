#!perl -T

use Test::Most;

plan tests => 1;

require_ok 'Dancer::Session::Memcached::Fast';

done_testing;
