package Data::ParseBinary;
use strict;
use warnings;
no warnings 'once';

our $VERSION = 0.31;

use Data::ParseBinary::Core;
use Data::ParseBinary::Adapters;
use Data::ParseBinary::Streams;
use Data::ParseBinary::Stream::String;
use Data::ParseBinary::Stream::Wrapper;
use Data::ParseBinary::Stream::Bit;
use Data::ParseBinary::Stream::StringBuffer;
use Data::ParseBinary::Stream::File;
use Data::ParseBinary::Constructs;
use Config;

our $DefaultPass = Data::ParseBinary::NullConstruct->create();
$Data::ParseBinary::BaseConstruct::DefaultPass = $DefaultPass;
our $print_debug_info = undef;

my $support_64_bit_int;
eval { my $x = pack "Q", 5 };
if ( $@ ) {
    $support_64_bit_int = 0;
    require Math::BigInt;
} else {
	$support_64_bit_int = 1
}
$@ = '';

sub UBInt16 { return Data::ParseBinary::Primitive->create($_[0], 2, "n") }
sub UBInt32 { return Data::ParseBinary::Primitive->create($_[0], 4, "N") }
sub ULInt16 { return Data::ParseBinary::Primitive->create($_[0], 2, "v") }
sub ULInt32 { return Data::ParseBinary::Primitive->create($_[0], 4, "V") }
sub UNInt32 { return Data::ParseBinary::Primitive->create($_[0], 4, "L") }
sub UNInt16 { return Data::ParseBinary::Primitive->create($_[0], 2, "S") }
sub UNInt8  { return Data::ParseBinary::Primitive->create($_[0], 1, "C") }
sub SNInt32 { return Data::ParseBinary::Primitive->create($_[0], 4, "l") }
sub SNInt16 { return Data::ParseBinary::Primitive->create($_[0], 2, "s") }
sub SNInt8  { return Data::ParseBinary::Primitive->create($_[0], 1, "c") }
sub NFloat32{ return Data::ParseBinary::Primitive->create($_[0], 4, "f") }
sub NFloat64{ return Data::ParseBinary::Primitive->create($_[0], 8, "d") };
*SBInt8 = \&SNInt8;
*SLInt8 = \&SNInt8;
*Byte = \&UNInt8;
*UBInt8 = \&UNInt8;
*ULInt8 = \&UNInt8;

my $create_64_classes = sub {
    my ($name, $is_signed, $is_be) = @_;
    return Data::ParseBinary::ExtendedNumberAdapter->create(Field($name, 8), $is_signed, $is_be);
};

if ($support_64_bit_int) {
    *UNInt64 = sub { return Data::ParseBinary::Primitive->create($_[0], 8, "Q") };
    *SNInt64 = sub { return Data::ParseBinary::Primitive->create($_[0], 8, "q") };
}

if ($^V ge v5.10.0) {
    *SBInt16 = sub { return Data::ParseBinary::Primitive->create($_[0], 2, "s>") };
    *SLInt16 = sub { return Data::ParseBinary::Primitive->create($_[0], 2, "s<") };
    *SBInt32 = sub { return Data::ParseBinary::Primitive->create($_[0], 4, "l>") };
    *SLInt32 = sub { return Data::ParseBinary::Primitive->create($_[0], 4, "l<") };
    *BFloat32= sub { return Data::ParseBinary::Primitive->create($_[0], 4, "f>") };
    *LFloat32= sub { return Data::ParseBinary::Primitive->create($_[0], 4, "f<") };
    if ($support_64_bit_int) {
        *SBInt64 = sub { return Data::ParseBinary::Primitive->create($_[0], 8, "q>") };
        *SLInt64 = sub { return Data::ParseBinary::Primitive->create($_[0], 8, "q<") };
        *UBInt64 = sub { return Data::ParseBinary::Primitive->create($_[0], 8, "Q>") };
        *ULInt64 = sub { return Data::ParseBinary::Primitive->create($_[0], 8, "Q<") };
    } else {
        *SBInt64 = sub { $create_64_classes->($_[0], 1, 1) };
        *SLInt64 = sub { $create_64_classes->($_[0], 1, 0) };
        *UBInt64 = sub { $create_64_classes->($_[0], 0, 1) };
        *ULInt64 = sub { $create_64_classes->($_[0], 0, 0) };
    }
    *BFloat64= sub { return Data::ParseBinary::Primitive->create($_[0], 8, "d>") };
    *LFloat64= sub { return Data::ParseBinary::Primitive->create($_[0], 8, "d<") };
} else {
    my ($primitive_class, $reversed_class);
    if (pack('s', -31337) eq "\x85\x97") {
        $primitive_class = 'Data::ParseBinary::Primitive';
        $reversed_class  = 'Data::ParseBinary::ReveresedPrimitive';
    } else {
        $reversed_class  = 'Data::ParseBinary::Primitive';
        $primitive_class = 'Data::ParseBinary::ReveresedPrimitive';
    }
    *SBInt16 = sub { return $primitive_class->create($_[0], 2, "s") };
    *SLInt16 = sub { return $reversed_class->create($_[0], 2, "s") };
    *SBInt32 = sub { return $primitive_class->create($_[0], 4, "l") };
    *SLInt32 = sub { return $reversed_class->create($_[0], 4, "l") };
    *BFloat32= sub { return $primitive_class->create($_[0], 4, "f") };
    *LFloat32= sub { return $reversed_class->create($_[0], 4, "f") };
    if ($support_64_bit_int) {
        *SBInt64 = sub { return $primitive_class->create($_[0], 8, "q") };
        *SLInt64 = sub { return $reversed_class->create($_[0], 8, "q") };
        *UBInt64 = sub { return $primitive_class->create($_[0], 8, "Q") };
        *ULInt64 = sub { return $reversed_class->create($_[0], 8, "Q") };
    } else {
        *SBInt64 = sub { $create_64_classes->($_[0], 1, 1) };
        *SLInt64 = sub { $create_64_classes->($_[0], 1, 0) };
        *UBInt64 = sub { $create_64_classes->($_[0], 0, 1) };
        *ULInt64 = sub { $create_64_classes->($_[0], 0, 0) };
    }
    *BFloat64= sub { return $primitive_class->create($_[0], 8, "d") };
    *LFloat64= sub { return $reversed_class->create($_[0], 8, "d") };
}

sub Struct  { return Data::ParseBinary::Struct->create(@_) }
sub Sequence{ return Data::ParseBinary::Sequence->create(@_) };
sub Array {
    my ($count, $sub) = @_;
    if ($count and ref($count) and UNIVERSAL::isa($count, "CODE")) {
        return Data::ParseBinary::MetaArray->create($count, $sub);
    } else {
        return Data::ParseBinary::MetaArray->create(sub {$count}, $sub);
    }
}

