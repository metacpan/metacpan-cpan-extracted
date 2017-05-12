#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
use Test::Exception;

use IO::Scalar;

BEGIN {
    use_ok('Buffer::Transactional');
    use_ok('Buffer::Transactional::Buffer::Lazy');
}

my $data = '';
my $b = Buffer::Transactional->new(
    out          => IO::Scalar->new(\$data),
    buffer_class => 'Buffer::Transactional::Buffer::Lazy'
);
isa_ok($b, 'Buffer::Transactional');

$b->begin_work;

my $is_called = 0;

$b->print(sub { $is_called++; 'OH HAI' });
is($data, '', '... no data is sent to the handle yet');
is($is_called, 0, '... not called yet');

{
    $b->begin_work;

    $b->print(sub { $is_called++; 'KTHNXBYE' });
    is($data, '', '... no more data is sent to the handle yet');
    is($is_called, 0, '... still not called yet');

    {
        $b->begin_work;

        $b->print(sub { $is_called++; 'OH NOES' });
        is($data, '', '... no more data is sent to the handle yet');
        is($is_called, 0, '... still not called yet');

        {
            $b->begin_work;

            $b->print(sub { $is_called++; 'OOPS' });
            is($data, '', '... no more data is sent to the handle yet');
            is($is_called, 0, '... still not called yet');

            $b->rollback;
        }

        $b->commit;
    }
    is($data, '', '... no more data is sent to the handle yet');
    is($is_called, 0, '... still not called yet');

    $b->rollback;

    {
        $b->begin_work;

        $b->print(sub { $is_called++; 'YEAH!' });
        is($data, '', '... no more data is sent to the handle yet');
        is($is_called, 0, '... still not called yet');

        $b->commit;
    }
}

is($is_called, 0, '... not called yet');

$b->commit;

is($is_called, 2, '... only 2 of them called now');

is($data, 'OH HAIYEAH!', '... added data to the handle now');













