use strict;
use warnings;
no warnings qw(portable);

use File::Temp qw(tempfile);
use Scalar::Type qw(bool_supported);
Scalar::Type->import('is_bool') if(bool_supported());
use Test::More;
use Test::Exception;
use lib 't/lib';
use TestFloat;

use Data::CompactReadonly;

(undef, my $filename) = tempfile(UNLINK => 1);

Data::CompactReadonly->create($filename, []);
isa_ok(my $data = Data::CompactReadonly->read($filename), 'Data::CompactReadonly::V0::Array::Byte',
    "can create an Array::Byte");
isa_ok($data, 'Data::CompactReadonly::Array', "and that isa Data::CompactReadonly::Array");
is($data->count(), 0, "it's empty");
is((stat($filename))[7], 7, "file size is correct");

my $true = 1 == 1;
my $false = 1 == 0;
my $array = [
    # header                        5 bytes
    # OMGANARRAY                    1 byte
    # number of elements (in Byte)  1 byte
    # 14 pointers                  14 bytes
    0x10000,     # Scalar::Medium,  4 bytes
    undef,       # Scalar::Null,    1 byte
    "apple",     # Text::Byte,      7 bytes
    0x1,         # Scalar::Byte,    2 bytes
    0x100,       # Scalar::Short,   3 bytes 
    3.4,         # Scalar::Float64, 9 bytes
    0x12345678,  # Scalar::Long,    5 bytes
    0x100000000, # Scalar::Huge,    9 bytes
    0x100000000, # Scalar::Huge, no storage, same as one already in db
    "apple",     # Text::Byte, no storage
    $true,       # Scalar::True,    1 byte
    $true,       # Scalar::True, no storage
    $false,      # Scalar::False,   1 byte
    'x' x 256    # Text::Short,     259 bytes
];
Data::CompactReadonly->create($filename, $array);
isa_ok($data = Data::CompactReadonly->read($filename), 'Data::CompactReadonly::V0::Array::Byte',
    "got another Array::Byte");
# yes, 1 byte despite the file being more than 255 bytes long. The
# last thing pointed to starts before the boundary.
is($data->_ptr_size(), 1, "pointers are 1 byte");
is($data->count(), 14, "got a non-empty array");
is($data->element(0), 0x10000,     "read a Medium from the array");
is($data->element(1), undef,       "read a Null");
is($data->element(2), 'apple',     "read a Text::Byte");
is($data->element(3), 1,           "read a Byte");
is($data->element(4), 256,         "read a Short");
cmp_float($data->element(5), 3.4,  "read a Float64");
is($data->element(6), 0x12345678,  "read a Long");
is($data->element(7), 0x100000000, "read a Huge");
is($data->element(8), 0x100000000, "read another Huge");
is($data->element(9), 'apple',     "read another Text");

ok($data->element(10),             "read a True");
if(bool_supported) {
    ok(is_bool($data->element(10)), "and on super-modern perl the Boolean flag is set correctly");
} 

ok($data->element(11),             "read another True");
if(bool_supported) {
    ok(is_bool($data->element(11)), "and on super-modern perl the Boolean flag is set correctly");
} 

ok(!$data->element(12),            "read a False");
if(bool_supported) {
    ok(is_bool($data->element(12)), "and on super-modern perl the Boolean flag is set correctly");
} 

is($data->element(13), 'x' x 256,  "read another Text");
is((stat($filename))[7], 322, "file size is correct");


push @{$array}, [], $array;
Data::CompactReadonly->create($filename, $array);
isa_ok($data = Data::CompactReadonly->read($filename), 'Data::CompactReadonly::V0::Array::Byte',
    "got another Array::Byte");
# last item pointed at is too far along for 1 byte pointers.
# TODO alter the order in which things are added to the file so
# that this array can have items after the long text, but they're
# stored before it, so we can keep using short pointers for longer
is($data->_ptr_size(), 2, "pointers are 2 bytes");
is($data->count(), 16, "got a non-empty array");
is($data->element(0), 0x10000,     "read a Medium from the array");
is($data->element(1), undef,       "read a Null");
is($data->element(2), 'apple',     "read a Text::Byte");
is($data->element(3), 1,           "read a Byte");
is($data->element(4), 256,         "read a Short");
cmp_float($data->element(5), 3.4,  "read a Float64");
is($data->element(6), 0x12345678,  "read a Long");
is($data->element(7), 0x100000000, "read a Huge");
is($data->element(8), 0x100000000, "read another Huge");
is($data->element(9), 'apple',     "read another Text");
ok($data->element(10),             "read a True");
if(bool_supported) {
    ok(is_bool($data->element(10)), "and on super-modern perl the Boolean flag is set correctly");
} 
ok($data->element(11),             "read another True");
if(bool_supported) {
    ok(is_bool($data->element(11)), "and on super-modern perl the Boolean flag is set correctly");
} 
ok(!$data->element(12),            "read a False");
if(bool_supported) {
    ok(is_bool($data->element(12)), "and on super-modern perl the Boolean flag is set correctly");
} 
is($data->element(13), 'x' x 256,  "read a Text::Short");
isa_ok(my $embedded_array = $data->element(14), 'Data::CompactReadonly::V0::Array::Byte',
    "can embed an array in an array");
