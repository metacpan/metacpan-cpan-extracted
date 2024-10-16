# $Id: test.pl,v 1.7 2001/07/28 06:36:50 btrott Exp $

use strict;

use Test2::V0;
BEGIN { plan tests => 55 }

use vars qw( $loaded );
END { print "not ok 1\n" unless $loaded; }
use Data::Buffer;
$loaded++;
ok($loaded);

my $buffer = Data::Buffer->new;
ok($buffer, "New Buffer Created");
$buffer->put_str("foo");
ok($buffer->length == 7, "Buffer length is 7");
like($buffer->get_str, qr/foo/, "Buffer read is foo");
ok($buffer->offset == 7, "Buffer offset is 7");

$buffer->put_str(0);
ok($buffer->get_str == 0, "Buffer write read 0");

$buffer->put_int32(999999999);
ok($buffer->get_int32 == 999999999, "Buffer write read int32 999999999");

$buffer->put_int8(2);
ok($buffer->get_int8 == 2, "Buffer write read int8 2");

my $save_off = $buffer->offset;

$buffer->put_int16(9999);
ok($buffer->get_int16 == 9999, "Buffer write read int16 9999");

$buffer->put_char('a');
ok($buffer->get_char eq 'a', "Buffer write read char 'a'");

$buffer->put_chars("bar");
ok($buffer->get_char eq 'b', "Buffer wrote 'bar' read char 'b'");
ok($buffer->get_char eq 'a', "Buffer wrote 'bar' read char 'a'");
ok($buffer->get_char eq 'r', "Buffer wrote 'bar' read char 'r'");

$buffer->put_bytes("foobar", 5);
ok($buffer->get_bytes(5) eq "fooba", "Buffer wrote foobar read 5 bytes 'fooba'");
ok($buffer->offset == $buffer->length, "Buffer offset is length after read");

$buffer->set_offset($save_off);
ok($buffer->offset == $save_off, "set offset matches read offset");
my $buf2 = $buffer->extract(5);
ok($buf2->offset == 0, "New buffer from extract offset is 0");
ok($buf2->length == 5, "New buffer from extract length is 5");
ok($buf2->get_int16 == 9999, "New buffer contains int16 value 9999 from old buffer");
ok($buf2->get_bytes(3) eq 'aba', "New buffer contains bytes 'aba' from old buffer");

$buffer->insert_template;
my @data = $buffer->get_all;
ok(@data == 14, "template contains 14 items");
ok($data[0] eq "foo", "template item 1 is foo");
ok($data[1] == 0, "template item 2 is '0'");
ok($data[2] == 999999999, "template item 3 is '999999999'");
ok($data[3] == 2, "template item 4 is '2'");
ok($data[4] == 9999, "template item 5 is '9999'");
ok($data[5] eq 'a', "template item 6 is 'a'");
ok($data[6] eq 'b', "template item 7 is 'b'");
ok($data[7] eq 'a', "template item 8 is 'a'");
ok($data[8] eq 'r', "template item 9 is 'r'");
ok($data[9] eq 'f', "template item 10 is 'f'");
ok($data[10] eq 'o', "template item 11 is 'o'");
ok($data[11] eq 'o', "template item 12 is 'o'");
ok($data[12] eq 'b', "template item 13 is 'b'");
ok($data[13] eq 'a', "template item 14 is 'a'");

$buffer->empty;
ok($buffer->offset == 0, "Empty buffer sets offset to 0");
ok($buffer->length == 0, "Empty buffer length is 0");
like($buffer->bytes, qr//, "Empty buffer read bytes is empty");
like($buffer->template, qr//, "Empty buffer template is empty");

$buffer->append("foobar");
ok($buffer->length == 6, "Empty Buffer append 'foobar' length is 6");
like($buffer->bytes, qr/foobar/, "Read bytes 'foobar' from buffer");

$buffer->empty;
ok($buffer->length == 0, 'Empty buffer length is zero');
like($buffer->dump, qr//, "Buffer dump hex from empty buffer is empty");

$buffer->put_int16(129);
ok($buffer->get_int16 == 129, "Buffer write int16 '129' - read '129'");
like($buffer->dump, qr/00 81/, "Buffer dump hex from offset 0 matches");
like($buffer->dump(1), qr/81/, "Buffer dump hex index 1 from offset 0 matches");

$buf2 = Data::Buffer->new_with_init("foo");
ok($buf2, "new_with_init 'foo' created");
ok($buf2->length == 3, "new_with_init 'foo' - length is 3");
like($buf2->bytes, qr/foo/, "new_with_init 'foo' - matches 'foo'");

$buf2 = Data::Buffer->new_with_init("foo", "bar");
ok($buf2, "new_with_init 'foobar' created");
ok($buf2->length == 6,  "new_with_init 'foobar' - length is 6");
like($buf2->bytes, qr/foobar/, "new_with_init 'foobar' - matches 'foobar'");

like($buf2->get_bytes(3), qr/foo/, "new_with_init 'foobar' - read 3 yytes matches 'foo'");
$buf2->reset_offset;
ok($buf2->offset == 0, "Reset buffer offset - offset is 0");
ok($buf2->length == 6, "Buffer 2 length is 6");