sub GreedyRange { return Data::ParseBinary::Range->create(1, undef, $_[0]); }
sub OptionalGreedyRange { return Data::ParseBinary::Range->create(0, undef, $_[0]); }
sub Range { return Data::ParseBinary::Range->create(@_) };
sub Padding   { return Data::ParseBinary::Padding->create($_[0]) }
sub Flag      { return Data::ParseBinary::BitField->create($_[0], 1) }
sub Bit       { return Data::ParseBinary::BitField->create($_[0], 1) }
sub Nibble    { return Data::ParseBinary::BitField->create($_[0], 4) }
sub Octet     { return Data::ParseBinary::BitField->create($_[0], 8) }
sub BitField  { return Data::ParseBinary::BitField->create(@_) }
sub ReversedBitField { return Data::ParseBinary::ReversedBitField->create(@_) }

sub ConditionalRestream { return Data::ParseBinary::ConditionalRestream->create(@_) }
sub BitStruct {
    my ($name, @subcons) = @_;
    my $subcon = Struct($name, @subcons);
    return ConditionalRestream($subcon, "Bit", sub { not $_->stream->isBitStream() });
}
sub ReversedBitStruct {
    my ($name, @subcons) = @_;
    my $subcon = Struct($name, @subcons);
    return ConditionalRestream($subcon, "ReversedBit", sub { not $_->stream->isBitStream() });
}
sub Enum      { return Data::ParseBinary::Enum->create(@_) }
sub OneOf {
    my ($subcon, $list) = @_;
    my $code = sub {
        return grep $_ == $_[0], @$list;
    };
    return Data::ParseBinary::LamdaValidator->create($subcon, $code);
}
sub NoneOf {
    my ($subcon, $list) = @_;
    my $code = sub {
        my @res = grep $_ == $_[0], @$list;
        return @res == 0;
    };
    return Data::ParseBinary::LamdaValidator->create($subcon, $code);
}
sub Field {
    my ($name, $len) = @_;
    if ($len and ref($len) and UNIVERSAL::isa($len, "CODE")) {
        return Data::ParseBinary::MetaField->create($name, $len);
    } else {
        return Data::ParseBinary::StaticField->create($name, $len);
    }
}
*Bytes = \&Field;
sub RepeatUntil (&$) { return Data::ParseBinary::RepeatUntil->create(@_) }

sub Char {
    my ($name, $encoding) = @_;
    
    # if we don't have encoding - a char is simply one byte
    return Field($name, 1) unless $encoding;
    
    if ( ( $encoding eq "UTF-32LE" ) or ( $encoding eq "UTF-32BE" ) ) {
        my $subcon = Field($name, 4);
        return Data::ParseBinary::CharacterEncodingAdapter->create($subcon, $encoding);
    } elsif ( ( $encoding eq "UTF-16LE" ) or ( $encoding eq "UTF-16BE" ) ) {
        my $place = $encoding eq "UTF-16LE" ? 1 : 0;
        my $subcon = Struct($name,
                            Field("FirstUnit", 2),
                            Array( sub { my $ch = substr($_->ctx->{FirstUnit}, $place, 1); return ( ( ($ch ge "\xD8" ) and ($ch le "\xDB") ) ? 1 : 0 ) },
                                  Field("TheRest", 2)
                                  )
                            );
        my $assambled = Data::ParseBinary::FirstUnitAndTheRestAdapter->create($subcon, 2);
        return Data::ParseBinary::CharacterEncodingAdapter->create($assambled, $encoding);
    } elsif ( ( $encoding eq "utf8" ) or ( $encoding eq "UTF-8" ) ) {
        my $subcon = Struct($name,
                            Field("FirstUnit", 1),
                            Array( sub { my $ch = $_->ctx->{FirstUnit}; return scalar(grep { $ch ge $_ } "\xC0", "\xE0", "\xF0" ) || 0 },
                                  Field("TheRest", 1)
                                  )
                            );
        my $assambled = Data::ParseBinary::FirstUnitAndTheRestAdapter->create($subcon, 1);
        return Data::ParseBinary::CharacterEncodingAdapter->create($assambled, $encoding);
    } elsif ( $encoding =~ /^(?:utf|ucs)/i ) {
        die "Unrecognized UTF format: $encoding";
    } else {
        # this is a single-byte encoding
        return Data::ParseBinary::CharacterEncodingAdapter->create(Field($name, 1), $encoding);
    }
}

sub PaddedString {
    my ($name, $length, %params) = @_;
    my $subcon = Data::ParseBinary::PaddedStringAdapter->create(Field($name, $length), length => $length, %params);
    return $subcon unless $params{encoding};
    return Data::ParseBinary::CharacterEncodingAdapter->create($subcon, $params{encoding});
};
sub String {
    my ($name, $length, %params) = @_;
    if (defined $params{padchar}) {
        #this is a padded string
        return PaddedString($name, $length, %params);
    }
    return Data::ParseBinary::JoinAdapter->create(
        Array($length, Char($name, $params{encoding})),
    );
}
sub LengthValueAdapter { return Data::ParseBinary::LengthValueAdapter->create(@_) }
sub PascalString {
    my ($name, $length_field_type, $encoding) = @_;
    $length_field_type ||= \&UBInt8;
    my $length_field;
    {
        no strict 'refs';
        $length_field = &$length_field_type('length');
    }
    if (not $encoding) {
        return LengthValueAdapter(
            Sequence($name,
                $length_field,
                Field("data", sub { $_->ctx->[0] }),
            )
        );
    } else {
        return LengthValueAdapter(
            Sequence($name,
                $length_field,
                Data::ParseBinary::JoinAdapter->create(
                    Array(sub { $_->ctx->[0] }, Char("data", $encoding)),
                ),
            )
        );
    }
}

sub CString {
    my ($name, %params) = @_;
    my ($terminators, $encoding, $char_field) = @params{qw{terminators encoding char_field}}; 
    $terminators = "\x00" unless defined $terminators;
    $char_field ||= Char($name, $encoding);
    my @t_list = split '', $terminators;
    return Data::ParseBinary::CStringAdapter->create(
        Data::ParseBinary::JoinAdapter->create(
            RepeatUntil(sub { my $obj = $_->obj; grep($obj eq $_, @t_list) } ,$char_field)),
            $terminators
        );
}


sub Switch { return Data::ParseBinary::Switch->create(@_) }
sub Pointer { return Data::ParseBinary::Pointer->create(@_) }
sub LazyBound { return Data::ParseBinary::LazyBound->create(@_) }
sub Value { return Data::ParseBinary::Value->create(@_) }
sub Anchor { my $name = shift; return Value($name, sub { $_->stream->tell } ) }
sub Terminator { return Data::ParseBinary::Terminator->create() }

