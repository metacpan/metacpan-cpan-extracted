use strict;
use warnings;
no warnings qw(portable overflow);

use File::Temp qw(tempfile);
use Test::More;

use Data::CompactReadonly;

(undef, my $filename) = tempfile(UNLINK => 1);

Data::CompactReadonly->create($filename, undef);
is(my $data = Data::CompactReadonly->read($filename), undef, "can create a Null file");

foreach my $tuple (
    [0,                    7], # Byte
    ['0',                  7], # Byte
    [0x01,                 7],
    [0x0102,               8],
    [0x010203,             9],
    [0x01020304,          10],
    [0xFFFFFFFF0,         14], # Huge, will require zero-padding
    [0x10000000000000000, 14], # too big for a Huge, encoded as Float
) {
    my($value, $filesize) = @{$tuple};
    foreach my $value ($value, -$value) {
        Data::CompactReadonly->create($filename, $value);
        is($data = Data::CompactReadonly->read($filename), $value,
            abs($value) == 0x10000000000000000 ? "auto-promoted humungo-Int to a Float" :
                                                 "can create an Int file ($value)"
        );
        is((stat($filename))[7], $filesize, "... file is expected size for data $value") || diag(`hexdump -C $filename`);
    }
}

# normal size, practically zero, ginormously -ve
foreach my $value (5.1413, 81.72e-50, -1.37e100/3) {
    Data::CompactReadonly->create($filename, $value);
    is($data = Data::CompactReadonly->read($filename), $value, "can create a Float file ($value)");
}

foreach my $length (1, 1000, 100000, 0x1000000) {
    #               ^  ^     ^       ^
    #        Byte --+  |     |       +-- Long 
    #       Short -----+     +---------- Medium
    my $filesize = 5 + 1 + (1 + int(log($length) / log(256))) + $length;
    my $value = 'x' x $length;
    Data::CompactReadonly->create($filename, $value);
    is($data = Data::CompactReadonly->read($filename), $value, "can create an ASCII Text file ($length chars)");
        is((stat($filename))[7], $filesize, "... file is expected size $filesize");
}

foreach my $length (1, 1000) {
    my $filesize = 5 + 1 + (1 + int(log(9 * $length) / log(256))) + 9 * $length;
    my $value = "\x{5317}\x{4eac}\x{5e02}" x $length;
    Data::CompactReadonly->create($filename, $value);
    is($data = Data::CompactReadonly->read($filename), $value, "can create a non-ASCII Text file ($length times three chars, each 3 utf-8 bytes)");
        is((stat($filename))[7], $filesize, "... file is expected size $filesize");
}

foreach my $tuple ( # torture tests
    ['007',   10], # Text
    ['000',   10], # Text
    ['00.7',  11], # Text
    ['00.07', 12], # Text
    ['0.07',  14], # Float
    ['7.01',  14], # Float
    ['7.0',   10], # Text
    ['7.00',  11], # Text
    ['7.10',  11], # Text
) {
    my($value, $filesize) = @{$tuple};
    Data::CompactReadonly->create($filename, $value);
    is($data = Data::CompactReadonly->read($filename), $value, "can create a file with value '$value'");
    is((stat($filename))[7], $filesize, "... file is expected size for data $value") || diag(`hexdump -C $filename`);
}

done_testing;
