use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use File::Temp qw(tempfile);
use String::Binary::Interpolation;

use Data::CompactReadonly;

my $header_bytes = "CROD\x00"; # version 0, byte pointers

my $DICTBYTE = $b10000000;
my $TEXTBYTE = $b00000000;
my $NULL     = $b11101000;
my $SHORT    = $b11001000;

subtest "empty dict", sub {
    open(my $fh, '<', \"$header_bytes$DICTBYTE\x00");
    isa_ok(
        my $dict = Data::CompactReadonly->read($fh),
        "Data::CompactReadonly::V0::Dictionary::Byte"
    );
    is($dict->count(), 0, "0 element dict");
    is($dict->_ptr_size(), 1, "1 byte pointers");
    eq_or_diff($dict->indices(), [], "can list collection indices");
};

subtest "1 element dict", sub {
    open(my $fh, '<', \(
        "\x00\x00".       # these don't count, we'll seek past them before we start
        "$header_bytes".                                     # 0x00
        "$DICTBYTE\x01".                                     # 0x05
        "\x09".    "\x0e".                                   # 0x07 and 0x08
        "$TEXTBYTE\x03cow".                                  # 0x09
        "$TEXTBYTE\x04calf"                                  # 0x0e
    ));
    read($fh, my $blah, 2);
    my $dict = Data::CompactReadonly->read($fh);
    is($dict->_db_base(), 2, "the fh was opened after having already been partially read");
    is($dict->count(), 1, "1 element dict");
    eq_or_diff($dict->indices(), ['cow'], "can list collection indices");
    is($dict->element('cow'), 'calf', "can fetch from a 1 element dict");
};

subtest "dict with Null key", sub {
    open(my $fh, '<', \(
        "$header_bytes".                                     # 0x00
        "$DICTBYTE\x01".                                     # 0x05
        "\x09".    "\x0a".                                   # 0x07 and 0x08
        "$NULL".                                             # 0x09
        "$TEXTBYTE\x04calf"                                  # 0x0a
    ));
    my $dict = Data::CompactReadonly->read($fh);
    is($dict->count(), 1, "1 element dict");
    throws_ok { $dict->indices() }
        qr/Invalid type: Null: Dictionary keys must be Text/,
        "finding a bad key in the index is fatal";
    throws_ok { $dict->element(undef) }
        qr/Invalid element: \[undef\] isn't Text/,
        "asking for a Null key is fatal";
    throws_ok { $dict->element(\"cow") }
        qr/Invalid element: SCALAR.* isn't Text/,
        "asking for a Reference key is fatal";
};

subtest "dict with Collection key", sub {
    open(my $fh, '<', \(
        "$header_bytes".                                     # 0x00
        "$DICTBYTE\x01".                                     # 0x05
        "\x09".    "\x0b".                                   # 0x07 and 0x08
        "$DICTBYTE\x00".                                     # 0x09
        "$TEXTBYTE\x04calf"                                  # 0x0b
    ));
    my $dict = Data::CompactReadonly->read($fh);
    throws_ok { $dict->indices() }
        qr/Invalid type: .*Dictionary::Byte.*: Dictionary keys must be Text/,
        "finding a bad key in the index is fatal";
};

subtest "missing data", sub {
    open(my $fh, '<', \(
        "$header_bytes".                                     # 0x00
        "$DICTBYTE\x01".                                     # 0x05
        "\x09".    "\x0b"                                    # 0x07 and 0x08
    ));
    my $dict = Data::CompactReadonly->read($fh);
    throws_ok { $dict->indices() }
        qr/sysread failed to read/,
        "fatal read errors bomb out fast";
};

subtest "2 element dict", sub {
    open(my $fh, '<', \(
        "$header_bytes".                                     # 0x00
        "$DICTBYTE\x02".                                     # 0x05
        "\x0b".    "\x10".                                   # 0x07 and 0x08
        "\x16".    "\x05".                                   # 0x09 and 0x0a
        "$TEXTBYTE\x03cow".                                  # 0x0b
        "$TEXTBYTE\x04calf".                                 # 0x10
        "$TEXTBYTE\x04dict"                                  # 0x16
    ));
    my $dict = Data::CompactReadonly->read($fh);
    is($dict->count(), 2, "2 element dict");
    eq_or_diff($dict->indices(), ['cow', 'dict'], "can list collection indices");
    is($dict->element('cow'), 'calf', "can fetch element 0 from a 2 element dict");
    isa_ok($dict->element('dict'), 
        'Data::CompactReadonly::V0::Dictionary',
        "can fetch a Dictionary from element 1 of the Dictionary");
    isa_ok($dict->element('dict')->element('dict')->element('dict'),
        'Data::CompactReadonly::V0::Dictionary',
        "it's Dictionaries all the way down");
    is($dict->id(), $dict->element('dict')->element('dict')->id(),
        "circular references to dicts all have the same id");
};