sub IfThenElse {
    my ($name, $predicate, $then_subcon, $else_subcon) = @_;
    return Switch($name, sub { &$predicate ? 1 : 0 },
        {
            1 => $then_subcon,
            0 => $else_subcon,
        }
    )
}

sub If {
    my ($predicate, $subcon, $elsevalue) = @_;
    return IfThenElse($subcon->_get_name(), 
        $predicate, 
        $subcon, 
        Value("elsevalue", sub { $elsevalue })
    )
}
sub Peek { Data::ParseBinary::Peek->create(@_) }
sub Const { Data::ParseBinary::ConstAdapter->create(@_) }
sub Alias {
    my ($newname, $oldname) = @_;
    return Value($newname, sub { $_->ctx->{$oldname}});
}

sub Union { Data::ParseBinary::Union->create(@_) }
sub RoughUnion { Data::ParseBinary::RoughUnion->create(@_) }

*CreateStreamReader = \&Data::ParseBinary::Stream::Reader::CreateStreamReader;
*CreateStreamWriter = \&Data::ParseBinary::Stream::Writer::CreateStreamWriter;
sub ExtractingAdapter { Data::ParseBinary::ExtractingAdapter->create(@_) };

sub Aligned {
    my ($subcon, $modulus) = @_;
    $modulus ||= 4;
    die "Aligned should be more then 2" if $modulus < 2;
    my $sub_name = $subcon->_get_name();
    my $s = ExtractingAdapter(
        Struct($sub_name,
               Anchor("Aligned_before"),
               $subcon,
               Anchor("Aligned_after"),
               Padding(sub { ($modulus - (($_->ctx->{Aligned_after} - $_->ctx->{Aligned_before}) % $modulus)) % $modulus })
              ),
        $sub_name);
    return $s;
}

sub Restream {
    my ($subcon, $stream_name) = @_;
    return Data::ParseBinary::Restream->create($subcon, $stream_name);
}
sub Bitwise {
    my ($subcon) = @_;
    return Restream($subcon, "Bit");
}

sub Magic {
    my ($data) = @_;
    return Const(Field(undef, length($data)), $data);
}

sub Select { Data::ParseBinary::Select->create(@_) }

sub Optional {
    my $subcon = shift;
    return Select($subcon, $DefaultPass);
}

sub FlagsEnum { Data::ParseBinary::FlagsEnum->create(@_) }

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    UBInt8
    ULInt8
    SBInt8
    SLInt8
    Byte
    UBInt16
    ULInt16
    SBInt16
    SLInt16
    UBInt32
    ULInt32
    SBInt32
    SLInt32
    BFloat32
    LFloat32
    UBInt64
    ULInt64
    SBInt64
    SLInt64
    BFloat64
    LFloat64

    Struct
    Sequence

    Padding

    Flag
    Bit
    Nibble
    Octet
    BitField
    BitStruct
    ReversedBitField
    ReversedBitStruct

    Enum
    $DefaultPass
    OneOf
    NoneOf
    Array
    RepeatUntil
    Field
    Bytes
    Switch
    Pointer
    Anchor

    Char
    String
    PascalString
    CString
    PaddedString

    LazyBound
    Value
    IfThenElse
    If
    Peek
    Const
    Terminator
    Alias
    Union
    RoughUnion
    
    CreateStreamReader
    CreateStreamWriter
    
    Aligned
    ExtractingAdapter
    Restream
    Bitwise
    Magic
    
    Select
    FlagsEnum
);

our @Neturals_depricated = qw{
    UNInt8
    SNInt8
    UNInt16
    SNInt16
    UNInt32
    SNInt32
    UNInt64
    SNInt64
    NFloat32
    NFloat64
};
our @EXPORT_OK = (@Neturals_depricated, qw{
    Range
    GreedyRange
    OptionalGreedyRange
    Optional
});
our %EXPORT_TAGS = ( NATURALS => \ @Neturals_depricated, all => [ @EXPORT_OK, @EXPORT ]);

1;

__END__

=head1 NAME

Data::ParseBinary - Yet Another parser for binary structures

=head1 SYNOPSIS

    $s =
    Struct("Construct",
        Struct("Header",
            Magic("MZ"),
            Byte("Version"),
            UBInt32("Expire Date"),
            Enum(UBInt32("Data Type"),
                Array => 0,
                String => 1,
                Various => 2,
            ),
            Byte("Have Extended Header"),
            If ( sub { $_->ctx->{"Have Extended Header"} },
                CString("Author")
            ),
        ),
        Switch("data", sub { $_->ctx->{Header}->{"Data Type"} },
            {
                Array => Array(4, SBInt32("Signed Int 32")),
                String => PascalString("Name"),
                Various =>
                    Struct("Various data",
                        NoneOf(Byte("value"), [4, 9]),
                        Padding(1), # byte
                        BitStruct("Mini Values",
                            Flag("done"),
                            Nibble("Short"),
                            Padding(1), #bit
                            SBInt16("something"),
                        ),
                    ),
            }
        ),
    );
    my $data = $s->parse("MZabcde\0\0\0\1\1semuel\0\x05fghij");
    # $data contains:
    #    {
    #        'Header' =>
    #        {
    #            'Version' => 97,
    #            'Expire Date' => 1650680933
    #            'Data Type' => 'String',
    #            'Have Extended Header' => 1,
    #            'Author' => 'semuel',
    #        }
    #        'data' => 'fghij',
    #    }

=head1 DESCRIPTION

This module is a Perl Port for PyConstructs http://construct.wikispaces.com/

This module enables writing declarations for simple and complex binary structures,
parsing binary to hash/array data structure, and building binary data from hash/array
data structure.

=head1 Reference Code

=head2 Struct

    $s = Struct("foo",
        UBInt8("a"),
        UBInt16("b"),
        Struct("bar",
            UBInt8("a"),
            UBInt16("b"),
        )
    );
    $data = $s->parse("ABBabb");
    # $data is { a => 65, b => 16962, bar => { a => 97, b => 25186 } }

This is the main building block of the module - the struct. Whenever there is the
need to bind a few varibles together, use Struct. Many constructs receive only one
sub-construct as parameter, (for example, all the conditional constructs) so use
Struct.

=head2 Primitives

=head3 Byte-Primitives

But this Struct is just an empy shell. we need to fill it with data types.
So here is a list of primitive elements:

    Byte, UBInt8, ULInt8 (All three are aliases to the same things)
    SBInt8, SLInt8
    UBInt16
    ULInt16
    SBInt16
    SLInt16
    UBInt32
    ULInt32
    SBInt32
    SLInt32
    BFloat32
    LFloat32
    UBInt64
    ULInt64
    SBInt64
    SLInt64
    BFloat64
    LFloat64

