#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Data::ParseBinary;
use Test::More;
$| = 1;

my $data;
my $string;
my $s;
my $s1;

ok( UBInt16("foo")->parse("\x01\x02") == 258, "Primitive: Parse: UBInt16");
ok( ULInt16("foo")->parse("\x01\x02") == 513, "Primitive: Parse: ULInt16");
ok( UBInt16("foo")->build(31337) eq 'zi', "Primitive: Build: UBInt16");
ok( SBInt16("foo")->build(-31337) eq "\x85\x97", "Primitive: Build: SBInt16");
ok( SLInt16("foo")->build(-31337) eq "\x97\x85", "Primitive: Build: SLInt16");

ok( BFloat32("foo")->build(5) eq "\x40\xa0\0\0", "Primitive: Build: BFloat32");
ok( LFloat32("foo")->build(5) eq "\0\0\xa0\x40", "Primitive: Build: LFloat32");
ok( BFloat32("foo")->parse("\x40\xa0\0\0") == 5, "Primitive: Parse: BFloat32");
ok( LFloat64("foo")->build(5) eq "\0\0\0\0\0\0\x14\x40", "Primitive: Build: LFloat64");
ok( LFloat64("foo")->parse("\0\0\0\0\0\0\x14\x40") == 5, "Primitive: Build: LFloat64");

$s = Struct("foo",
    UBInt8("a"),
    SLInt16("b")
);
$data = {a => 7, b => 256};
$string = "\x07\x00\x01";
is_deeply($s->parse($string), $data, "Struct: Parse: correct");
ok( $s->build($data) eq $string, "Struct: Build: Rebuild1");
$data->{b} = 5000;
ok( $s->build($data) eq "\x07\x88\x13", "Struct: Build: Rebuild2");

$s = Struct("foo",
    UBInt8("a"),
    UBInt16("b"),
    Struct("bar",
        UBInt8("a"),
        UBInt16("b"),
    )
);
$data = {a=>65, b=>16962, bar=>{ a=>97, b=> 25186}};
$string = "ABBabb";
is_deeply($s->parse($string), $data, "Nested Struct: Parse: correct");
ok( $s->build($data) eq $string, "Nested Struct: Build: Rebuild1");

$s = Sequence("foo",
    UBInt8("a"),
    UBInt16("b")
);
$data = [97, 25186];
$string = "abb";
is_deeply($s->parse($string), $data, "Sequence: Parse: correct");
ok( $s->build($data) eq $string, "Sequence: Build: Rebuild1");
ok( $s->build([1,2]) eq "\x01\x00\x02", "Sequence: Build: correct");

$s = Sequence("foo",
    UBInt8("a"),
    UBInt16("b"),
    Sequence("bar",
        UBInt8("a"),
        UBInt16("b"),
    )
);
$data = [65, 16962, [97, 25186]];
$string = "ABBabb";
is_deeply($s->parse($string), $data, "Nested Sequence: Parse: correct");
ok( $s->build($data) eq $string, "Nested Sequence: Build: correct");

$s = Array(4, UBInt8("foo"));
$data = $s->parse("\x01\x02\x03\x04");
is_deeply( $s->parse("\x01\x02\x03\x04"), [1..4], "StrictRepeater: Parse: correct elements1");
eval { $data = $s->parse("\x01\x02\x03") };
ok( $@ , "StrictRepeater: Parse: Die on too few elements");
is_deeply( $s->parse("\x01\x02\x03\x04\x05"), [1..4], "StrictRepeater: Parse: correct elements2");
ok( $s->build([5,6,7,8]) eq "\x05\x06\x07\x08", "StrictRepeater: Build: normal build");
eval { $s->build([5,6,7,8,9]) };
ok( $@, "StrictRepeater: Build: dies on too many elements");

$s = Array(5, Array(2, UBInt8("foo")));
$data = [[97,97], [98,98], [99,99], [100,100], [101,101]];
$string = "aabbccddee";
is_deeply($s->parse($string), $data, "Nested StrictRepeater: Parse: correct");
ok( $s->build($data) eq $string, "Nested StrictRepeater: Build: correct");

$s = Struct("foo",
    Padding(2),
    Flag("myflag"),
    Padding(5),
);
$data = {myflag => 1};
$string = "\x00\x00\x01\x00\x00\x00\x00\x00";
is_deeply($s->parse($string), $data, "Struct with Padding, Flag: Parse: correct");
ok( $s->build($data) eq $string, "Struct with Padding, Flag: Build: correct");

