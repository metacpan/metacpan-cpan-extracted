use strict;
use warnings;
no warnings qw(portable);

use Test::More;
use Test::Differences;
use Test::Exception;

use File::Temp qw(tempfile);
use String::Binary::Interpolation;

use Data::CompactReadonly;

my $header_bytes = "CROD\x00"; # version 0, byte pointers

open(my $fh, '<', \"$header_bytes${b01000000}\x00");
isa_ok(
    my $array = Data::CompactReadonly->read($fh),
    "Data::CompactReadonly::V0::Array::Byte"
);
is($array->count(), 0, "empty array");
is($array->_ptr_size(), 1, "1 byte pointers");
eq_or_diff($array->indices(), [], "can list collection indices");
throws_ok { $array->element(-1) }
    qr/Invalid element: -1: negative/,
    "negative elements are illegal";
throws_ok { $array->element(3.7) }
    qr/Invalid element: 3.7: non-integer/,
    "non-integer elements are illegal";
throws_ok { $array->element('horse') }
    qr/Invalid element: horse: non-integer/,
    "non-numeric elements are illegal";
throws_ok { $array->element(0) }
    qr/Invalid element: 0: out of range/,
    "trying to read beyond end of empty array is fatal";

my $ARRAYBYTE   = $b01000000;
my $ARRAYSHORT  = $b01001000;
my $ARRAYMEDIUM = $b01010000;
my $ARRAYLONG   = $b01011000;
my $TEXTBYTE    = $b00000000;
my $DICTBYTE    = $b10000000;
my $BYTE        = $b11000000;
my $SHORT       = $b11001000;
my $MEDIUM      = $b11010000;
my $LONG        = $b11011000;
my $HUGE        = $b11100000;
my $NULL        = $b11101000;

open($fh, '<', \(
    "\x00\x00".               # these don't count, we'll seek past them before we start
    "$header_bytes".          # 0x00
    "$ARRAYBYTE\x02\x0c\x09". # 0x05 A::Byte, two pointers, dests in reverse order of index
    "$SHORT\x94\x45".         # 0x09 Short, 0x9445
    "$BYTE\x94"               # 0x0c Byte,  0x94
));
read($fh, my $blah, 2);
$array = Data::CompactReadonly->read($fh);
is($array->_db_base(), 2, "the fh was opened after having already been partially read");
isa_ok($array, 'Data::CompactReadonly::V0::Array::Byte');
is($array->count(), 2, "2 element array");
throws_ok { $array->element(94) }
    qr/Invalid element: 94: out of range/,
    "trying to read beyond end of non-empty array is fatal";
is($array->element(0), 0x94, "fetched a Byte element from the array");
is($array->element(1), 0x9445, "fetched a Short element from the array");

open($fh, '<', \(
    "$header_bytes".               # 0x00
    "$ARRAYSHORT\x00\x02\x0d\x0a". # 0x05 A::Short, two pointers
    "$SHORT\x94\x45".              # 0x0a Short,  0x9445
    "$MEDIUM\x12\x34\x56"          # 0x0d Medium, 0x123456
));
$array = Data::CompactReadonly->read($fh);
isa_ok($array, 'Data::CompactReadonly::V0::Array::Short');
is($array->count(), 2, "2 element array");
is($array->element(0), 0x123456, "fetched a Medium element from the array");
is($array->element(1), 0x9445,   "fetched a Short element from the array");

open($fh, '<', \(
    "$header_bytes".                         # 0x00
    "$ARRAYSHORT\x00\x03\x10\x0b\x19".       # 0x05 A::Short, three pointers
    "$LONG\xab\xcd\xef\x01".                 # 0x0b Long,  0xabcdef01
    "$HUGE\xfe\xdc\xba\x98\x76\x54\x32\x10". # 0x10 Huge,  0xfedcba9876543210
    "$NULL"                                  # 0x19
));
$array = Data::CompactReadonly->read($fh);
isa_ok($array, 'Data::CompactReadonly::V0::Array::Short');
is($array->count(), 3, "3 element array");
is($array->element(0), 0xfedcba9876543210, "fetched a Huge element from the array");
is($array->element(1), 0xabcdef01,         "fetched a Long element from the array");
is($array->element(2), undef,              "fetched a Null element from the array");
eq_or_diff($array->indices(), [0, 1, 2], "can list collection indices");