S - Signed, U - Unsigned, L - Little endian, B - Big Endian
Samples:

    UBInt16("foo")->parse("\x01\x02") == 258
    ULInt16("foo")->parse("\x01\x02") == 513
    UBInt16("foo")->build(31337) eq 'zi'
    SBInt16("foo")->build(-31337) eq "\x85\x97"
    SLInt16("foo")->build(-31337) eq "\x97\x85"

And of course, see Struct above to how bundle a few primitives together.

Be aware that the Float data type is not portable between platforms. So
it is advisable not to use it when there is an alternative.

=head3 Bit-Primitives
    
    Flag, Bit (1 bit)
    Nibble (4 bits)
    Octet (8 bits, equal to "Byte")
    BitField (variable length)

These primitive are bit-wide. however, unless using BitStruct, they take a whole
byte from the input stream. Take for example this struct:

    $s = Struct("bits",
        Flag("a"),
        Nibble("b"),
    );
    $data = $s->parse("\x25\x27");
    # data is { a => 1, b => 7 }

"\x25\x27" is 0010010100100111 in binary. The Flag is first, and it takes one byte
from the stream (00100101) use the last bit (1) and discard the rest. After it comes
the Mibble, that takes a byte too, (00100111) use the last four bits (0111) and discard
the rest.

If you need these bits to be packed tight together, see BitStruct.

Examples for the rest of the bit constructs:

    $s = Struct("bits",
        Octet("a"),
        BitField("b", 5),
    );
    $data = $s->parse("\x25\x27");
    # data is { a => 37, b => 7 }

=head2 Meta-Constructs

Life isn't always simple. If you only have a rigid structure with constance types,
then you can use other modules, that are far simplier. hack, use pack/unpack.

So if you have more complicate requirements, welcome to the meta-constructs.
Basically, you pass a code ref to the meta-construct, which will be used while
parsing and building.

For every data that the code ref needs, the $_ variable is loaded with all the
data that you need. $_->ctx is equal to $_->ctx(0), that returns hash-ref
containing all the data that the current struct parsed. Is you want to go another
level up, just request $_->ctx(1).

Also avialble are $_->obj, when need to inspect the current object, (see RepeatUntil)
and $_->stream, which gives the current stream. (mostly used as $_->stream->tell to
get the current location)

As a rule, everywhere a code-ref is used, a simple number can be used too.
If it doesn't - it's a bug. please report it.

=head2 Meta-Primitives

=head3 Field (Bytes)

The first on is the field. a Field is a chunk of bytes, with variable length:

    $s = Struct("foo",
        Byte("length"),
        Field("data", sub { $_->ctx->{length} }),
    );

(it can be also in constent length, by replacing the code section with, for example, 4)
So we have struct, that the first byte is the length of the field, and after that the field itself.
An example:

    $data = $s->parse("\x03ABC");
    # $data is {length => 3, data => "ABC"} 
    $data = $s->parse("\x04ABCD");
    # $data is {length => 4, data => "ABCD"} 

And so on.

Field is also called Bytes.

=head3 Value

A calculated value - not in the stream. It is calculated on both parse and build.

    $s = Struct("foo",
        UBInt8("width"),
        UBInt8("height"),
        Value("total_pixels", sub { $_->ctx->{width} * $_->ctx->{height}}),
    );

=head3 Alias

Copies "a" to "b".

    $s = Struct("foo",
        Byte("a"),
        Alias("b", "a"),
    );
    $data = $s->parse("\x25");
    # $data is { a => 37, b => 37 }

=head2 Conditionals

=head3 If / IfThenElse

Basic branching:

    $s = Struct("foo",
        Flag("has_options"),
        If(sub { $_->ctx->{has_options} },
            Bytes("options", 5)
        )
    );

The If statment takes it's name from the contained construct, and return undef
of the condition is not met.

    $s = Struct("foo",
        Flag("long_options"),
        IfThenElse("options", sub { $_->ctx->{long_options} },
            Bytes("Long Options", 5),
            Bytes("Short Options", 3),
        ),
    );

The IfThenElse discard the name of the contained consturct, and use its own.

=head3 Switch

Multi branching. Can operate on numbers or strings. In the first example used with
Enum to convert a value to string.

The Switch discard the name of the contained consturcts, and use its own.
return undef if $DefaultPass is used.

    $s = Struct("foo",
        Enum(Byte("type"),
            INT1 => 1,
            INT2 => 2,
            INT4 => 3,
            STRING => 4,
        ),
        Switch("data", sub { $_->ctx->{type} },
            {
                INT1 => UBInt8("spam"),
                INT2 => UBInt16("spam"),
                INT4 => UBInt32("spam"),
                STRING => String("spam", 6),
            }
        )
    );
    $data = $s->parse("\x01\x12");
    # $data is {type => "INT1", data => 18}
    $data = $s->parse("\x02\x12\x34");
    # $data is {type => "INT2", data => 4660}
    $data = $s->parse("\x04abcdef");
    # $data is {type => "STRING", data => 'abcdef'}

And so on. Switch also have a default option:

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

And can use $DefaultPass that make it to no-op.

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
    $data = $s->parse("\x01\x27");
    # $data is { type => 1, data => 37 }

$DefaultPass is valid also as one of the options:

    $s = Struct("foo",
        Byte("type"),
        Switch("data", sub { $_->ctx->{type} },
            {
                1 => $DefaultPass,
                2 => UBInt16("spam"),
            },
            default => UBInt8("spam"),
        )
    );
    $data = $s->parse("\x01\x27");
    # $data is { type => 1, data => undef }
    
=head2 Loops

=head3 Array

Array, as any meta construct, and have constant length or variable lenght.

    # This is an Array of four bytes
    $s = Array(4, UBInt8("foo"));
    $data = $s->parse("\x01\x02\x03\x04");
    # $data is [1, 2, 3, 4]

    # Array with variable length
    $s = Struct("foo",
        Byte("length"),
        Array(sub { $_->ctx->{length}}, UBInt16("data")),
    );
    $data = $s->parse("\x03\x00\x01\x00\x02\x00\x03");
    # $data is {length => 3, data => [1, 2, 3]}

=head3 RepeatUntil

RepeatUntil gets for every round to inspect data on $_->obj:

    $s = RepeatUntil(sub {$_->obj eq "\x00"}, Field("data", 1));
    $data = $s->parse("abcdef\x00this is another string");
    # $data is [qw{a b c d e f}, "\0"]

=head2 Adapters

Adapters are constructs that transform the data that they work on. It wraps some underlining
structure, and present the data in a new, easier to use, way. There are some built-in
adapters for general use, but it is easy to write one of your own.