$s = BitStruct("foo",
    Padding(2),
    Flag("myflag"),
    Padding(5),
);
$data = {myflag => 1};
$string = "\x20";
is_deeply($s->parse($string), $data, "BitStruct with Padding, Flag: Parse: correct");
ok( $s->build($data) eq $string, "BitStruct with Padding, Flag: Build: correct");

$s = BitStruct("foo",
    BitField("a", 3),
    Flag("b"),
    Padding(3),
    Nibble("c"),
    BitField("d", 5),
);
$data = {a=>7, b=>0, c=>8, d=>31};
$string = "\xe1\x1f";
is_deeply($s->parse($string), $data, "BitStruct: Parse: correct");
ok( $s->build($data) eq $string, "BitStruct: Build: correct");

$s = BitStruct("foo",
    BitField("a", 3),
    Flag("b"),
    Padding(3),
    Nibble("c"),
    Struct("bar",
        Nibble("d"),
        Bit("e"),
    )
);
$data = { a=>7, b=>0, c=>8, bar=>{ d=>15, e=>1 } };
$string = "\xe1\x1f";
is_deeply($s->parse($string), $data, "Nested BitStruct: Parse: correct");
ok($s->build($data) eq $string, "Nested BitStruct: Build: correct");

$s = BitStruct("foo",
    BitField("a", 3),
    Flag("b"),
    Byte("c"),
);
$data = { a=>7, b=>0, c=>59 };
$string = "\xe3\xb0";
is_deeply($s->parse($string), $data, "BitStruct with Byte: Parse: correct");
ok( $s->build($data) eq $string, "BitStruct with Byte: Build: correct");

$s = Enum(Byte("protocol"),
    TCP => 6,
    UDP => 17,
);
ok( $s->parse("\x06") eq 'TCP', "Enum: correct1");
ok( $s->parse("\x11") eq 'UDP', "Enum: correct1");
eval { $s->parse("\x12") };
ok( $@, "Enum: dies on undeclared value with default");
ok( $s->build("TCP") eq "\x06", "Enum: build 1");
ok( $s->build("UDP") eq "\x11", "Enum: build 2");

$s = Enum(Byte("protocol"),
    TCP => 6,
    UDP => 17,
    _default_ => blah => 99,
);
ok( $s->parse("\x11") eq 'UDP', "Enum with default: correct1");
ok( $s->parse("\x12") eq 'blah', "Enum with default: correct2");
ok( $s->build("TCP") eq "\x06", "Enum with default: build 1");
ok( $s->build("blah") eq "\x63", "Enum with default: build default");

$s = Enum(Byte("protocol"),
    TCP => 6,
    UDP => 17,
    _default_ => $DefaultPass,
);
ok( $s->parse("\x11") eq 'UDP', "Enum with pass: correct1");
ok( $s->parse("\x12") == 18, "Enum with pass: correct2");
ok( $s->parse("\xff") == 255, "Enum with pass: correct3");
ok( $s->build("TCP") eq "\x06", "Enum with pass: build 1");
ok( $s->build(18) eq "\x12", "Enum with pass: build 2");
ok( $s->build(255) eq "\xff", "Enum with pass: build 3");

ok( OneOf(UBInt8("foo"), [4,5,6,7])->parse("\x05") == 5, "OneOf: Parse: passing");
eval { OneOf(UBInt8("foo"), [4,5,6,7])->parse("\x08") };
ok( $@, "OneOf: Parse: blocking");
ok( OneOf(UBInt8("foo"), [4,5,6,7])->build(5) eq "\x05", "OneOf: Build: passing");
eval { OneOf(UBInt8("foo"), [4,5,6,7])->build(8) };
ok( $@, "OneOf: Build: blocking");

ok( NoneOf(UBInt8("foo"), [4,5,6,7])->parse("\x08") == 8, "NoneOf: Parse: passing");
eval { NoneOf(UBInt8("foo"), [4,5,6,7])->parse("\x06") };
ok( $@, "NoneOf: Parse: blocking");
ok( NoneOf(UBInt8("foo"), [4,5,6,7])->build(8) eq "\x08", "NoneOf: Build: passing");
eval { NoneOf(UBInt8("foo"), [4,5,6,7])->build(6) };
ok( $@, "NoneOf: Build: blocking");

