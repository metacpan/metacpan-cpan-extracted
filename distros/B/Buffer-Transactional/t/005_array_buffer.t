#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use IO::Scalar;

BEGIN {
    use_ok('Buffer::Transactional');
    use_ok('Buffer::Transactional::Buffer::Array');
}

my $data = '';
my $b = Buffer::Transactional->new(
    out          => IO::Scalar->new(\$data),
    buffer_class => 'Buffer::Transactional::Buffer::Array'
);
isa_ok($b, 'Buffer::Transactional');

$b->begin_work;

$b->print('OH HAI');
is($data, '', '... no data is sent to the handle yet');
is($b->current_buffer->as_string, 'OH HAI', '... what we expected in the buffer');

is_deeply($b->current_buffer->_buffer, [ 'OH HAI' ], '... got the buffer contents correctly');

{
    $b->begin_work;

    $b->print('KTHNXBYE');
    is($data, '', '... no more data is sent to the handle yet');
    is($b->current_buffer->as_string, 'KTHNXBYE', '... what we expected in the buffer');

    is_deeply($b->current_buffer->_buffer, [ 'KTHNXBYE' ], '... got the buffer contents correctly');

    {
        $b->begin_work;

        $b->print('OH NOES');
        is($data, '', '... no more data is sent to the handle yet');
        is($b->current_buffer->as_string, 'OH NOES', '... what we expected in the buffer');

        is_deeply($b->current_buffer->_buffer, [ 'OH NOES' ], '... got the buffer contents     correctly');

        $b->commit;
    }
    is($data, '', '... no more data is sent to the handle yet');
    is($b->current_buffer->as_string, 'KTHNXBYEOH NOES', '... what we expected in the buffer');

    is_deeply($b->current_buffer->_buffer, [ 'KTHNXBYE', 'OH NOES' ], '... got the buffer contents correctly');

    $b->rollback;
}

$b->commit;
is($data, 'OH HAI', '... added data to the handle now');













