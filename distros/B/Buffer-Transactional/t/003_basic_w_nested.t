#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

use IO::Scalar;

BEGIN {
    use_ok('Buffer::Transactional');
}

my $data = '';
my $b = Buffer::Transactional->new( out => IO::Scalar->new(\$data) );
isa_ok($b, 'Buffer::Transactional');

$b->begin_work;

$b->print('OH HAI');
is($data, '', '... no data is sent to the handle yet');
is($b->current_buffer->as_string, 'OH HAI', '... what we expected in the buffer');

{
    $b->begin_work;

    $b->print('KTHNXBYE');
    is($data, '', '... no more data is sent to the handle yet');
    is($b->current_buffer->as_string, 'KTHNXBYE', '... what we expected in the buffer');

    {
        $b->begin_work;

        $b->print('OH NOES');
        is($data, '', '... no more data is sent to the handle yet');
        is($b->current_buffer->as_string, 'OH NOES', '... what we expected in the buffer');

        $b->commit;
    }
    is($data, '', '... no more data is sent to the handle yet');
    is($b->current_buffer->as_string, 'KTHNXBYEOH NOES', '... what we expected in the buffer');

    $b->rollback;
}

$b->commit;
is($data, 'OH HAI', '... added data to the handle now');