$s = Struct("foo",
    Byte("length"),
    Field("data", sub { $_->ctx->{length} }),
);
$data = {data=> 'ABC', length => 3};
$string = "\x03ABC";
is_deeply( $s->parse($string), $data, "MetaField: Parse: correct1");
ok( $s->build($data) eq $string, "MetaField: Build: correct1");
$data = {data=> 'ABCD', length => 4};
$string = "\x04ABCD";
is_deeply( $s->parse($string), $data, "MetaField: Parse: correct2");
ok( $s->build($data) eq $string, "MetaField: Build: correct2");

ok( Field("foo", 3)->parse("ABCD") eq "ABC", "Field: Parse: route to StaticField");
ok( Field("foo", sub {return 3})->parse("ABCD") eq "ABC", "Field: Parse: route to MetaField");

$s = Struct("foo",
    Byte("length"),
    Array(sub { $_->ctx->{length}}, UBInt16("data")),
);
$data = {length => 3, data => [1,2,3]};
$string = "\x03\x00\x01\x00\x02\x00\x03";
is_deeply( $s->parse($string), $data, "MetaRepeater: Parse: correct");
ok( $s->build($data) eq $string, "MetaRepeater: Build: correct");

$s = RepeatUntil(sub {$_->obj eq "\x00"}, Field("data", 1));
$data = [ split('', "abcdef\x00") ];
$string = "abcdef\x00this is another string";
is_deeply( $s->parse($string), $data, "RepeatUntil: Parse: correct");
$string = "abcdef\x00";
ok( $s->build($data) eq $string, "RepeatUntil: Build: correct");

$s = Struct("foo",
    Enum(Byte("type"),
        INT1 => 1,
        INT2 => 2,
        INT4 => 3,
        STRING => 4,
    ),
    Switch("data", sub { $_->ctx->{type} },
        {
            "INT1" => UBInt8("spam"),
            "INT2" => UBInt16("spam"),
            "INT4" => UBInt32("spam"),
            "STRING" => String("spam", 6),
        }
    )
);
$data = {type => 'INT1', data => 18};
$string = "\x01\x12";
is_deeply( $s->parse($string), $data, "Switch: Parse: correct1");
ok( $s->build($data) eq $string, "Switch: Build: correct1");
$data = {type => 'INT2', data => 4660};
$string = "\x02\x12\x34";
is_deeply( $s->parse($string), $data, "Switch: Parse: correct2");
ok( $s->build($data) eq $string, "Switch: Build: correct2");
$data = {type => 'INT4', data => 305419896};
$string = "\x03\x12\x34\x56\x78";
is_deeply( $s->parse($string), $data, "Switch: Parse: correct3");
ok( $s->build($data) eq $string, "Switch: Build: correct3");
$data = {type => 'STRING', data => 'abcdef'};
$string = "\x04abcdef";
is_deeply( $s->parse($string), $data, "Switch: Parse: correct4");
ok( $s->build($data) eq $string, "Switch: Build: correct4");

$s = Struct("foo",
    Byte("type"),
    Switch("data", sub { $_->ctx->{type} },
        {
            1 => UBInt8("spam"),
            2 => UBInt16("spam"),
        },
        default => UBInt8("spam")
    )
);
$data = {type => 1, data => 255};
$string = "\x01\xff";
is_deeply( $s->parse($string), $data, "Switch with default: Parse: correct1");
ok( $s->build($data) eq $string, "Switch with default: Build: correct1");
$data = {type => 2, data => 65535};
$string = "\x02\xff\xff";
is_deeply( $s->parse($string), $data, "Switch with default: Parse: correct2");
ok( $s->build($data) eq $string, "Switch with default: Build: correct2");
$data = {type => 3, data => 255};
$string = "\x03\xff\xff";  # <-- uses the default construct
is_deeply( $s->parse($string), $data, "Switch with default: Parse: correct3");
ok( $s->build($data) eq "\x03\xff", "Switch with default: Build: correct3");

$s = Struct("foo",
    Byte("type"),
    Switch("data", sub { $_->ctx->{type} },
        {
            1 => UBInt8("spam"),
            2 => UBInt16("spam"),
        },
        default => $DefaultPass,
    )
);
$data = {type => 1, data => 255};
$string = "\x01\xff";
is_deeply( $s->parse($string), $data, "Switch with pass: Parse: correct1");
ok( $s->build($data) eq $string, "Switch with pass: Build: correct1");
$data = {type => 2, data => 65535};
$string = "\x02\xff\xff";
is_deeply( $s->parse($string), $data, "Switch with pass: Parse: correct2");
ok( $s->build($data) eq $string, "Switch with pass: Build: correct2");
$data = {type => 3, data => undef};
$string = "\x03\xff\xff";  # <-- uses the default construct
is_deeply( $s->parse($string), $data, "Switch with pass: Parse: correct3");
ok( $s->build($data) eq "\x03", "Switch with pass: Build: correct3");

