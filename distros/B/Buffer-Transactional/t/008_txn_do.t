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

$b->txn_do(sub {;
    $b->print('Greetings');
    is($data, '', '... no data is sent to the handle yet');
    is($b->current_buffer->as_string, 'Greetings', '... what we expected in the buffer');
});

is($data, "Greetings", '... now data is sent to the handle');










