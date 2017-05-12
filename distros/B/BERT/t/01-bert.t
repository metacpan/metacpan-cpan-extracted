#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;
use BERT;

my ($perl, $bert, @bytes);

# integer
@bytes = ( 
    131, 97, 4
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, 4, 'integer decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'integer encode');

# float
@bytes = ( 
    131, 99, 56, 46, 49, 53, 49, 54, 48, 48, 48, 48, 48, 48, 48, 48, 
    48, 48, 48, 49, 55, 57, 48, 54, 101, 43, 48, 48, 0, 0, 0, 0, 0
);
$perl = decode_bert(pack 'C*', @bytes);
is(sprintf('%.16g', $perl), sprintf('%.16g', 8.1516), 'float decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'float encode');

# atom
@bytes = (
    131, 100, 0, 3, 102, 111, 111
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Atom');
is($perl, BERT::Atom->new('foo'), 'atom decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'atom encode');

# tuple
@bytes = (
    131, 104, 3, 100, 0, 5, 99, 111, 111, 114, 100, 97, 23, 97, 42
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Tuple');
is_deeply($perl, BERT::Tuple->new([BERT::Atom->new('coord'), 23, 42]), 'tuple decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'tuple encode');

# bytelist
@bytes = (
    131, 107, 0, 3, 1, 2, 3
);
$perl = decode_bert(pack 'C*', @bytes);
is_deeply($perl, [1, 2, 3], 'bytelist decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'bytelist encode');

# list
@bytes = (
    131, 108, 0, 0, 0, 2, 100, 0, 1, 97, 107, 0, 2, 1, 2, 106
);
$perl = decode_bert(pack 'C*', @bytes);
is_deeply($perl, [BERT::Atom->new('a'), [1, 2]], 'list decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'list encode');

# binary
@bytes = (
    131, 109, 0, 0, 0, 30, 82, 111, 115, 101, 115, 32, 97, 114, 101, 
    32, 114, 101, 100, 0, 86, 105, 111, 108, 101, 116, 115, 32, 97,
    114, 101, 32, 98, 108, 117, 101
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, "Roses are red\0Violets are blue", 'binary decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'binary encode');

# nil
@bytes = (
    131, 104, 2, 100, 0, 4, 98, 101, 114, 116, 100, 0, 3, 110, 105, 108
);
$perl = decode_bert(pack 'C*', @bytes);
is($perl, undef, 'nil decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'nil encode');
$bert = encode_bert();
is_deeply([ unpack 'C*', $bert ], \@bytes, 'nil encode');

# boolean 
@bytes = ( 
    131, 104, 2, 100, 0, 4, 98, 101, 114, 116, 100, 0, 4, 116, 114, 117, 101
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Boolean');
is_deeply($perl, BERT::Boolean->true, 'true decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'true encode');

@bytes = (
    131, 104, 2, 100, 0, 4, 98, 101, 114, 116, 100, 0, 5, 102, 97, 108, 115, 101
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Boolean');
is_deeply($perl, BERT::Boolean->false, 'false decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'false encode');

# dictionary
@bytes = (
    131, 104, 3, 100, 0, 4, 98, 101, 114, 116, 100, 0, 4, 100, 105, 99, 116, 106
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Dict');
is_deeply($perl, BERT::Dict->new([]), 'empty dict decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'empty dict encode');
$bert = encode_bert({});
is_deeply([ unpack 'C*', $bert ], \@bytes, 'empty dict encode');

@bytes = (
    131, 104, 3, 100, 0, 4, 98, 101, 114, 116, 100, 0, 4, 100, 105, 99, 116, 
    108, 0, 0, 0, 2, 104, 2, 100, 0, 4, 110, 97, 109, 101, 109, 0, 0, 0, 3,
    84, 111, 109, 104, 2, 100, 0, 3, 97, 103, 101, 97, 30, 106
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Dict');
is_deeply($perl, BERT::Dict->new([ BERT::Atom->new('name') => 'Tom', BERT::Atom->new('age') => 30 ]), 'dict decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'dict encode');

# time
@bytes = (
    131, 104, 5, 100, 0, 4, 98, 101, 114, 116, 100, 0, 4, 116, 105, 109, 101,
    98, 0, 0, 4, 231, 98, 0, 4, 130, 157, 98, 0, 6, 207, 20
);
$perl = decode_bert(pack 'C*', @bytes);
isa_ok($perl, 'BERT::Time');
is_deeply($perl, BERT::Time->new(1255 * 1_000_000 + 295581, 446228), 'time decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'time encode');

# regex
@bytes = (
    131, 104, 4, 100, 0, 4, 98, 101, 114, 116, 100, 0, 5, 114, 101, 103, 101, 
    120, 109, 0, 0, 0, 8, 94, 99, 40, 97, 42, 41, 116, 36, 108, 0, 0, 0, 1,
    100, 0, 8, 99, 97, 115, 101, 108, 101, 115, 115, 106
);
$perl = decode_bert(pack 'C*', @bytes);
is_deeply($perl, qr/^c(a*)t$/i, 'regex decode');
$bert = encode_bert($perl);
is_deeply([ unpack 'C*', $bert ], \@bytes, 'regex encode');