$s = Struct("foo",
    Pointer(sub { 4 }, Byte("data1")),   # <-- data1 is at (absolute) position 4
    Pointer(sub { 7 }, Byte("data2")),   # <-- data2 is at (absolute) position 7
);
$data = {data1 => 1, data2=> 2};
$string = "\x00\x00\x00\x00\x01\x00\x00\x02";
is_deeply( $s->parse($string), $data, "Pointer: Parse: correct");
ok( $s->build($data) eq $string, "Pointer: Build: Empty");

$s = Struct("foo",
    Byte("padding_length"),
    Padding(sub { $_->ctx->{padding_length} } ),
    Byte("relative_offset"),
    Anchor("absolute_position"),
    Pointer(sub { $_->ctx->{absolute_position} + $_->ctx->{relative_offset} }, Byte("data")),
);
$data = {relative_offset=>3, absolute_position=>7, data=>255, padding_length=>5};
$string = "\x05\x00\x00\x00\x00\x00\x03\x00\x00\x00\xff";
is_deeply( $s->parse($string), $data, "Pointer n Anchor: Parse: Correct");
ok(( $s->build($data) eq $string ), "Pointer n Anchor: Build: Correct");

$s = Struct("foo",
    Byte("padding_length"),
    Padding(sub { $_->ctx->{padding_length} } ),
    Byte("relative_offset"),
    Pointer(sub { $_->stream->tell + $_->ctx->{relative_offset} }, Byte("data")),
);
$data = {relative_offset=>3, data=>255, padding_length=>5};
$string = "\x05\x00\x00\x00\x00\x00\x03\x00\x00\x00\xff";
is_deeply( $s->parse($string), $data, "Pointer n Anchor: Parse: Correct");
ok(( $s->build($data) eq $string ), "Pointer n Anchor: Build: Correct");

ok(( String("foo", 5)->parse("hello") eq "hello"), "String: Parse: Simple");

$s = String("foo", 10, padchar => "X", paddir => "right");
ok(( $s->parse("helloXXXXX") eq 'hello' ), "Padded String: Parse: Simple");
ok(( $s->build("hello") eq 'helloXXXXX' ), "Padded String: Build: Simple");

$s = PascalString("foo");
ok(( $s->parse("\x05hello") eq 'hello'), "PascalString: Parse: Simple");
ok(( $s->build("hello world") eq "\x0bhello world"), "PascalString: Build: Simple");
$s = PascalString("foo", \&UBInt16);
ok(( $s->parse("\x00\x05hello") eq 'hello'), "PascalString: Parse: With cutsom length type");
ok(( $s->build("hello") eq "\x00\x05hello"), "PascalString: Build: With cutsom length type");

$s = CString("foo");
ok(( $s->parse("hello\x00") eq 'hello' ), "CString: Parse: Simple");
ok(( $s->build("hello") eq "hello\x00" ), "CString: Build: Simple");
$s = CString("foo", terminators => "XYZ");
ok(( $s->parse("helloX") eq 'hello' ), "CString: Parse: custom terminator1");
ok(( $s->parse("helloY") eq 'hello' ), "CString: Parse: custom terminator2");
ok(( $s->parse("helloZ") eq 'hello' ), "CString: Parse: custom terminator3");
ok(( $s->build("hello") eq "helloX" ), "CString: Build: custom terminator");


$s = Struct("foo",
    UBInt8("width"),
    UBInt8("height"),
    Value("total_pixels", sub { $_->ctx->{width} * $_->ctx->{height}}),
);
is_deeply( $s->parse("\x05\x05"), { width => 5, height => 5, total_pixels => 25 }, "Value: Parse: Simple");
$data = { width => 5, height => 5 };
ok(( $s->build($data) eq "\x05\x05"), "Value: Parse: Ignored");
is_deeply( $data, { width => 5, height => 5, total_pixels => 25 }, "Value: Parse: Added to hash");

$s = Struct("foo",
    Flag("has_options"),
    If(sub { $_->ctx->{has_options} },
        Bytes("options", 5)
    )
);
is_deeply( $s->parse("\x01hello"), {options => 'hello', has_options => 1 }, "If: Parse: True");
is_deeply( $s->parse("\x00hello"), {options => undef, has_options => 0 }, "If: Parse: False");
ok(( $s->build({options => undef, has_options => 0 }) eq "\0"), "If: Build: False");
ok(( $s->build({options => 'hello', has_options => 1 }) eq "\x01hello"), "If: Build: True");

