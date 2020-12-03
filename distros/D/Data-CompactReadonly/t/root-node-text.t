use strict;
use warnings;

use Test::More;
use Test::Exception;

use File::Temp qw(tempfile);
use String::Binary::Interpolation;

use Data::CompactReadonly;

my $header_bytes = "CROD\x00"; # version 0, byte pointers

open(my $fh, '<', \"$header_bytes${b00000000}\x05hippo");
is(Data::CompactReadonly->read($fh), 'hippo', "can read a Text with Byte length");

open($fh, '<', \"$header_bytes${b00001000}\x00\x05hippo");
is(Data::CompactReadonly->read($fh), 'hippo', "can read a Text with Short length");

open($fh, '<', \"$header_bytes${b00010000}\x00\x00\x05hippo");
is(Data::CompactReadonly->read($fh), 'hippo', "can read a Text with Medium (24 bits) length");

open($fh, '<', \"$header_bytes${b00011000}\x00\x00\x00\x05hippo");
is(Data::CompactReadonly->read($fh), 'hippo', "can read a Text with Long (32 bits) length");

foreach my $length_type (0b000, 0b001, 0b010, 0b011, 0b100) {
    my $type = chr(($length_type << 3) + 0b100);
    my $binary = sprintf('0b%08b', ord($type));
    open($fh, '<', \"$header_bytes$type");
    throws_ok { Data::CompactReadonly->read($fh)}
        qr/Invalid type: $binary: length Negative/,
        "invalid negative length type $binary throws a wobbly";
}

open($fh, '<', \"$header_bytes${b00101000}");
throws_ok { Data::CompactReadonly->read($fh) }
    qr/Invalid type: 0b00101000: length Null/,
    "invalid Null length type b00101000 throws a wobbly";

open($fh, '<', \"$header_bytes${b00101100}");
throws_ok { Data::CompactReadonly->read($fh) }
    qr/Invalid type: 0b00101100: length Float/,
    "invalid Float length type b00101100 throws a wobbly";

foreach my $length_type (0b1100 .. 0b1111) {
    my $type = chr($length_type << 2);
    my $binary = sprintf('0b%08b', ord($type));
    open($fh, '<', \"$header_bytes$type");
    throws_ok { Data::CompactReadonly->read($fh)}
        qr/Invalid type: $binary: Reserved/,
        "invalid type $binary throws a wobbly";
}

open($fh, '<', \"$header_bytes${b00000000}\x09\xe5\x8c\x97\xe4\xba\xac\xe5\xb8\x82");
is(Data::CompactReadonly->read($fh), "\x{5317}\x{4eac}\x{5e02}", "bytes are converted to utf-8 text: got 3 chars [北, 京, 市] from 9 bytes");

done_testing;