is($embedded_array->count(), 0, "sub-array is empty");
is($data->element(15)->element(15)->element(14)->id(),
   $embedded_array->id(),
   "circular array-refs work");
# this is:
#   original size +
#   two extra pointers +
#   sixteen for the pointers now being Shorts
#   two for the empty array
is((stat($filename))[7], 322 + 2 + 16 + 2, "file size is correct");

Data::CompactReadonly->create($filename, {});
isa_ok($data = Data::CompactReadonly->read($filename), 'Data::CompactReadonly::V0::Dictionary::Byte',
    "got a Dictionary::Byte");
is($data->count(), 0, "it's empty");
is($data->_ptr_size(), 1, "pointers are 1 byte");

my $hash = {
    # header                          5 bytes
    # OMGADICT                        1 byte
    # number of elements (in Byte)    1 byte
    # 20 pairs of pointers         #  40 bytes
    true   => $true,               #  6 bytes for key, 1 for value
    false  => $false,              #  7 bytes for key, 1 for value
    $false => $false,              #  2 bytes for stringified key, value is FREE!!!
    float  => 3.14,                #  7 bytes for key, 9 bytes for value
    byte   => 65,                  #  6 bytes for key, 2 bytes for value
    short  => 65534,               #  7 bytes for key, 3 bytes for value
    medium => 65536,               #  8 bytes for key, 4 bytes for value
    long   => 0x1000000,           #  6 bytes for key, 5 bytes for value
    huge   => 0xffffffff1,         #  6 bytes for key, 9 bytes for value
    array  => [],                  #  7 bytes for key, 2 bytes for value 
    dict   => {},                  #  6 bytes for key, 2 bytes for value
    null   => undef,               #  6 bytes for key, 1 byte for value
    text      => 'hi mum!',        #  6 bytes for key, 9 bytes for value (Text::Byte)
    'hi mum!' => 'hi mum!',        #     free!!! storage
    "\x{5317}\x{4eac}\x{5e02}" => 'Beijing', # 11 bytes for key, 9 bytes for value
    'Beijing' => "\x{5317}\x{4eac}\x{5e02}", #     free storage
    2      => 65,                  #  3 bytes for key, free storage for value
    900    => 65,                  #  5 bytes for key, free storage for value
    6.28   => 65,                  #  6 bytes for key, free storage for value
    # the last element in the hash, cos its key sorts last
    zzlongtext => 'z' x 300,       # 12 bytes for key, 303 for value (Text::Short)
    # 524 bytes total
};
Data::CompactReadonly->create($filename, $hash);
isa_ok($data = Data::CompactReadonly->read($filename), 'Data::CompactReadonly::V0::Dictionary::Byte',
    "got a Dictionary::Byte");
isa_ok($data, 'Data::CompactReadonly::Dictionary', "and that isa Data::CompactReadonly::Dictionary");
is($data->count(), 20, "20 entries");
is($data->_ptr_size(), 1, "pointers are 1 byte");
cmp_float($data->element('float'), 3.14,        "read a Float64");

ok($data->element('true'),   "read a True");
if(bool_supported) {
    ok(is_bool($data->element('true')), "and on super-modern perl the Boolean flag is set correctly");
} 
ok(!$data->element('false'), "read a False");
if(bool_supported) {
    ok(is_bool($data->element('false')), "and on super-modern perl the Boolean flag is set correctly");
} 
ok(!$data->element($false),  "False as a key");
if(bool_supported) {
    ok(is_bool($data->element($false)), "and on super-modern perl the Boolean flag is set correctly");
} 

is($data->element('byte'),         65,          "read a Byte");
is($data->element('short'),        65534,       "read a Short");
is($data->element('medium'),       65536,       "read a Medium");
is($data->element('long'),         0x1000000,   "read a Long");
is($data->element('huge'),         0xffffffff1, "read a Huge");
is($data->element('null'),         undef,       "read a Null");
is($data->element('text'),         'hi mum!',   "read a Text::Byte");
is($data->element('hi mum!'),      'hi mum!',   "read the same text again (reused)");
is($data->element('zzlongtext'),   'z' x 300,   "read a Text::Short");
isa_ok($embedded_array = $data->element('array'), 'Data::CompactReadonly::V0::Array::Byte',
    "read an array from the Dictionary");