$s = Struct("foo",
    Flag("long_options"),
    IfThenElse("options", sub { $_->ctx->{long_options} },
        Bytes("Long Options", 5),
        Bytes("Short Options", 3),
    ),
);
is_deeply( $s->parse("\x01hello"), {options => 'hello', long_options => 1 }, "IfThenElse: Parse: True");
is_deeply( $s->parse("\x00hello"), {options => 'hel', long_options => 0 }, "IfThenElse: Parse: False");
ok(( $s->build({options => 'hel', long_options => 0 }) eq "\0hel"), "IfThenElse: Build: False");
ok(( $s->build({options => 'hello', long_options => 1 }) eq "\x01hello"), "IfThenElse: Build: True");

$s = Struct("foo",
    Flag("has_next"),
    If(sub { $_->ctx->{has_next} }, LazyBound("next", sub { $s })),
);
$data = { has_next => 1, next => { has_next => 1, next => { has_next => 1, next => { has_next => 0, next => undef } } } };
$string = "\x01\x01\x01\x00";
is_deeply( $s->parse($string), $data, "LazyBound: Parse: Correct");
ok(( $s->build($data) eq $string), "LazyBound: Build: Correct");

$s = Struct("foo",
    Byte("a"),
    Peek(Byte("b")),
    Byte("c"),
);
is_deeply( $s->parse("\x01\x02"), {a=>1, b=>2, c=>2}, "Peek: Parse: Simple");
ok(( $s->build({a=>1, b=>222, c=>2}) eq "\x01\x02"), "Peek: Build: Ignored");

$s = Struct("foo",
    Byte("a"),
    Peek(Byte("b"), 3),
    UBInt16("c"),
    Byte("d"),
    Byte("e"),
);
$string = "\x01\xaa\xbb\x03\x04";
$data = {a=>1, c=>43707, d=>3, e=>4};
is_deeply( $s->parse($string), {%$data, b=>4}, "Far Peek: Parse: Simple");
ok(( $s->build($data) eq $string), "Far Peek: Build: Ignored");

$s = Const(Bytes("magic", 6), "FOOBAR");
ok(($s->parse("FOOBAR") eq "FOOBAR"), "Const: Parse: OK");
eval { $s->parse("FOOBAX") };
ok( $@, "Const: Parse: Dies");
ok(( $s->build("FOOBAR") eq "FOOBAR"), "Const: Build: OK");
eval { $s->build("FOOBAX") };
ok( $@, "Const: Build: Dies");

$s = Terminator();
ok(( not defined $s->parse("")), "Terminator: Parse: ok");
eval { $s->parse("x") };
ok( $@, "Terminator: Parse: dies");
ok(( $s->build({}) eq ""), "Terminator: Build: Empty");

$s = Struct("foo",
    Byte("a"),
    Alias("b", "a"),
);
is_deeply( $s->parse("\x03"), {a=>3, b=>3}, "Alias: Parse: Simple");
$data = {a=>3};
ok(( $s->build($data) eq "\x03"), "Alias: Build: OK");
is_deeply($data, {a=>3, b=>3}, "Alias: Build: Add value");
$data = {a=>3, b=>5};
ok(( $s->build($data) eq "\x03"), "Alias: Build: Ignore b");

$s = Union("foo",
    UBInt32("a"),
    UBInt16("b")
);
is_deeply( $s->parse("\xaa\xbb\xcc\xdd"), { a => 2864434397, b => 43707 }, "Union: Parse: Simple");
ok(( $s->build( { a=> 2864434397 } ) eq "\xaa\xbb\xcc\xdd" ), "Union: Build: a");
ok(( $s->build( { b => 43707 } ) eq "\xaa\xbb\0\0" ), "Union: Build: b");

$s = Struct("foo", Aligned(Byte("bbb"), 8), Byte("aaa"));
$data = { bbb => 99, aaa=>5 };
$string = "c\0\0\0\0\0\0\0\5";
is_deeply( $s->parse($string), $data, "Aligned: Parse: Correct");
ok(( $s->build($data) eq $string), "Aligned: Build: Correct");