This is actually the easiest way to extend the framework.
For creating an adapter, the class should inherent from the Data::ParseBinary::Adapter
class. For example, we will take the IP address. An IP address can be viewed as
four bytes, or one unsigned long integer, but humans like to see it as dotted numbers.
("1.2.3.4") Here is how I would have done it. First, I'll write an adapter class:

    package IpAddressAdapter;
    our @ISA = qw{Data::ParseBinary::Adapter};
    sub _encode {
        my ($self, $tvalue) = @_;
        return [split '\.', $tvalue];
    }
    sub _decode {
        my ($self, $value) = @_;
        return join '.', @$value;
    }

This adapter transforms dotted IP address ("1.2.3.4") to four numbers. Each number size
is "byte", so we will use an array of four bytes. For actually creating one
we should write:

    my $ipAdapter = IpAddressAdapter->create(Array(4, Byte("foo")));

(An adapter inherits its name from the underlying data construct)

Or we can create a little function:

    sub IpAddressAdapterFunc {
        my $name = shift;
        IpAddressAdapter->create(Array(4, Byte($name)));
    }

And then:

    IpAddressAdapterFunc("foo")->parse("\x01\x02\x03\x04");
    # will return "1.2.3.4"

On additional note, it is possible to declare an "init" sub inside IpAddressAdapter,
that will receive any extra parameter that "create" recieved. 

=head3 Enum

One of the built-in Adapters is Enum:

    $s = Enum(Byte("protocol"),
        TCP => 6,
        UDP => 17,
    );
    $s->parse("\x06") # return 'TCP'
    $s->parse("\x11") # return 'UDP'
    $s->build("TCP") # returns "\x06"

It is also possible to have a default:

    $s = Enum(Byte("protocol"),
        TCP => 6,
        UDP => 17,
        _default_ => blah => 99,
    );
    $s->parse("\x12") # returns 'blah'

Please note that the default tag must not be one of the supplied pairs.
And finally:

    $s = Enum(Byte("protocol"),
        TCP => 6,
        UDP => 17,
        _default_ => $DefaultPass,
    );
    $s->parse("\x12") # returns 18

$DefaultPass tells Enum that if it isn't familiar with the value, pass it alone.

=head3 FlagsEnum

If the field represent a set of flags, then the library provide a construct just for that:

    $s = FlagsEnum(ULInt16("characteristics"),
        RELOCS_STRIPPED => 0x0001,
        EXECUTABLE_IMAGE => 0x0002,
        LINE_NUMS_STRIPPED => 0x0004,
        REMOVABLE_RUN_FROM_SWAP => 0x0400,
        BIG_ENDIAN_MACHINE => 0x8000,
    );
    $data = $s->parse("\2\4");
    # $data is { EXECUTABLE_IMAGE => 1, REMOVABLE_RUN_FROM_SWAP => 1 };

Of course, this is equvalent to creating a BitStruct, and specifing Flag-s in the
correct positions, and so on. but this is an easier way.

=head2 Validators

Validator... validate. they validate that the value on the stream is an expected
one, and they validate that the value that need to be written to the stream is
a correct one. otherwise, throws an exception.

=head3 OneOf / NoneOf

    OneOf(UBInt8("foo"), [4,5,6,7])->parse("\x05") # return 5
    OneOf(UBInt8("foo"), [4,5,6,7])->parse("\x08") # dies.
    NoneOf(UBInt8("foo"), [4,5,6,7])->parse("\x08") # returns 8
    NoneOf(UBInt8("foo"), [4,5,6,7])->parse("\x05") # dies

=head3 Const

    $s = Const(Bytes("magic", 6), "FOOBAR");

On parsing: verify that the correct value is being read, and return it.

On building: if value is supplied, verify that it is the correct one. if the
value is not supplied, insert the correct one.

=head3 Magic

    Magic("\x89PNG\r\n\x1a\n")

A constant string that is written / read and verified to / from the stream.
For example, every PNG file starts with eight pre-defined bytes. this construct
handle them, transparant to the calling program. (you don't need to supply a value,
nor you will see the parsed value)

=head2 BitStruct

As said in the section about Bit-Primitives, these primitives are not packed tightly,
and each will take complete bytes from the stream.
If you need to pack them tightly, use BitStruct:

    $s = BitStruct("foo",
        BitField("a", 3), # three bit int
        Flag("b"),  # one bit
        Nibble("c"),  # four bit int
        BitField("d", 5), # five bit int
    );
    $data = $s->parse("\xe1\xf2");
    # $data is { a => 7, b => 0, c => 1, d => 30 }

As can be seen, we start with 1110000111110010. The it is being splitted as
a=111, b=0, c=0001, d=11110 and the rest (010) is discard. 

BitStruct can be inside other BitStruct. Inside BitStruct, Struct and BitStruct are equivalents.

    $s = BitStruct("foo",
        BitField("a", 3),
        Flag("b"),
        Nibble("c"),
        Struct("bar",
            Nibble("d"),
            Bit("e"),
            Octet("f"),
        )
    );
    $data = $s->parse("\xe1\xf2\x34");
    # $data is { a => 7, b => 0, c => 1, bar => { d => 15, e => 0, f => 70 } }

It is possible to mix a byte-primitives inside a BitStruct:

    $s = BitStruct("foo",
        BitField("a", 3),
        UBInt16("int data"),
        Nibble("b"),
    );
    $data = $s->parse("\xe1\xf2\x34");
    # $data is { a => 7, "int data" => 3985, b => 10 }

Just be aware that this UBInt16 starts from the middle of the first byte, and
ends in the middle of the third.

BitStruct is based on a BitStream (see Stream) that is not seekable. So it can't
contain any construct that require seekability.

=head3 Bitwise

Use Bitwise when you are not under a BitStream, and you have single construct
that need to be packed by bits, and you don't want to create another hash for
just this construct. Here is an example from BMP:

    Bitwise(Array(sub { $_->ctx(2)->{width} }, Nibble("index")));

We have an array of Nibble, that need to be packed together. 

=head2 ReversedBitStruct and ReversedBitField

BitStruct assumes that each byte is arranged, bit-wise, from the most significante
bit (MSB) to the least significante bit. (LSB) However, it is not always true.

Lets say that you bytes are:

          MSB             LSB
    Byte 1: A B C D E F G H
    Byte 2: I J K M L N O P

And suppose that you have a bit-struct with three fields. AF1 is three bits,
AF2 is one bit, and AF3 is eight bits. so if:

    AF1=ABC, AF2=D, AF3=EFGHIJKM
    use: BitStruct with BitField
    AF1=CBA, AF2=D, AF3=MKJIHGFE
    use: BitStruct with ReversedBitField
    AF1=HGF, AF2=E, AF3=DCBAPONL
    use: ReversedBitStruct with BitField
    AF1=FGH, AF2=E, AF3=LNOPABCD
    use: ReversedBitStruct with ReversedBitField