open($fh, '<', \(
    "CROD${b00000001}".                      # 0x00 pointers are Shorts
    "$ARRAYSHORT\x00\x06".                   # 0x05 A::Short, 6 elements
    "\x00\x19".
    "\x00\x14".
    "\x00\x22".
    "\x00\x23".
    "\x00\x05".               # NB pointer to the array it's a member of
    "\x00\x2e".
    "$LONG\xab\xcd\xef\x01".                 # 0x14 Long,  0xabcdef01
    "$HUGE\xfe\xdc\xba\x98\x76\x54\x32\x10". # 0x19 Huge,  0xfedcba9876543210
    "$NULL".                                 # 0x22
    "$TEXTBYTE\x09Fran\xc3\xa7ais".          # 0x23 Text,  Franc,ais
    "$DICTBYTE\x00"                          # 0x2e Dictionary, empty
));
$array = Data::CompactReadonly->read($fh);
isa_ok($array, 'Data::CompactReadonly::V0::Array::Short');
is($array->_ptr_size(), 2, "2 byte pointers");
is($array->count(), 6, "6 element array");
is($array->element(0), 0xfedcba9876543210, "fetched a Huge element from the array");
is($array->element(1), 0xabcdef01,         "fetched a Long element from the array");
is($array->element(2), undef,              "fetched a Null element from the array");
is($array->element(3), "Fran\xe7ais",      "fetched a Text element from the array");
isa_ok(my $array2 = $array->element(4),
    'Data::CompactReadonly::V0::Array::Short',
    "fetched an Array element from the array");
isa_ok($array->element(5),    # no further tests for this here
    'Data::CompactReadonly::V0::Dictionary::Byte',
    "fetched a Dictionary element from the array");
is($array2->_ptr_size(), 2, "2 byte pointers");
is($array2->count(), 6, "6 element array");
is($array2->element(0), 0xfedcba9876543210, "fetched a Huge element from the array");
is($array2->element(1), 0xabcdef01,         "fetched a Long element from the array");
is($array2->element(2), undef,              "fetched a Null element from the array");
is($array2->element(3), "Fran\xe7ais",      "fetched a Text element from the array");
isa_ok($array2->element(4),
    'Data::CompactReadonly::V0::Array::Short',
    "fetched an Array element from the embedded array");
isa_ok($array->element(4)->element(4)->element(4)->element(4)->element(4),
    'Data::CompactReadonly::V0::Array::Short',
    "it's arrays all the way down");
is($array->id(), $array->element(4)->element(4)->id(),
    "circular references to arrays all have the same id");
is($array->exists(6), 0, "exists() works on a non-existent element");
is($array->exists(2), 1, "exists() works on an existent element");
throws_ok { $array->exists(-1) } qr/negative/,
    "exists() dies as expected on an illegal (negative) index";
throws_ok { $array->exists('horse') } qr/non-integer/,
    "exists() dies as expected on an illegal (non-integer) index";

# at this point we've tested Array::Byte and ::Short, and 1 and 2 byte
# pointers. We now test 3, 4, and 8 byte pointers (can't be arsed with
# 5/6/7, they'll obviously work if 8 works) and Array::Medium and
# Array::Long. We've also fetched all types from the array except Dictionaries

open($fh, '<', \(
    "CROD${b00000010}".                           # 0x00 pointers are Mediums
    "$ARRAYLONG\x00\x00\x00\x01".                 # 0x05 array has 1 member
    "\x00\x00\x0d".                               # 0x0a
    "$BYTE\x09"                                   # 0x0d
));
$array = Data::CompactReadonly->read($fh);
isa_ok($array, 'Data::CompactReadonly::V0::Array::Long');
is($array->count(), 1, "1 element array");
is($array->_ptr_size(), 3, "3 byte pointers");
is($array->element(0), 9, "can fetch");

open($fh, '<', \(
    "CROD${b00000011}".                           # 0x00 pointers are Longs
    "$ARRAYLONG\x00\x00\x00\x01".                 # 0x05 array has 1 member
    "\x00\x00\x00\x0e".                           # 0x0a
    "$BYTE\x09"                                   # 0x0e
));
$array = Data::CompactReadonly->read($fh);
isa_ok($array, 'Data::CompactReadonly::V0::Array::Long');
is($array->count(), 1, "1 element array");
is($array->_ptr_size(), 4, "4 byte pointers");
is($array->element(0), 9, "can fetch");

open($fh, '<', \(
    "CROD${b00000111}".                           # 0x00 pointers are Huges
    "$ARRAYMEDIUM\x00\x00\x01".                   # 0x05 array has 1 member
    "\x00\x00\x00\x00\x00\x00\x00\x11".           # 0x09
    "$BYTE\x09"                                   # 0x11
));
$array = Data::CompactReadonly->read($fh);
isa_ok($array, 'Data::CompactReadonly::V0::Array::Medium');
is($array->count(), 1, "1 element array");
is($array->_ptr_size(), 8, "8 byte pointers");
is($array->element(0), 9, "can fetch");

done_testing;