subtest "large odd number of elements in a dict", sub {
    open(my $fh, '<', \(
        "$header_bytes".                                     # 0x00
        "$DICTBYTE\x0b".                                     # 0x05
        "\x1d".    "\x26".                                   # 0x07 and 0x08
        "\x31".    "\x34".                                   # 0x09 and 0x0a
        "\x37".    "\x3a".                                   # 0x0b and 0x0c
        "\x3d".    "\x40".                                   # 0x0d and 0x0e
        "\x43".    "\x46".                                   # 0x0f and 0x10
        "\x49".    "\x4c".                                   # 0x11 and 0x12
        "\x4f".    "\x52".                                   # 0x13 and 0x14
        "\x55".    "\x58".                                   # 0x15 and 0x16
        "\x5b".    "\x5e".                                   # 0x17 and 0x18
        "\x61".    "\x64".                                   # 0x19 and 0x1a
        "\x26".    "\x1d".                                   # 0x1b and 0x1c
        "$TEXTBYTE\x07Beijing".                              # 0x1d
        "$TEXTBYTE\x09\xe5\x8c\x97\xe4\xba\xac\xe5\xb8\x82". # 0x26
        "$TEXTBYTE\x01a".                                    # 0x31
        "$TEXTBYTE\x01A".                                    # 0x34
        "$TEXTBYTE\x01b".                                    # 0x37
        "$TEXTBYTE\x01B".                                    # 0x3a
        "$TEXTBYTE\x01c".                                    # 0x3d
        "$TEXTBYTE\x01C".                                    # 0x40
        "$TEXTBYTE\x01d".                                    # 0x43
        "$TEXTBYTE\x01D".                                    # 0x46
        "$TEXTBYTE\x01e".                                    # 0x49
        "$TEXTBYTE\x01E".                                    # 0x4c
        "$TEXTBYTE\x01f".                                    # 0x49
        "$TEXTBYTE\x01F".                                    # 0x52
        "$TEXTBYTE\x01g".                                    # 0x55
        "$TEXTBYTE\x01G".                                    # 0x58
        "$TEXTBYTE\x01h".                                    # 0x5b
        "$SHORT\x01\x02".                                    # 0x5e
        "$TEXTBYTE\x01i".                                    # 0x61
        "$NULL"                                              # 0x64
    ));
    my $dict = Data::CompactReadonly->read($fh);
    is($dict->count(), 11, "11 element dict");
    eq_or_diff(my $indices = $dict->indices(),
        [ qw(Beijing a b c d e f g h i), "\x{5317}\x{4eac}\x{5e02}" ],
        "can list collection indices");
    foreach my $index (0 .. $#{$indices}) {
        my $wanted = {
            Beijing => "\x{5317}\x{4eac}\x{5e02}",
            "\x{5317}\x{4eac}\x{5e02}" => 'Beijing',
            h => 0x0102,
            i => undef,
            map { $_ => uc($_) } ('a' .. 'g')
        }->{$indices->[$index]};
        is($dict->element($indices->[$index]), $wanted,
            "can fetch element $index from dictionary");
    }
    throws_ok { $dict->element('horse') }
        qr/Invalid element: horse: doesn't exist/,
        "cry like a baby when trying to fetch non-existent elements";
    is($dict->exists('horse'), 0, "exists() works on a non-existent index");
    is($dict->exists('Beijing'), 1, "exists() works on an existent index");
    throws_ok { $dict->exists(undef) }
        qr/Invalid element: \[undef\] isn't Text/,
        "exists() dies when asked for something hopelessly invalid"
};

subtest "large even number of elements dict", sub {
    open(my $fh, '<', \(
        "$header_bytes".                                     # 0x00
        "$DICTBYTE\x06".                                     # 0x05
        "\x13".    "\x16".                                   # 0x07 and 0x08
        "\x19".    "\x1c".                                   # 0x09 and 0x0a
        "\x1f".    "\x22".                                   # 0x0b and 0x0c
        "\x25".    "\x28".                                   # 0x0d and 0x0e
        "\x2b".    "\x2e".                                   # 0x0f and 0x10
        "\x31".    "\x34".                                   # 0x11 and 0x12
        "$TEXTBYTE\x01a".                                    # 0x13
        "$TEXTBYTE\x01A".                                    # 0x16
        "$TEXTBYTE\x01b".                                    # 0x19
        "$TEXTBYTE\x01B".                                    # 0x1c
        "$TEXTBYTE\x01c".                                    # 0x1f
        "$TEXTBYTE\x01C".                                    # 0x22
        "$TEXTBYTE\x01d".                                    # 0x25
        "$TEXTBYTE\x01D".                                    # 0x28
        "$TEXTBYTE\x01e".                                    # 0x2b
        "$TEXTBYTE\x01E".                                    # 0x2e
        "$TEXTBYTE\x01f".                                    # 0x31
        "$TEXTBYTE\x01F"                                     # 0x34
    ));
    my $dict = Data::CompactReadonly->read($fh);
    is($dict->count(), 6, "6 element dict");
    is($dict->element('a'), 'A', 'can fetch element 0 from dictionary');
    is($dict->element('b'), 'B', 'can fetch element 1 from dictionary');
    is($dict->element('c'), 'C', 'can fetch element 2 from dictionary');
    is($dict->element('d'), 'D', 'can fetch element 3 from dictionary');
    is($dict->element('e'), 'E', 'can fetch element 4 from dictionary');
    is($dict->element('f'), 'F', 'can fetch element 5 from dictionary');
};

done_testing;
