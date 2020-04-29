#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use Test::Deep;

use Data::Dumper;

use CBOR::Free;

my @tests = (
    [ 65535 => "\x1a\0\0\xff\xff" ],
    [ 65535 => "\x1b\0\0\0\0\0\0\xff\xff" ],
    [ 0xffffffff => "\x1b\0\0\0\0\xff\xff\xff\xff" ],
    [ -0x80000000 => "\x3b\0\0\0\0\x7f\xff\xff\xff" ],
);

for my $t (@tests) {
    my ($in, $enc) = @$t;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Indent = 0;

    is( CBOR::Free::decode($enc), $in, "Decode: " . Dumper($enc) );
}

#----------------------------------------------------------------------

SKIP: {
    skip 'These tests are only for 32-bit perls.' if (0xffffffff << 1) > 0xffffffff;

    throws_ok(
        sub { diag explain( CBOR::Free::decode("\x82\x4aHello, yo!\x1b\0\0\0\1\0\0\0\0") ) },
        'CBOR::Free::X::CannotDecode64Bit',
        '64-bit number prompts expected error',
    );

    my $err = $@->get_message();

    cmp_deeply(
        $err,
        all(
            re( qr<0x0000_0001_0000_0000> ),
            re( qr<[^0-9]13[^0-9]> ),
        ),
        '… and the message looks as it should',
    );
}

done_testing();