is($embedded_array->count(), 0, "array is empty");
isa_ok(my $embedded_dict = $data->element('dict'), 'Data::CompactReadonly::V0::Dictionary::Byte',
    "read a dictionary from the Dictionary");
is($embedded_dict->count(), 0, "dict is empty");
is($data->element("\x{5317}\x{4eac}\x{5e02}"),
    "Beijing", "non-ASCII keys work");
is($data->element('Beijing'), "\x{5317}\x{4eac}\x{5e02}",
    "non-ASCII values work");
is((stat($filename))[7], 524, "file size is correct");
if(bool_supported) {
    ok((!grep { is_bool($_) } $data->indices), "bools as keys are stringified");
}

# the previous 20 pointer pairs are now 20 * 2 * _2_ bytes == 80, so an extra 40 bytes
$hash->{zzz} = 'say the bees'; # extra pair of pointers (4 bytes), plus 5 bytes for key, 14 bytes for value
Data::CompactReadonly->create($filename, $hash);
isa_ok($data = Data::CompactReadonly->read($filename), 'Data::CompactReadonly::V0::Dictionary::Byte',
    "got a Dictionary::Byte");
is($data->count(), 21, "got a hash with 18 entries");
is($data->_ptr_size(), 2, "pointers are 2 bytes");
is($data->element('null'), undef,          "read a Null");
is($data->element('text'), 'hi mum!',      "read a Text::Byte");
is($data->element('zzz'),  'say the bees', "can retrieve data after the long text");
is(
    (stat($filename))[7],
    587, # 524 (original size) + 40 (extra pointer bytes for previous data) + 23 (new pointers/data)
    "file size is correct"
);

$hash = {
    'Bond' => '007',
    '007'  => 'Bond',
    '0.07' => 'Baby Bond',
    '00.7' => 'Weird Bond',
    '000'  => 'Georgian Bond',
    array  => [ 5, 'four', [ 3 ], { two => 2 }, 1 ],
    '7.0'  => 'seven point oh',
    '7.00' => 'seven point oh oh',
    '7.10' => 'seven point one oh',
};
$hash->{dict} = $hash;
$hash->{$_} = $_ foreach(0 .. 65536); # Dictionary::Medium, longer 3 byte pointers
push @{$hash->{array}}, $hash->{array};
Data::CompactReadonly->create($filename, $hash);
isa_ok($data = Data::CompactReadonly->read($filename), 'Data::CompactReadonly::V0::Dictionary::Medium',
    "got a Dictionary::Medium");
isa_ok($data, 'Data::CompactReadonly::Dictionary', "and that isa Data::CompactReadonly::Dictionary");
is($data->count(), 65547, "right number of elements");
is($data->_ptr_size(), 3, "pointers are 3 bytes");
is($data->element('array')->element(2)->element(0), 3,
    "can retrieve from an array in an array in a hash");
is($data->element('array')->element(3)->element('two'), 2,
    "can retrieve from a hash in an array in a hash");
is($data->element('dict')->element(65535), 65535,
    "can retrieve from an array in a hash");
is($data->element('dict')->element('array')->element(3)->element('two'), 2,
    "can retrieve from a hash in an array in a hash in a hash");
is($data->element('Bond'), '007', "can store text that looks like a number with leading zeroes");
is($data->element('007'), 'Bond', "... and use it as a key too");
is($data->element(0.07), 'Baby Bond', "zero point something works when presented as a number");
is($data->element('0.07'), 'Baby Bond', "zero point something works when presented as text");
is($data->element('00.7'), 'Weird Bond', "00.7 isn't numeric, gets properly encoded as text");
is($data->element('000'), 'Georgian Bond', 'but 000 is a bunch of characters');
is($data->element('7.0'), 'seven point oh', 'trailing zeroes on strings that look like floats are preserved (7.0)');
is($data->element('7.00'), 'seven point oh oh', 'trailing zeroes on strings that look like floats are preserved (7.00)');
is($data->element('7.10'), 'seven point one oh', 'trailing zeroes on strings that look like floats are preserved (7.10)');
throws_ok { $data->element(7.1) } qr/Invalid element: 7.1: doesn't exist/, "key 7.10 is not the same as key 7.1";

Data::CompactReadonly->create($filename, [
                  { aardvark => 'bat', cat => 'doge' },                 
    [ [ 65, 66 ], { aardvark => 'bat', cat => 'doge' } ],
      [ 65, 66 ]
]);
# this would be 64 without array/hash de-duping
is((stat($filename))[7], 54, "arrays and dictionaries aren't repeated if their contents are identical");

done_testing;