$s = Bitwise(Struct("foo",
    Padding(2),
    Flag("myflag"),
    Padding(5),
));
$data = {myflag => 1};
$string = "\x20";
is_deeply($s->parse($string), $data, "Bitwise eq BitStruct: Parse: correct");
ok( $s->build($data) eq $string, "Bitwise eq BitStruct: Build: correct");

$s = Struct("foo1",
    Byte("a"),
    Select(
           Const(Byte("b1"), 4),
           Const(Byte("b2"), 2),
          ),
    Byte("c"),
);
$s1 = Struct("foo1",
    Byte("a"),
    Select(
           Const(Byte("b1"), 4),
           Const(Byte("b2"), 2),
           $DefaultPass,
          ),
    Byte("c"),
);
$string = "\3\4\xb0";
$data = { a=>3, b1=>4, c=>176};
is_deeply($s->parse($string), $data, "Select: Parse: OK1");
ok( $s->build($data) eq $string, "Select: Build: OK1");
is_deeply($s1->parse($string), $data, "Select with Pass: Parse: OK1");
ok( $s1->build($data) eq $string, "Select with Pass: Build: OK1");
$string = "\3\2\xb0";
$data = { a=>3, b2=>2, c=>176};
is_deeply($s->parse($string), $data, "Select: Parse: OK2");
ok( $s->build($data) eq $string, "Select: Build: OK2");
is_deeply($s1->parse($string), $data, "Select with Pass: Parse: OK2");
ok( $s1->build($data) eq $string, "Select with Pass: Build: OK2");
$string = "\3\3\xb0";
$data = { a=>3, b2=>3, c=>176};
eval { $s->parse($string) };
ok( $@, "Select: Parse: Failed");
eval { $s->build($data) };
ok( $@, "Select: Build: Failed");
$data = { a=>3, c=>3};
is_deeply($s1->parse($string), $data, "Select with Pass: Parse: Pass");
ok( $s1->build($data) eq "\3\3", "Select with Pass: Build: Pass");

$s = FlagsEnum(ULInt16("characteristics"),
    RELOCS_STRIPPED => 0x0001,
    EXECUTABLE_IMAGE => 0x0002,
    LINE_NUMS_STRIPPED => 0x0004,
    LOCAL_SYMS_STRIPPED => 0x0008,
    AGGRESSIVE_WS_TRIM => 0x0010,
    LARGE_ADDRESS_AWARE => 0x0020,
    MACHINE_16BIT => 0x0040,
    BYTES_REVERSED_LO => 0x0080,
    MACHINE_32BIT => 0x0100,
    DEBUG_STRIPPED => 0x0200,
    REMOVABLE_RUN_FROM_SWAP => 0x0400,
    SYSTEM => 0x1000,
    DLL => 0x2000,
    UNIPROCESSOR_ONLY => 0x4000,
    BIG_ENDIAN_MACHINE => 0x8000,
);
$data = {};
$string = "\0\0";
is_deeply($s->parse($string), $data, "FlagsEnum: Parse: Empty");
ok( $s->build($data) eq $string, "FlagsEnum: Build: Empty");
$data = {EXECUTABLE_IMAGE => 1, REMOVABLE_RUN_FROM_SWAP=>1};
$string = "\2\4";
is_deeply($s->parse($string), $data, "FlagsEnum: Parse: Pass");
ok( $s->build($data) eq $string, "FlagsEnum: Build: Pass");

$string = "PNG";
$s = Magic($string);
ok( $s->build({ }) eq $string, "Magic: Build: Pass");
eval { $s->parse($string) };
ok( (not $@), "Magic: Parse: OK");
eval { $s->parse("PXNG") };
ok( $@, "Magic: Parse: Dies");

$s = ReversedBitStruct("foo",
    BitField("a", 3),
    Flag("b"),
    Byte("c"),
);
$data = { a=>7, b=>0, c=>236 };
$string = pack "B*", "0111011100000011";
is_deeply($s->parse($string), $data, "ReversedBitStruct: Parse: correct");
ok( $s->build($data) eq $string, "ReversedBitStruct: Build: correct");

$s = ReversedBitStruct("foo",
    BitField("a", 3),
    Flag("b"),
    ReversedBitField("c", 8),
);
$data = { a=>7, b=>0, c=>236 };
$string = pack "B*", "1100011100001110";
is_deeply($s->parse($string), $data, "ReversedBitStruct with ReversedBitField: Parse: correct");
ok( $s->build($data) eq $string, "ReversedBitStruct with ReversedBitField: Build: correct");



#print Dumper($data);

done_testing();