=head2 Padding

Padding remove bytes from the stream

    $s = Struct("foo",
        Padding(2),
        Flag("myflag"),
        Padding(5),
    );
    $data = $s->parse("\x00\x00\x01\x00\x00\x00\x00\x00");
    # $data is { myflag => 1 } 

However, if woring on Bit Stream, then Padding takes bits and not bytes

    $s = BitStruct("foo",
        Padding(2),
        Flag("myflag"),
        Padding(5),
    );
    $data = $s->parse("\x20");
    # $data is { myflag => 1 } 

Padding is a meta-construct, can take code ref instead of a number

    $s = Struct("foo",
        Byte("count"),
        Padding( sub { $_->ctx->{count} } ),
        Flag("myflag"),
    );
    $data = $s->parse("\x02\0\0\1");
    # $data is { count => 2, muflag => 1 }

=head2 Peeking and Jumping

Not all parsing is linear. sometimes you need to peek ahead to see if a certain
value exists ahead, or maybe you know where the data is, it's just that it is
some arbitary number of bytes ahead. or before.

=head3 Pointer and Anchor

Pointers are another animal of meta-struct. For example:

    $s = Struct("foo",
        Pointer(sub { 4 }, Byte("data1")),   # <-- data1 is at (absolute) position 4
        Pointer(sub { 7 }, Byte("data2")),   # <-- data2 is at (absolute) position 7
    );
    $data = $s->parse("\x00\x00\x00\x00\x01\x00\x00\x02");
    # $data is {data1=> 1 data2=>2 }

Literaly is says: jump to position 4, read byte, return to the beginning, jump to position 7,
read byte, return to the beginning.

Anchor can help a Pointer to find it's target:

    $s = Struct("foo",
        Byte("padding_length"),
        Padding(sub { $_->ctx->{padding_length} } ),
        Byte("relative_offset"),
        Anchor("absolute_position"),
        Pointer(sub { $_->ctx->{absolute_position} + $_->ctx->{relative_offset} }, Byte("data")),
    );
    $data = $s->parse("\x05\x00\x00\x00\x00\x00\x03\x00\x00\x00\xff");
    # $data is { absolute_position=> 7, relative_offset => 3, data => 255, padding_length => 5 }

Anchor saves the current location in the stream, enable the Pointer to jump to location
relative to it.

Also, $_->stream->tell will point you to the current location, giving the ability for
relative location without using Anchor. The above construct is quevalent to:

    $s = Struct("foo",
        Byte("padding_length"),
        Padding(sub { $_->ctx->{padding_length} } ),
        Byte("relative_offset"),
        Pointer(sub { $_->stream->tell + $_->ctx->{relative_offset} }, Byte("data")),
    );

=head3 Peek
    
    $s = Struct("foo",
        Byte("a"),
        Peek(Byte("b")),
        Byte("c"),
    );

Peek is like Pointer with two differences: one that it is no-op on build.
second the location is calculated relative to the current location,
while with Pointer it's absolute position.

If no distance is supplied, zero is assumed. it is posible to supply
constant distance, (i.e. 5) or code ref. Examples:

    Peek(UBInt16("b"), 5) # Peek 5 bytes ahead
    Peek(UBInt16("b"), sub { $_->ctx->{this_far} }) # calculated number of bytes ahead    

=head2 Strings

=head3 Char

The Char construct represent a single character. This can mean one byte, or
if it have encoding attached, a multi-byte character.

    $s = Char("c", "utf8");
    $s->build("\x{1abcd}");
    # returns "\xf0\x9a\xaf\x8d"

The allowded encodings are:

    UTF-32LE
    UTF-32BE
    UTF-16LE
    UTF-16BE
    UTF-8
    utf8
    or any single-byte encoding supported by the Encode module
    for example: iso-8859-8

If you don't know if your unicode string is BE or LE, then it's probably BE.

=head3 String (constant length / meta)

A string with constant length:

    String("foo", 5)->parse("hello")
    # returns "hello"

A string with variable length, and encoding:

    String("description", sub { $_->ctx->{description_size} }, encoding => 'UTF-16LE' )

The string length is specified in *characters*, not bytes.

=head3 PaddedString

A Padded string with constant length:

    $s = PaddedString("foo", 10, padchar => "X", paddir => "right");
    $s->parse("helloXXXXX") # return "hello"
    $s->build("hello") # return 'helloXXXXX'

I think that it speaks for itself. only that paddir can be one of qw{right left center},
and there can be also trimdir that can be "right" or "left".

When encoding is supplied, for example:

    $s = PaddedString("foo", 10, encoding => "utf8");

The String length is still specified in *bytes*, not characters. If anyone ever
encouter a padded constant length string with multi byte encoding that it's length is
specified in characters, please send me an email.

=head3 PascalString

PascalString - String with a length marker in the beginning:

    $s = PascalString("foo");
    $s->build("hello world") # returns "\x0bhello world"

The marker can be of any kind:

    $s = PascalString("foo", \&UBInt16);
    $s->build("hello") # returns "\x00\x05hello"

(the marker can be pointer to any function that get a name and return construct.
And on parse that construct should return a value. like the built-in primitives for example)

With encoding:

    $s = PascalString("foo", undef, "utf8");

The string length is specified in *characters*, not bytes.

=head3 CString

And finally, CString:

    $s = CString("foo");
    $s->parse("hello\x00") # returns 'hello'

Can have many optional terminators:

    $s = CString("foo", terminators => "XYZ");
    $s->parse("helloY") # returns 'hello'

With encoding:

    $s = CString("foo", encoding => "utf8");

=head2 Union / RoughUnion

    $s = Union("foo",
        UBInt32("a"),
        UBInt16("b")
    );
    $data = $s->parse("\xaa\xbb\xcc\xdd");
    # $data is { a => 2864434397, b => 43707 }

A Union. currently work only with constant-size constructs, (like primitives, Struct and such)
but not on bit-stream.

    $s = Struct("records",
        ULInt32("record_size"),
        RoughUnion("params",
            Field("raw", sub { $_->ctx(1)->{record_size} - 8 }),
            Array(sub { int(($_->ctx(1)->{record_size} - 8) / 4) }, ULInt32("params")),
        ),
    );

RoughUnion is a type of Union, that doesn't check the size of it's sub-constructs.
it is used when we don't know before-hand the size of the sub-constructs, and the size
of the union as a whole. In the above example, we assume that if the union target is
the array of integers, then it probably record_size % 4 = 0.

If it's not, and we build this construct from the array, then we will be a few bytes
short. 

=head2 Aligned

    $s = Struct("bmp",
        ULInt32("width"),
        ULInt32("height"),
        Array(
            sub { $_->ctx->{height} },
            Aligned(
                Array(
                    sub { $_->ctx(2)->{width} },
                    Byte("index")
                ),
            4),
        ),
    );

