#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use IO::Scalar;

BEGIN {
    use_ok('Buffer::Transactional');
}

my $data = '';
my $b = Buffer::Transactional->new( out => IO::Scalar->new(\$data) );
isa_ok($b, 'Buffer::Transactional');

eval {
    $b->begin_work;
    $b->print('OH HAI');
    is($data, '', '... no data is sent to the handle yet');
    is($b->current_buffer->as_string, 'OH HAI', '... what we expected in the buffer');
    die "Whoops!\n"
};
if ($@) {
    $b->rollback;
    is($data, '', '... no data was sent to the handle');
}










