use strict;
use warnings;
use Test::More;

use Data::TxnBuffer;

my $little_endian = !(unpack('S', pack('C2', 0, 1)) == 1);

subtest 'basic functions' => sub {
    my $b = Data::TxnBuffer->new;
    isa_ok $b, 'Data::TxnBuffer';

    $b->write('foo');
    is $b->data, 'foo', 'write foo ok';
    is $b->read(3), 'foo', 'read 3 byte ok';

    is $b->length, 3, 'buffer length ok';

    is $b->cursor, 3, 'cursor ok';
    $b->reset;
    is $b->cursor, 0, 'cursor reset ok';
    is $b->read(3), 'foo', 're-read 3 byte ok';
    is $b->spin, 'foo', 'spin res ok';
    is $b->length, 0, 'length ok';

    $b->write('foo');
    $b->write('bar');
    is $b->read(3), 'foo', 'read foo ok';
    is $b->read(3), 'bar', 'read bar ok';
    $b->reset;
    is $b->read(6), 'foobar', 'read foobar ok';
    $b->reset;

    $b->read(3);
    is $b->spin, 'foo', 'spin only foo';

    is $b->cursor, 0, 'reset cursor ok after spin';
    is $b->data, 'bar', 'bar is remain ok';

    $b->clear;
    ok !$b->data, 'clear data ok';

    done_testing;
};

subtest 'default data' => sub {
    my $b = Data::TxnBuffer->new('foobar');
    is $b->data, 'foobar', 'default data ok';

    done_testing;
};

subtest 'int 32' => sub {
    my $b = Data::TxnBuffer->new;

    $b->write_u32(123);
    is $b->read_u32, 123, 'read 123 ok';

    $b->write_i32(456);
    is $b->read_i32, 456, 'read 456 ok';

    $b->write_i32(-123);
    is $b->read_i32, -123, 'read -123 ok';

    $b->clear;

    $b->write_u32(0x11223344);
    if ($little_endian) {
        is $b->data, "\x44\x33\x22\x11", 'data ok';
    }
    else {
        is $b->data, "\x11\x22\x33\x44", 'data ok';
    }

    done_testing;
};

subtest 'int 24' => sub {
    my $b = Data::TxnBuffer->new;

    $b->write_u24(123);
    is $b->read_u24, 123, 'read 123 ok';

    $b->write_i24(456);
    is $b->read_i24, 456, 'read 456 ok';

    $b->write_i24(-123);
    is $b->read_i24, -123, 'read -123 ok';

    $b->clear;

    $b->write_u24(0x112233);
    if ($little_endian) {
        is $b->data, "\x33\x22\x11", 'data ok';
    }
    else {
        is $b->data, "\x11\x22\x33", 'data ok';
    }

    done_testing;
};

subtest 'int 16' => sub {
    my $b = Data::TxnBuffer->new;

    $b->write_u16(123);
    is $b->read_u16, 123, 'read 123 ok';

    $b->write_i16(456);
    is $b->read_i16, 456, 'read 456 ok';

    $b->write_i16(-123);
    is $b->read_i16, -123, 'read -123 ok';

    $b->clear;

    $b->write_u16(0x1122);
    if ($little_endian) {
        is $b->data, "\x22\x11", 'data ok';
    }
    else {
        is $b->data, "\x22\x33", 'data ok';
    }

    done_testing;
};

subtest 'int 8' => sub {
    my $b = Data::TxnBuffer->new;

    $b->write_u8(123);
    is $b->read_u8, 123, 'read 123 ok';

    $b->write_i8(-123);
    is $b->read_i8, -123, 'read -123 ok';

    $b->clear;
    
    done_testing;
};

subtest 'network order u32' => sub {
    my $b = Data::TxnBuffer->new;

    $b->write_n32(123);
    is $b->read_n32, 123, 'read 123 ok';

    $b->write_n32(456);
    is $b->read_n32, 456, 'read 456 ok';

    $b->clear;

    $b->write_n32(0x11223344);
    is $b->data, "\x11\x22\x33\x44", 'data ok';

    done_testing;
};

subtest 'network order u24' => sub {
    my $b = Data::TxnBuffer->new;

    $b->write_n24(123);
    is $b->read_n24, 123, 'read 123 ok';

    $b->write_n24(456);
    is $b->read_n24, 456, 'read 456 ok';

    $b->clear;

    $b->write_n24(0x112233);
    is $b->data, "\x11\x22\x33", 'data ok';

    done_testing;
};

subtest 'network order u16' => sub {
    my $b = Data::TxnBuffer->new;

    $b->write_n16(123);
    is $b->read_n16, 123, 'read 123 ok';

    $b->write_n16(456);
    is $b->read_n16, 456, 'read 456 ok';

    $b->clear;

    $b->write_n16(0x1122);
    is $b->data, "\x11\x22", 'data ok';

    done_testing;
};

subtest 'float/double' => sub {
    my $b = Data::TxnBuffer->new;

    $b->write_float(0.123);
    is int($b->read_float * 1000), 123, 'read 0.123 ok';

    $b->write_double(0.12345);
    is int($b->read_double * 100000), 12345, 'read 0.12345 ok';

    $b->spin;

    ok !$b->data, 'buffer empty ok';

    done_testing;
};

done_testing;