Aligned make sure that the contained construct's size if dividable by $modulo. the
syntex is:

    Aligned($subcon, $modulo);

In the above example, we have an excert from the BMP parser. each pixel is a byte.
There is an array of lines (height) that each line is an array of pixels. each line
is aligned to a four bytes boundary. 

The modulo can be any number. 2, 4, 8, 7, 23. 

=head2 Terminator

    Terminator()->parse("")

verify that we reached the end of the stream. Not very useful, unless you are
processing a file and need to verify that you have reached the end

=head2 LasyBound

This construct is estinental for recoursive constructs.

    $s = Struct("foo",
        Flag("has_next"),
        If(sub { $_->ctx->{has_next} }, LazyBound("next", sub { $s })),
    );
    $data = $s->parse("\x01\x01\x01\x00");
    # $data is:
    #    {
    #        has_next => 1,
    #        next => {
    #            has_next => 1,
    #            next => {
    #                has_next => 1,
    #                next => {
    #                    has_next => 0,
    #                    next => undef
    #                }
    #            }
    #        }
    #    }

=head2 Sequence

Similar to Struct, just return an arrat reference instead of hash ref
    
    $s = Sequence("foo",
        UBInt8("a"),
        UBInt16("b"),
        Sequence("bar",
            UBInt8("a"),
            UBInt16("b"),
        )
    );
    $data = $s->parse("ABBabb");
    # $data is [ 65, 16962, [ 97, 25186 ] ]
    
Be aware that not every construct works well under Sequence. For example, Value
will have problems on building. Using Struct is prefered.

=head1 Depricated Constructs

A few construct are being depricated - for the reason that while parsing
a binary stream, you should know before-hand what are you going to get.
If needed, it is possible to use Peek or Pointer to look ahead.

These will be exported only by request, or by using the :all tag

	use Data::ParseBinary qw{:all};
	use Data::ParseBinary qw{UNInt64 OptionalGreedyRange};

=head2 Primitives

The following primitives are depricated, because I don't think it's good practice
to declare a structure with native-order byte order.
What if someone will run your program in a machine with the oposite byte order?

N stand for Platform natural

    UNInt8
    SNInt8
    UNInt16
    SNInt16
    UNInt32
    SNInt32
    UNInt64
    SNInt64
    NFloat32
    NFloat64

These will be exported only by request, or by using the :NATURALS tag

	use Data::ParseBinary qw{:NATURALS};

=head2 Ranges

Please use Array, with constant or dynamic number of elements
    
    # This is an array for 3 to 7 bytes
    $s = Range(3, 7, UBInt8("foo"));
    $data = $s->parse("\x01\x02\x03");
    $data = $s->parse("\x01\x02\x03\x04\x05\x06\x07\x08\x09");
    # in the last example, will take only 7 bytes from the stream
    
    # A range with at least one byte, unlimited
    $s = GreedyRange(UBInt8("foo"));
    
    # A range with zero to unlimited bytes
    $s = OptionalGreedyRange(UBInt8("foo"));

=head2 Optional

Optional construct may or may not be in the stream. Of course, it need a seekable stream.
The optional section usually have a Const in them, that indicates is this section
exists. 

    my $wmf_file = Struct("wmf_file",
        Optional(
            Struct("placeable_header",
                Const(ULInt32("key"), 0x9AC6CDD7),
                ULInt16("handle"),
            ),
        ),
        ULInt16("version"),
        ULInt32("size"), # file size is in words
    );

A better way is to Peek ahead, and decide if this part exists:

    my $wmf_file = Struct("wmf_file",
        Peek(ULInt32("header_key")),
        If(sub { $_->ctx->{header_key} == 0x9AC6CDD7 },
            Struct("placeable_header",
                Const(ULInt32("key"), 0x9AC6CDD7),
                ULInt16("handle"),
            ),
        ),
        ULInt16("version"),
        ULInt32("size"), # file size is in words
    );

=head1 Streams

