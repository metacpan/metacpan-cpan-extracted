#!perl
use Test::More;

use Data::BinaryBuffer;

{
    my $s = Data::BinaryBuffer->new;
    is $s->size, 0, "initial size is 0";

    $s->write("12345");
    is $s->size, 5, "right size after write 5 bytes";

    is $s->read(4), "1234", "read 4 bytes";
    $s->write("67890");
    is $s->size, 6, "add another 5 bytes, now size is 6";

    is $s->read(6), "567890", "read 6 bytes";
    is $s->size, 0, "now size is 0";

    $s->write("1234");
    is $s->read(6), "1234", "write 4 bytes, read 6, we should got 4";

    $s = Data::BinaryBuffer->new;
    is $s->read(10), '', "read from empty buffer always return empty string";
}

{ # write/read big data
    my $s = Data::BinaryBuffer->new;

    $s->write("abcd" x 2048);
    is $s->size, 8192, "write 8Kb of data";

    is $s->read(15), "abcdabcdabcdabc", "now read 15 bytes back";
    is $s->size, 8177, "now size should be 8177 bytes";
    is $s->read(4096), "dabc" x 1024, "read back 4Kb";
    is $s->size, 4081, "now size should be 4081";
}

{ # uint8
    my $s = Data::BinaryBuffer->new;
    $s->write("0");
    is $s->read_uint8, ord("0"), "we can read one byte as uint";
    is $s->size, 0, "size now 0";

    $s->write_uint8(5);
    is $s->size, 1, "write uint8, size should be 1";
    is $s->read_uint8, 5, "write and read uint8";

    $s->write_uint8(-1);
    is $s->read_uint8, 255, "write -1 and read 255 as uint";
}

{ # int8
    my $s = Data::BinaryBuffer->new;

    $s->write_int8(5);
    is $s->read_int8, 5;

    $s->write_int8(-1);
    is $s->read_int8, -1;
}

{ #uint16
    my $s = Data::BinaryBuffer->new;

    $s->write_uint16be(0x1234);
    is $s->size, 2, "write_uint16be write 2 bytes";
    is $s->read(2), pack("n", 0x1234), "write_uint16be work";

    $s->write(pack("n", 0x1234));
    is $s->read_uint16be, 0x1234, "read_uint16be work";
    is $s->size, 0, "read_uint16be read 2 bytes";

    $s->write_uint16le(0x1234);
    is $s->size, 2, "write_uint16le write 2 bytes";
    is $s->read(2), pack("v", 0x1234), "write_uint16le work";

    $s->write(pack("v", 0x1234));
    is $s->read_uint16le, 0x1234, "read_uint16le work";
    is $s->size, 0, "read_uint16le read 2 bytes";
}

{ #int16
    my $s = Data::BinaryBuffer->new;

    $s->write_int16be(-7);
    is $s->size, 2, "write_int16be write 2 bytes";
    is $s->read(2), pack("n",unpack("S",pack("s", -7))), "write_int16be work";

    $s->write(pack("n", 0x1234));
    is $s->read_int16be, 0x1234, "read_int16be work";
    is $s->size, 0, "read_int16be read 2 bytes";

    $s->write_int16le(0x1234);
    is $s->size, 2, "write_int16le write 2 bytes";
    is $s->read(2), pack("v", 0x1234), "write_int16le work";

    $s->write(pack("v", 0x1234));
    is $s->read_int16le, 0x1234, "read_int16le work";
    is $s->size, 0, "read_int16le read 2 bytes";
}

{ #uint32
    my $s = Data::BinaryBuffer->new;

    $s->write_uint32be(0x12345678);
    is $s->size, 4, "write_uint32be write 4 bytes";
    is $s->read(4), pack("N", 0x12345678), "write_uint32be work";

    $s->write(pack("N", 0x12345678));
    is $s->read_uint32be, 0x12345678, "read_uint32be work";
    is $s->size, 0, "read_uint32be read 4 bytes";

    $s->write_uint32le(0x12345678);
    is $s->size, 4, "write_uint32le write 4 bytes";
    is $s->read(4), pack("V", 0x12345678), "write_uint32le work";

    $s->write(pack("V", 0x12345678));
    is $s->read_uint32le, 0x12345678, "read_uint32le work";
    is $s->size, 0, "read_uint32le read 4 bytes";
}

{ # int32
    my $s = Data::BinaryBuffer->new;

    $s->write_int32be(0x12345678);
    is $s->size, 4, "write_int32be write 4 bytes";
    is $s->read(4), pack("N", 0x12345678), "write_int32be work";

    $s->write(pack("N", 0x12345678));
    is $s->read_int32be, 0x12345678, "read_int32be work";
    is $s->size, 0, "read_int32be read 4 bytes";

    $s->write_int32le(0x12345678);
    is $s->size, 4, "write_int32le write 4 bytes";
    is $s->read(4), pack("V", 0x12345678), "write_int32le work";

    $s->write(pack("V", 0x12345678));
    is $s->read_int32le, 0x12345678, "read_int32le work";
    is $s->size, 0, "read_int32le read 4 bytes";
}

{ # read_buffer
    my $s = Data::BinaryBuffer->new;

    $s->write("abcdefg012345");
    is $s->size, 13, "initial string 13 bytes long";
    my $s1 = $s->read_buffer(7);
    is $s->size, 6, "remains 6 bytes in original buffer";
    is $s1->size, 7, "new buffer size is 7";
    is $s1->read(7), "abcdefg", "new buffer contains right data";
    is $s->read(6), "012345", "original buffer contains right data";

    is $s->size, 0, "try read buffer from empty one";
    my $s2 = $s->read_buffer(10);
    is $s2->size, 0, "we got buffer with size = 0";
}

{ # read big buffer
    my $s = Data::BinaryBuffer->new;

    $s->write("01234567" x 1024); # 8Kb
    is $s->size, 8192, "initial string 8Kb long";
    my $s1 = $s->read_buffer(8000);
    is $s->size, 192, "remains 192 bytes in original buffer";
    is $s1->size, 8000, "new buffer size is 8000";
    is $s1->read(4096), "01234567" x 512, "new buffer contains right data";
    is $s->read(6), "012345", "original buffer contains right data";

    $s = Data::BinaryBuffer->new;

    $s->write($_ x 2000) for qw/a b c d e f g h/;
    is $s->size, 16000, "wrtie 16000 bytes to buffer";
    $s->read(10);
    is $s->size, 15990, "now read some small amount of data (10 bytes)";
    $s1 = $s->read_buffer(10000);
    is $s1->size, 10000, "read 10000 bytes to another buffer";

    is $s1->read(1990), "a" x 1990, "chunk 1 right";
    is $s1->read(2000), "b" x 2000, "chunk 2 right";
}

{ # bug with long writes
    my $s = Data::BinaryBuffer->new;
    my $sample = ("A" x 2000).("B" x 2000).("C" x 2000);
    $s->write($sample);
    my $data = $s->read(6000);
    is $data, $sample;
}

done_testing;
