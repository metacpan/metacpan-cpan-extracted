#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

use IO::Scalar;

BEGIN {
    use_ok('Buffer::Transactional');
    use_ok('Buffer::Transactional::Buffer::File');
}

my @uuids;

my $data = '';
my $b = Buffer::Transactional->new(
    out          => IO::Scalar->new(\$data),
    buffer_class => 'Buffer::Transactional::Buffer::File'
);
isa_ok($b, 'Buffer::Transactional');

$b->begin_work;

$b->print('OH HAI');
is($data, '', '... no data is sent to the handle yet');
is($b->current_buffer->as_string, 'OH HAI', '... what we expected in the buffer');

push @uuids => $b->current_buffer->uuid;

ok(-e $uuids[-1], '... the buffer file (' . $uuids[-1] . ') exists');

{
    $b->begin_work;

    $b->print('KTHNXBYE');
    is($data, '', '... no more data is sent to the handle yet');
    is($b->current_buffer->as_string, 'KTHNXBYE', '... what we expected in the buffer');

    push @uuids => $b->current_buffer->uuid;

    ok(-e $uuids[-1], '... the buffer file (' . $uuids[-1] . ') exists');

    {
        $b->begin_work;

        $b->print('OH NOES');
        is($data, '', '... no more data is sent to the handle yet');
        is($b->current_buffer->as_string, 'OH NOES', '... what we expected in the buffer');

        push @uuids => $b->current_buffer->uuid;

        ok(-e $uuids[-1], '... the buffer file (' . $uuids[-1] . ') exists');

        $b->commit;

        ok(!-e $uuids[-1], '... the buffer file (' . $uuids[-1] . ') no longer exists');
    }

    is($data, '', '... no more data is sent to the handle yet');
    is($b->current_buffer->as_string, 'KTHNXBYEOH NOES', '... what we expected in the buffer');

    $b->rollback;

    ok(!-e $uuids[-2], '... the buffer file (' . $uuids[-2] . ') no longer exists');
}

ok(-e $uuids[0], '... the buffer file (' . $uuids[0] . ') still exists');

$b->commit;
is($data, 'OH HAI', '... added data to the handle now');

ok(!-e $_, '... the buffer file (' . $_ . ') has been deleted') for @uuids;