Until now, everything worked in single-action. build built one construct, and parse
parsed one construct from one string. But suppose the string have more then one
construct in it? Suppose we want to write two constructs into one string? (and
if these constructs are in bit-mode, we can't create and just join them)

So, anyway, we have streams. A stream is an object that let a construct read and
parse bytes from, or build and write bytes to.

Please note, that some constructs can only work on seekable streams.

=head2 String

is seekable, not bit-stream

This is the most basic stream.

    $data = $s->parse("aabb");
    # is equivalent to:
    $stream = CreateStreamReader("aabb");
    $data = $s->parse($stream);
    # also equivalent to:
    $stream = CreateStreamReader(String => "aabb");
    $data = $s->parse($stream);

Being that String is the default stream type, it is not needed to specify it.
So, if there is a string contains two or more structs, that the following code is possible:

    $stream = CreateStreamReader(String => $my_string);
    $data1 = $s1->parse($stream);
    $data2 = $s2->parse($stream);

The other way is equally possible:

    $stream = CreateStreamWriter(String => undef);
    $s1->build($data1);
    $s2->build($data2);
    $my_string = $stream->Flush();

The Flush command in Writer Stream says: finish doing whatever you do, and return
your internal object. For string writer it is simply return the string that it built.
Wrapping streams (like Bit, StringBuffer) finish whatever they are doing, flush the
data to the internal stream, and call Flush on that internal stream.

The special case here is Wrap, that does not call Flush on the internal stream.
usefull for some configurations.
a Flush operation happens in the end of every build operation automatically, and
when a stream being destroyed. 

In creation, the following lines are equvalent:

    $stream = CreateStreamWriter(undef);
    $stream = CreateStreamWriter('');
    $stream = CreateStreamWriter(String => undef);
    $stream = CreateStreamWriter(String => '');

Of course, it is possible to create String Stream with inital string to append to:

    $stream = CreateStreamWriter(String => "aabb");

And any sequencal build operation will append to the "aabb" string.

=head2 StringRef

is seekable, not bit-stream

Mainly for cases when the string is to big to play around with. Writer:

    my $string = '';
    $stream = CreateStreamWriter(StringRef => \$string);
    ... do build operations ...
    # and now the data in $string.
    # or refer to: ${ $stream->Flush() }

Because Flush returns what's inside the stream - in this case a reference to a string.
For Reader:

    my $string = 'MBs of data...';
    $stream = CreateStreamReader(StringRef => \$string);
    ... parse operations ...

=head2 Bit

not seekable, is bit-stream

While every stream support bit-fields, when requesting 2 bits in non-bit-streams
you get these two bits, but a whole byte is consumed from the stream. In bit stream,
only two bits are consumed.

When you use BitStruct construct, it actually wraps the current stream with a bit stream.
If the stream is already bit-stream, it continues as usual.

What does it all have to do with you? great question. Support you have a string containing
a few bit structs, and each struct is aligned to a byte border. Then you can use
the example under the BitStruct section.

However, if the bit structs are not aligned, but compressed one against the other, then
you should use:

    $s = BitStruct("foo",
        Padding(1),
        Flag("myflag"),
        Padding(3),
    );
    $inner = "\x42\0";
    $stream1 = CreateStreamReader(Bit => String => $inner);
    $data1 = $s->parse($stream1);
    # data1 is { myflag => 1 }
    $data2 = $s->parse($stream1);
    # data2 is { myflag => 1 }
    $data3 = $s->parse($stream1);
    # data3 is { myflag => 0 }
    
Note that the Padding constructs detects that it work on bit stream, and pad in bits
instead of bytes.

On Flush the bit stream write the reminding bits (up to a byte border) as 0,
write the last byte to the contained stream, and call Flush on the said contained stream.
so, if we use the $s from the previous code section:

    $stream1 = CreateStreamWriter(Bit => String => undef);
    $s->build({ myflag => 1 }, $stream1);
    $s->build({ myflag => 1 }, $stream1);
    $s->build({ myflag => 0 }, $stream1);
    my $result = $stream1->Flush();
    # $result eq "\x40\x40\0"

In this case each build operation did Flush on the bit stream, closing the last
(and only) byte. so we get three bytes, each contain one record. But if we want
that our constructs will be compressed each against the other, then we need
to protect the bit stream from the Flush command:

    $stream1 = CreateStreamWriter(Wrap => Bit => String => undef);
    $s->build($data1, $stream1);
    $s->build($data1, $stream1);
    $s->build($data2, $stream1);
    my $result = $stream1->Flush()->Flush();
    # $result eq "\x42\0";

Ohh. Two Flushs. one for the Wrap, one for the Bit and the String.
However, as you can see, the structs are packed together. The Wrap stream protects
the Bit stream from the Flush command in the end of every build.

=head2 StringBuffer

is seekable, not bit-stream

Suppose that you have some non-seekable stream. like socket. and suppose that your
struct do use construct that need seekable stream. What can you do?

Enter StringBuffer. It reads from the warped stream exactly the number of bytes
that the struct needs, giving the struct the option to seek inside the read section.
and if the struct seeks ahead - it will just read enough bytes to seek to this place.

In writer stream, the StringBuffer will pospone writing the data to the actual stream,
until the Flush command.

This warper stream is usefull only when the struct seek inside it's borders, and
not sporadically reads data from 30 bytes ahead / back.

    # suppose we have unseekable reader stream names $s_stream
    # (for example, TCP connection)
    $stream1 = CreateStreamReader(StringBuffer => $s_stream);
    # $s is some struct that uses seek. (using Peek, for example)
    $data = $s->parse($stream1);
    # the data were read, you can either drop $stream1 or continue use
    # it for future parses.
    
    # now suppose we have a unseekable writer strea name $w_stream
    $stream1 = CreateStreamWriter(StringBuffer => $w_stream);
    # $s is some struct that uses seek. (using Peek, for example)
    $s->build($data1, $stream1);
    # data is written into $stream1, flushed to $w_stream, and sent.

Note that in StringBuffer, the Flush operation writes the data to the underlining
stream, and then Flushes that stream.

=head2 Wrap

A simple wraping stream, whose only function is to protect the contained stream
from Flush commands. Usable only for writer streams, and can be used to:

1. Protect a Bit stream, so it will compress multiple structs without byte alignment
(see the Bit stream documentation for example)

2. Protect a StringBuffer, so it will aggregate some structs before you will
Flush them all as one to the socket/file/whatever.

=head2 File

is seekable, not bit-stream

Reads from / Writes to a file. it is your responsebility to open the file and binmode it.

    open my $fh, "<", "bin_data.xdf" or die "oh sh...";
    binmode $fh;
    $stream1 = CreateStreamReader(File => $fh);

=head1 Format Library

The Data::ParseBinary arrive with ever-expanding set of pre-defined parsers for popular formats.
Each of these parsers is in it's own module.
And if you have a file-format, then this is how it's done:

    use Data::ParseBinary::Graphics::BMP qw{$bmp_parser};
    open my $fh2, "<", $filename or die "can not open $filename";
    binmode $fh2;
    $data = $bmp_parser->parse(CreateStreamReader(File => $fh2));

And $data will contain the parsed file. In the same way, it is possible to build a BMP file.

Please look for the documentation inside each module,
as it highlights various issues with the various libraries.

=head1 Debugging

=head2 Output on failure

The first line of defence is the output on error. Where did it happend?
in which construct? In which byte of the input?

On error, you get the following "die" messege:

    Got Exception not enought bytes in stream
    
    Streams location:
    1: Stream BitReader in byte #Bit 5
    2: Stream StringReader in byte #2
    Constructs Stack:
    1: BitField f
    2: Struct bar
    3: BitStruct foo

It tells me that I was inside "f" under "bar" under "foo", that it's the
second byte in stream, and because I was inside a BitStuct I get another
line for the stream, pointing me to the exact bit.

=head2 $print_debug_info

What we miss in the "die" messege above, is knowing how did I got there.
If it's inside Array, how many times it happen, and what decissions taken
along the way. But fear not. just set $print_debug_info:

    $Data::ParseBinary::print_debug_info = 1;

This will trigger a print every time the parsing process enter or exit a construct.
So if a parsing dies, you can follow where it did.

=head1 TODO

The following elements were not implemented:

    OnDemand
    Reconfig and a macro Rename
    AlignedStruct
    Probe
    Embed
    Tunnel (TunnelAdapter is already implemented)

Add documentation to: ExtractingAdapter

Move the insertion of the parsed value to the context from the Struct/Sequence constructs
to each indevidual construct?

Streams: SocketStream

FileStreamWriter::Flush : improve.

Ability to give the CreateStreamReader/CreateStreamWriter function an ability to reconginze
socket / filehandle / pointer to string.

Union need to be extended to bit-structs?

use some nice exception system

Fix the Graphics-EMF library :
Find out if the EMF file should work or not. it fails on the statment:
Const(ULInt32("signature"), 0x464D4520)
And complain that it gets "0".

Make BitField a meta construct?

=head1 Thread Safety

This is a pure perl module. there should be not problems.

=head1 BUGS

Currently L/BFloat64 does not work if you don't have 64 bit numbers support
compiled in your Perl

=head1 SEE ALSO

Original PyConstructs homepage: http://construct.wikispaces.com/

=head1 AUTHOR

Fomberg Shmuel, E<lt>owner@semuel.co.ilE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Shmuel Fomberg.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
