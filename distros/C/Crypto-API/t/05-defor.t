use strict;
use warnings;
use Test::More;
use Crypto::API;

is Crypto::API::_defor('foo', 'bar'), 'foo';
is Crypto::API::_defor(undef, 'bar'), 'bar';

done_testing;
