use strict;
use warnings;
no warnings 'portable';

use Test::More;
use Test::Exception;

use File::Temp qw(tempfile);
use String::Binary::Interpolation;
use Data::IEEE754 qw(pack_double_be);

use Data::CompactReadonly;

my $header_bytes = "CROD\x00"; # version 0, byte pointers

foreach my $negative (0, 1) {
    subtest $negative ? 'negative numbers' : 'positive numbers' => sub {
        my $type = chr(0b11000000 + $negative * 0b100);
        open(my $fh, '<', \"$header_bytes$type\x12");
        is(Data::CompactReadonly->read($fh), ($negative ? -1 : 1) * 0x12, "can read a Byte");
         
        $type = chr(0b11001000 + $negative * 0b100);
        open($fh, '<', \"$header_bytes$type\xff\xfe");
        is(Data::CompactReadonly->read($fh), ($negative ? -1 : 1) * 0xFFFE, "can read a Short");
        
        $type = chr(0b11010000 + $negative * 0b100);
        open($fh, '<', \"$header_bytes$type\xff\xfe\x00");
        is(Data::CompactReadonly->read($fh), ($negative ? -1 : 1) * 0xFFFE00, "can read a Medium (24 bits)");
        
        $type = chr(0b11011000 + $negative * 0b100);
        open($fh, '<', \"$header_bytes$type\xff\xfe\x00\x00");
        is(Data::CompactReadonly->read($fh), ($negative ? -1 : 1) * 0xFFFE0000, "can read a Long (32 bits)");
        
        $type = chr(0b11100000 + $negative * 0b100);
        open($fh, '<', \"$header_bytes$type\xff\xfe\x00\x00\x00\x00\x00\x00");
        is(Data::CompactReadonly->read($fh), ($negative ? -1 : 1) * 0xFFFE000000000000, "can read a Huge (64 bits)");
    };
}

subtest 'floats' => sub {
    my $float_bytes = pack_double_be(3.1415);
    open(my $fh, '<', \"$header_bytes${b11101100}$float_bytes");
    is(Data::CompactReadonly->read($fh), 3.1415, "can read a Float");
    
    $float_bytes = pack_double_be(2.718e-50);
    open($fh, '<', \"$header_bytes${b11101100}$float_bytes");
    is(Data::CompactReadonly->read($fh), 2.718e-50, "can read a teeny-tiny Float");
    
    $float_bytes = pack_double_be(-1e100/137);
    open($fh, '<', \"$header_bytes${b11101100}$float_bytes");
    is(Data::CompactReadonly->read($fh), -1e100/137, "can read a hugely negative Float");
};

open(my $fh, '<', \"$header_bytes${b11101000}");
is(Data::CompactReadonly->read($fh), undef, "can read a Null (undef)");

foreach my $scalar_type (0b1100 .. 0b1111) {
    my $type = chr(($scalar_type << 2) + 0b11000000);
    my $binary = sprintf('0b%08b', ord($type));
    open($fh, '<', \"$header_bytes$type");
    throws_ok { Data::CompactReadonly->read($fh)}
        qr/Invalid type: $binary: Reserved/,
        "invalid type $binary throws a wobbly";
}

done_testing;
