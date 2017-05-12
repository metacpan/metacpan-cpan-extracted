#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 31;
use BERT;

my ($perl, $bert, @bytes);

# empty atom
@bytes = (
    131, 100, 0, 0
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Atom');
is($perl, BERT::Atom->new(''), 'empty atom decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'empty atom encode');

# atom
@bytes = (
    131, 100, 0, 5, 97, 116, 0, 111, 109
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Atom');
is($perl, BERT::Atom->new("at\0om"), 'atom decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'atom encode');


@bytes = (
    131, 100, 0, 12, 195, 165, 195, 164, 195, 182, 195, 133, 195, 132,
    195, 150
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Atom');
is($perl, BERT::Atom->new('åäöÅÄÖ'), 'atom unicode decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'atom unicode encode');

# float
@bytes = (
    131, 99, 50, 46, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 
    48, 48, 48, 48, 48, 48, 101, 43, 48, 48, 0, 0, 0, 0, 0
);
$perl = decode_bert(pack 'C*', @bytes);
cmp_ok($perl, '==', 2.0, 'float decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'float encode');

# small integer
@bytes = (
    131, 97, 123
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, 123, 'small integer decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'small integer encode');

# integer
@bytes = (
    131, 98, 0, 0, 48, 57
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, 12345, 'integer decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'integer encode');

@bytes = (
    131, 98, 255, 255, 255, 255
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, -1, 'integer decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'integer encode');

@bytes = (
    131, 98, 248, 0, 0, 0
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, -134217728, 'integer decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'integer encode');

@bytes = (
    131, 110, 4, 1, 1, 0, 0, 8
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, -134217729, 'small big decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'small big encode');

@bytes = (
    131, 98, 7, 255, 255, 255
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, 134217727, 'integer decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'integer encode');

@bytes = (
    131, 110, 4, 0, 0, 0, 0, 8
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, 134217728, 'small big decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'small big encode');

# small big
@bytes = (
    131, 110, 8, 0, 210, 10, 31, 235, 140, 169, 84, 171
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'Math::BigInt');
is($perl, Math::BigInt->new('12345678901234567890'), 'small big decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'small big encode');

# large big
@bytes = (
    131, 111, 0, 0, 1, 2, 0, 210, 10, 63, 206, 150, 241, 207, 172, 75, 241, 
    123, 239, 97, 17, 61, 36, 94, 147, 169, 136, 23, 160, 194, 1, 165, 37, 
    183, 227, 81, 27, 0, 235, 231, 229, 213, 80, 111, 152, 189, 144, 241, 
    195, 221, 82, 131, 209, 41, 252, 38, 234, 72, 195, 49, 119, 241, 7, 
    243, 243, 51, 143, 183, 150, 131, 5, 116, 236, 105, 156, 89, 34, 152, 
    152, 105, 202, 17, 98, 89, 29, 117, 17, 110, 5, 24, 33, 199, 192, 114, 
    243, 26, 88, 91, 61, 77, 137, 41, 149, 178, 1, 141, 140, 224, 200, 10, 
    136, 35, 229, 148, 84, 231, 39, 129, 110, 72, 17, 243, 229, 114, 217, 
    165, 125, 238, 117, 88, 93, 130, 112, 225, 45, 232, 49, 26, 199, 12, 
    193, 17, 121, 251, 223, 189, 113, 17, 225, 236, 132, 208, 149, 77, 
    164, 124, 112, 122, 142, 126, 26, 22, 29, 180, 4, 91, 20, 117, 249, 21, 
    141, 80, 162, 156, 122, 0, 170, 91, 238, 6, 69, 137, 92, 194, 33, 118, 
    205, 79, 87, 40, 85, 225, 114, 52, 75, 111, 40, 166, 159, 159, 175, 
    120, 148, 150, 104, 140, 101, 30, 112, 198, 206, 105, 125, 47, 223, 
    216, 213, 254, 195, 126, 171, 158, 14, 254, 160, 92, 191, 166, 81, 
    215, 10, 240, 107, 218, 239, 92, 184, 45, 43, 205, 193, 127, 16, 226, 
    42, 204, 16, 118, 41, 124, 215, 101, 210, 97, 197, 174, 65, 29, 98, 
    153, 108, 157, 4, 126, 1
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'Math::BigInt');
my $expected = new Math::BigInt '12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890';
is($perl, $expected, 'large big decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'large big encode');
