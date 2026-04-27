use strict;
use warnings;
use Test2::V0;
use Scalar::Util qw(blessed);
use Async::Redis;

my $c = Async::Redis->new(host => 'x', port => 1);   # no connect

subtest 'simple string OK' => sub {
    my ($kind, $val) = $c->_decode_response_result({ type => '+', data => 'OK' });
    is $kind, 'ok', 'kind=ok';
    is $val, 'OK', 'value';
};

subtest 'integer OK' => sub {
    my ($kind, $val) = $c->_decode_response_result({ type => ':', data => '42' });
    is $kind, 'ok', 'kind=ok';
    is $val, 42, 'value coerced to number';
};

subtest 'bulk string OK' => sub {
    my ($kind, $val) = $c->_decode_response_result({ type => '$', data => 'hello' });
    is $kind, 'ok';
    is $val, 'hello';
};

subtest 'nil bulk OK' => sub {
    my ($kind, $val) = $c->_decode_response_result({ type => '$', data => undef });
    is $kind, 'ok';
    is $val, undef, 'nil value';
};

subtest 'array OK' => sub {
    my ($kind, $val) = $c->_decode_response_result({
        type => '*',
        data => [
            { type => '+', data => 'foo' },
            { type => ':', data => '7' },
        ],
    });
    is $kind, 'ok';
    is $val, ['foo', 7], 'decoded array';
};

subtest 'redis_error child inside an array is preserved as an error object element' => sub {
    my ($kind, $val) = $c->_decode_response_result({
        type => '*',
        data => [
            { type => '+', data => 'OK' },
            { type => '-', data => 'WRONGTYPE bad' },
            { type => ':', data => '42' },
        ],
    });
    is $kind, 'ok', 'array kind is ok even with error child';
    is ref $val, 'ARRAY', 'value is arrayref';
    is $val->[0], 'OK', 'first element is normal value';
    ok $val->[1]->isa('Async::Redis::Error::Redis'),
        'second element is an error object (MULTI/EXEC semantics)';
    like "$val->[1]", qr/WRONGTYPE/, 'error carries its message';
    is $val->[2], 42, 'third element is numeric';
};

subtest 'redis error becomes redis_error kind' => sub {
    my ($kind, $val) = $c->_decode_response_result({ type => '-', data => 'ERR bad' });
    is $kind, 'redis_error', 'kind=redis_error';
    ok blessed($val) && $val->isa('Async::Redis::Error::Redis'), 'error object';
    like "$val", qr/bad/, 'carries message';
};

subtest 'undef message is protocol_error' => sub {
    my ($kind, $val) = $c->_decode_response_result(undef);
    is $kind, 'protocol_error';
    ok blessed($val) && $val->isa('Async::Redis::Error::Protocol'),
        'typed protocol error';
};

subtest 'unknown type is protocol_error' => sub {
    my ($kind, $val) = $c->_decode_response_result({ type => '?', data => 'x' });
    is $kind, 'protocol_error';
    ok blessed($val) && $val->isa('Async::Redis::Error::Protocol');
};

done_testing;
