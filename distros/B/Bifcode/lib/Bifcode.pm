package Bifcode;
use 5.010;
use strict;
use warnings;
use boolean ();
use Carp (qw/croak shortmess/);
use Exporter::Tidy all => [
    qw( encode_bifcode
      decode_bifcode
      force_bifcode
      diff_bifcode)
];

# ABSTRACT: Serialisation similar to Bencode + undef/UTF8

our $VERSION = '1.002';
our $max_depth;
our @CARP_NOT = (__PACKAGE__);

sub _croak {
    my $type     = shift // croak 'usage: _error($TYPE, [$msg])';
    my %messages = (
        Decode             => 'garbage at',
        DecodeBytes        => 'malformed BYTES length at',
        DecodeBytesTrunc   => 'unexpected BYTES end of data at',
        DecodeBytesTerm    => 'missing BYTES termination at',
        DecodeDepth        => 'nesting depth exceeded at',
        DecodeTrunc        => 'unexpected end of data at',
        DecodeFloat        => 'malformed FLOAT data at',
        DecodeFloatTrunc   => 'unexpected FLOAT end of data at',
        DecodeInteger      => 'malformed INTEGER data at',
        DecodeIntegerTrunc => 'unexpected INTEGER end of data at',
        DecodeTrailing     => 'trailing garbage at',
        DecodeUTF8         => 'malformed UTF8 string length at',
        DecodeUTF8Trunc    => 'unexpected UTF8 end of data at',
        DecodeUTF8Term     => 'missing UTF8 termination at',
        DecodeUsage        => undef,
        DiffUsage          => 'usage: diff_bifcode($b1, $b2, [$diff_args])',
        EncodeBytesUndef   => 'Bifcode::BYTES ref is undefined',
        EncodeFloat        => undef,
        EncodeFloatUndef   => 'Bifcode::FLOAT ref is undefined',
        EncodeInteger      => undef,
        EncodeIntegerUndef => 'Bifcode::INTEGER ref is undefined',
        DecodeKeyType      => 'dict key is not BYTES or UTF8 at',
        DecodeKeyDuplicate => 'duplicate dict key at',
        DecodeKeyOrder     => 'dict key not in sort order at',
        DecodeKeyValue     => 'dict key is missing value at',
        EncodeUTF8Undef    => 'Bifcode::UTF8 ref is undefined',
        EncodeUnhandled    => undef,
        EncodeUsage        => 'usage: encode_bifcode($arg)',
        ForceUsage         => 'ref and type must be defined',
    );

    my $err   = 'Bifcode::Error::' . $type;
    my $msg   = shift // $messages{$type} // '(no message)';
    my $short = shortmess('');

    $msg =~ s! at$!' at input byte '. ( pos() // 0 )!e;

    eval 'package ' . $err . qq[;
        use overload
          bool => sub { 1 },
          '""' => sub { \${ \$_[0] } . ' (' . ( ref \$_[0] ) . ')$short' },
          fallback => 1; 
        1; ];

    die bless \$msg, $err;
}

my $match = qr/ \G (?|
      (~)
    | (0)
    | (1)
    | (B|U) (?: ( 0 | [1-9] [0-9]* ) : )? 
    | (I)   (?: ( 0 | -? [1-9] [0-9]* ) , )?
    | (F)   (?: ( 0 | -? [1-9] [0-9]* ) \. ( 0 | [0-9]* [1-9] ) e
                ( (?: 0 | -? [1-9] ) [0-9]* ) , )?
    | (\[)
    | (\{)
) /x;

sub _decode_bifcode_chunk {
    local $max_depth = $max_depth - 1 if defined $max_depth;

    unless (m/$match/gc) {
        _croak m/ \G \z /xgc ? 'DecodeTrunc' : 'Decode';
    }

    if ( $1 eq '~' ) {
        return undef;
    }
    elsif ( $1 eq '0' ) {
        return boolean::false;
    }
    elsif ( $1 eq '1' ) {
        return boolean::true;
    }
    elsif ( $1 eq 'B' ) {
        my $len = $2 // _croak 'DecodeBytes';
        _croak 'DecodeBytesTrunc' if $len > length() - pos();

        my $data = substr $_, pos(), $len;
        pos() = pos() + $len;

        _croak 'DecodeBytesTerm' unless m/ \G , /xgc;
        return $data;
    }
    elsif ( $1 eq 'U' ) {
        my $len = $2 // _croak 'DecodeUTF8';
        _croak 'DecodeUTF8Trunc' if $len > length() - pos();

        utf8::decode( my $str = substr $_, pos(), $len );
        pos() = pos() + $len;

        _croak 'DecodeUTF8Term' unless m/ \G , /xgc;
        return $str;
    }
    elsif ( $1 eq 'I' ) {
        return $2 if defined $2;
        _croak 'DecodeIntegerTrunc' if m/ \G \z /xgc;
        _croak 'DecodeInteger';
    }
    elsif ( $1 eq 'F' ) {
        if ( !defined $2 ) {
            _croak 'DecodeFloatTrunc' if m/ \G \z /xgc;
            _croak 'DecodeFloat';
        }
        _croak 'DecodeFloat'
          if $2 eq '0'      # mantissa 0.
          and $3 eq '0'     # mantissa 0.0
          and $4 ne '0';    # sign or exponent 0.0e0

        return $2 . '.' . $3 . 'e' . $4;
    }
    elsif ( $1 eq '[' ) {
        _croak 'DecodeDepth' if defined $max_depth and $max_depth < 0;

        my @list;
        until (m/ \G \] /xgc) {
            push @list, _decode_bifcode_chunk();
        }
        return \@list;
    }
    elsif ( $1 eq '{' ) {
        _croak 'DecodeDepth' if defined $max_depth and $max_depth < 0;

        my $last_key;
        my %hash;
        until (m/ \G \} /xgc) {
            _croak 'DecodeTrunc' if m/ \G \z /xgc;
            _croak 'DecodeKeyType' unless m/ \G (B|U) /xgc;

            pos() = pos() - 1;
            my $key = _decode_bifcode_chunk();

            _croak 'DecodeKeyDuplicate' if exists $hash{$key};
            _croak 'DecodeKeyOrder'
              if defined $last_key and $key lt $last_key;
            _croak 'DecodeKeyValue' if m/ \G \} /xgc;

            $last_key = $key;
            $hash{$key} = _decode_bifcode_chunk();
        }
        return \%hash;
    }
}

sub decode_bifcode {
    local $_         = shift;
    local $max_depth = shift;

    _croak 'DecodeUsage', 'decode_bifcode: too many arguments' if @_;
    _croak 'DecodeUsage', 'decode_bifcode: input undefined'
      unless defined $_;
    _croak 'DecodeUsage', 'decode_bifcode: only accepts bytes'
      if utf8::is_utf8($_);

    my $deserialised_data = _decode_bifcode_chunk();
    _croak 'DecodeTrailing' if $_ !~ m/ \G \z /xgc;
    return $deserialised_data;
}

my $number_qr = qr/\A ( 0 | -? [1-9] [0-9]* )
                    ( \. ( [0-9]+? ) 0* )?
                    ( e ( -? [0-9]+ ) )? \z/xi;

sub _encode_bifcode {
    map {
        if ( !defined $_ ) {
            '~';
        }
        elsif ( ( my $ref = ref $_ ) eq '' ) {
            if ( $_ =~ $number_qr ) {
                if ( defined $3 or defined $5 ) {

                    # normalize to BIFCODE_FLOAT standards
                    my $x = 'F' . ( 0 + $1 )    # remove leading zeros
                      . '.' . ( $3 // 0 ) . 'e' . ( 0 + ( $5 // 0 ) ) . ',';
                    $x =~ s/ ([1-9]) (0+ e)/.${1}e/x;    # remove trailing zeros
                    $x;
                }
                else {
                    'I' . $_ . ',';
                }
            }
            else {
                utf8::encode( my $str = $_ );
                'U' . length($str) . ':' . $str . ',';
            }
        }
        elsif ( $ref eq 'ARRAY' ) {
            '[' . join( '', map _encode_bifcode($_), @$_ ) . ']';
        }
        elsif ( $ref eq 'HASH' ) {
            '{' . join(
                '',
                do {
                    my @k = sort keys %$_;
                    map {
                        my $k = shift @k;

                        # if ( is valid utf8($k) ) {
                        utf8::encode($k);
                        ( 'U' . length($k) . ':' . $k . ',', $_ );

                        # }
                        # else {
                        #     ('B' . length($k) . ':' . $k .',', $_);
                        # }
                    } _encode_bifcode( @$_{@k} );
                  }
            ) . '}';
        }
        elsif ( $ref eq 'SCALAR' or $ref eq 'Bifcode::BYTES' ) {
            $$_ // _croak 'EncodeBytesUndef';
            'B' . length($$_) . ':' . $$_ . ',';
        }
        elsif ( boolean::isBoolean($_) ) {
            $_;
        }
        elsif ( $ref eq 'Bifcode::INTEGER' ) {
            $$_ // _croak 'EncodeIntegerUndef';
            _croak 'EncodeInteger', 'invalid integer: ' . $$_
              unless $$_ =~ m/\A (?: 0 | -? [1-9] [0-9]* ) \z/x;
            sprintf 'I%s,', $$_;
        }
        elsif ( $ref eq 'Bifcode::FLOAT' ) {
            $$_ // _croak 'EncodeFloatUndef';
            _croak 'EncodeFloat', 'invalid float: ' . $$_
              unless $$_ =~ $number_qr;

            my $x = 'F' . ( 0 + $1 )    # remove leading zeros
              . '.' . ( $3 // 0 ) . 'e' . ( 0 + ( $5 // 0 ) ) . ',';
            $x =~ s/ ([1-9]) (0+ e)/.${1}e/x;    # remove trailing zeros
            $x;
        }
        elsif ( $ref eq 'Bifcode::UTF8' ) {
            my $str = $$_ // _croak 'EncodeUTF8Undef';
            utf8::encode($str);    #, sub { croak 'invalid Bifcode::UTF8' } );
            'U' . length($str) . ':' . $str . ',';
        }
        else {
            _croak 'EncodeUnhandled', 'unhandled data type: ' . $ref;
        }
    } @_;
}

sub encode_bifcode {
    _croak 'EncodeUsage' if @_ != 1;
    (&_encode_bifcode)[0];
}

sub force_bifcode {
    my $ref  = shift;
    my $type = shift;

    _croak 'ForceUsage' unless defined $ref and defined $type;
    bless \$ref, 'Bifcode::' . uc($type);
}

sub _expand_bifcode {
    my $bifcode = shift;
    $bifcode =~ s/ (
            [~\[\]\{\}]
            | (U|B) [0-9]+ :  
            | F -? [0-9]+ \. [0-9]+ e -? [0-9]+ ,  
            | I [0-9]+ ,  
        ) /\n$1/gmx;
    $bifcode =~ s/ \A \n //mx;
    $bifcode . "\n";
}

sub diff_bifcode {
    _croak 'DiffUsage' unless @_ >= 2 and @_ <= 3;
    my $b1        = shift;
    my $b2        = shift;
    my $diff_args = shift || { STYLE => 'Unified' };

    require Text::Diff;

    $b1 = _expand_bifcode($b1);
    $b2 = _expand_bifcode($b2);
    return Text::Diff::diff( \$b1, \$b2, $diff_args );
}

decode_bifcode('I1,');

__END__

=pod

=encoding utf8

=head1 NAME

Bifcode - simple serialization format

=head1 VERSION

1.002 (2018-09-23)


=head1 SYNOPSIS

    use boolean;
    use Bifcode qw( encode_bifcode decode_bifcode );

    my $bifcode = encode_bifcode {
        bools   => [ boolean::false, boolean::true, ],
        bytes   => \pack( 's<',       255 ),
        integer => 25,
        float   => 1.25e-5,
        undef   => undef,
        utf8    => "\x{df}",
    };

    # 7b 55 35 3a 62 6f 6f 6c 73 2c 5b 30    {U5:bools,[0
    # 31 5d 55 35 3a 62 79 74 65 73 2c 42    1]U5:bytes,B
    # 32 3a ff  0 2c 55 35 3a 66 6c 6f 61    2:..,U5:floa
    # 74 2c 46 31 2e 32 35 65 2d 35 2c 55    t,F1.25e-5,U
    # 37 3a 69 6e 74 65 67 65 72 2c 49 32    7:integer,I2
    # 35 2c 55 35 3a 75 6e 64 65 66 2c 7e    5,U5:undef,~
    # 55 34 3a 75 74 66 38 2c 55 32 3a c3    U4:utf8,U2:.
    # 9f 2c 7d                               .,}

    my $decoded = decode_bifcode $bifcode;

=head1 DESCRIPTION

B<Bifcode> implements the I<bifcode> serialisation format, a mixed
binary/text encoding with support for the following data types:

=over

=item * Primitive:

=over

=item * Undefined(null)

=item * Booleans(true/false)

=item * Integer numbers

=item * Floating point numbers

=item * UTF8 strings

=item * Binary strings

=back

=item * Structured:

=over

=item * Arrays(lists)

=item * Hashes(dictionaries)

=back

=back

The encoding is simple to construct and relatively easy to parse. There
is no need to escape special characters in strings. It is not
considered human readable, but as it is mostly text it can usually be
visually debugged.

I<bifcode> can only be constructed canonically; i.e. there is only one
possible encoding per data structure. This property makes it suitable
for comparing structures (using cryptographic hashes) across networks.

In terms of size the encoding is similar to minified JSON. In terms of
speed this module compares well with other pure Perl encoding modules
with the same features.

=head1 MOTIVATION

I<bifcode> was created for a project because none of currently
available serialization formats (Bencode, JSON, MsgPack, Netstrings,
Sereal, YAML, etc) met the requirements of:

=over

=item * Support for undef

=item * Support for binary data

=item * Support for UTF8 strings

=item * Universally-recognized canonical form for hashing

=item * Trivial to construct on the fly from SQLite triggers

=back

I have no lofty goals or intentions to promote this outside of my
specific case, but would appreciate hearing about other uses or
implementations.

=head1 SPECIFICATION

The encoding is defined as follows:

=head2 BIFCODE_UNDEF

A null or undefined value correspond to "~".

=head2 BIFCODE_TRUE and BIFCODE_FALSE

Boolean values are represented by "1" and "0".

=head2 BIFCODE_UTF8

A UTF8 string is "U" followed by the octet length of the encoded string
as a base ten number followed by a colon and the encoded string
followed by ",". For example the Perl string "\x{df}" (ß) corresponds
to "U2:\x{c3}\x{9f},".

=head2 BIFCODE_BYTES

Opaque data is 'B' followed by the octet length of the data as a base
ten number followed by a colon and then the data itself followed by
",". For example a three-byte blob 'xyz' corresponds to 'B3:xyz,'.

=head2 BIFCODE_INTEGER

Integers are represented by an 'I' followed by the number in base 10
followed by a ','. For example 'I3,' corresponds to 3 and 'I-3,'
corresponds to -3. Integers have no size limitation. 'I-0,' is invalid.
All encodings with a leading zero, such as 'I03,', are invalid, other
than 'I0,', which of course corresponds to 0.

=head2 BIFCODE_FLOAT

Floats are represented by an 'F' followed by a decimal number in base
10 followed by a 'e' followed by an exponent followed by a ','.  For
example 'F3.0e-1,' corresponds to 0.3 and 'F-0.1e0,' corresponds to
-0.1. Floats have no size limitation.  'F-0.0e0,' is invalid.  All
encodings with an extraneous leading zero, such as 'F03.0e0,', or an
extraneous trailing zero, such as 'F3.10e0,', are invalid.

=head2 BIFCODE_LIST

Lists are encoded as a '[' followed by their elements (also I<bifcode>
encoded) followed by a ']'. For example '[U4:spam,U4:eggs,]'
corresponds to ['spam', 'eggs'].

=head2 BIFCODE_DICT

Dictionaries are encoded as a '{' followed by a list of alternating
keys and their corresponding values followed by a '}'. For example,
'{U3:cow,U3:moo,U4:spam,U4:eggs,}' corresponds to {'cow': 'moo',
'spam': 'eggs'} and '{U4:spam,[U1:a,U1:b,]}' corresponds to {'spam':
['a', 'b']}. Keys must be BIFCODE_UTF8 or BIFCODE_BYTES and appear in
sorted order (sorted as raw strings, not alphanumerics).

=head1 INTERFACE

=head2 C<encode_bifcode( $datastructure )>

Takes a single argument which may be a scalar, or may be a reference to
either a scalar, an array or a hash. Arrays and hashes may in turn
contain values of these same types. Returns a byte string.

The mapping from Perl to I<bifcode> is as follows:

=over

=item * 'undef' maps directly to BIFCODE_UNDEF.

=item * The C<true> and C<false> functions from the L<boolean>
distribution encode to BIFCODE_TRUE and BIFCODE_FALSE.

=item * Plain scalars are treated as BIFCODE_UTF8 unless:

=over

=item 

They look like canonically represented integers in which case they are
mapped to BIFCODE_INTEGER; or

=item

They look like floats in which case they are mapped to BIFCODE_FLOAT.

=back

=item * SCALAR references become BIFCODE_BYTES.

=item * ARRAY references become BIFCODE_LIST.

=item * HASH references become BIFCODE_DICT.

=back

You can force scalars to be encoded a particular way by passing a
reference to them blessed as Bifcode::BYTES, Bifcode::INTEGER,
Bifcode::FLOAT or Bifcode::UTF8. The C<force_bifcode> function below
can help with creating such references.

This subroutine croaks on unhandled data types.

=head2 C<decode_bifcode( $string [, $max_depth ] )>

Takes a byte string and returns the corresponding deserialised data
structure.

If you pass an integer for the second option, it will croak when
attempting to parse dictionaries nested deeper than this level, to
prevent DoS attacks using maliciously crafted input.

I<bifcode> types are mapped back to Perl in the reverse way to the
C<encode_bifcode> function, with the exception that any scalars which
were "forced" to a particular type (using blessed references) will
decode as unblessed scalars.

Croaks on malformed data.

=head2 C<force_bifcode( $scalar, $type )>

Returns a reference to $scalar blessed as Bifcode::$TYPE. The value of
$type is not checked, but the C<encode_bifcode> function will only
accept the resulting reference where $type is one of 'bytes', 'float',
'integer' or 'utf8'.

=head2 C<diff_bifcode( $bc1, $bc2, [$diff_args] )>

Returns a string representing the difference between two bifcodes. The
inputs do not need to be valid Bifcode; they are only expanded with a
very simple regex before the diff is done. The third argument
(C<$diff_args>) is passed directly to L<Text::Diff>.

Croaks if L<Text::Diff> is not installed.

=head1 DIAGNOSTICS

The following exceptions may be raised by B<Bifcode>:

=over

=item Bifcode::Error::Decode

Your data is malformed in a non-identifiable way.

=item Bifcode::Error::DecodeBytes

Your data contains a byte string with an invalid length.

=item Bifcode::Error::DecodeBytesTrunc

Your data includes a byte string declared to be longer than the
available data.

=item Bifcode::Error::DecodeBytesTerm

Your data includes a byte string that is missing a "," terminator.

=item Bifcode::Error::DecodeDepth

Your data contains dicts or lists that are nested deeper than the
$max_depth passed to C<decode_bifcode()>.

=item Bifcode::Error::DecodeTrunc

Your data is truncated.

=item Bifcode::Error::DecodeFloat

Your data contained something that was supposed to be a float but
didn't make sense.

=item Bifcode::Error::DecodeFloatTrunc

Your data contains a float that is truncated.

=item Bifcode::Error::DecodeInteger

Your data contained something that was supposed to be an integer but
didn't make sense.

=item Bifcode::Error::DecodeIntegerTrunc

Your data contains an integer that is truncated.

=item Bifcode::Error::DecodeKeyType

Your data violates the I<bifcode> format constaint that all dict keys
be BIFCODE_BYTES or BIFCODE_UTF8.

=item Bifcode::Error::DecodeKeyDuplicate

Your data violates the I<bifcode> format constaint that all dict keys
must be unique.

=item Bifcode::Error::DecodeKeyOrder

Your data violates the I<bifcode> format constaint that dict keys must
appear in lexical sort order.

=item Bifcode::Error::DecodeKeyValue

Your data contains a dictionary with an odd number of elements.

=item Bifcode::Error::DecodeTrailing

Your data does not end after the first I<bifcode>-serialised item.

=item Bifcode::Error::DecodeUTF8

Your data contained a UTF8 string with an invalid length.

=item Bifcode::Error::DecodeUTF8Trunc

Your data includes a string declared to be longer than the available
data.

=item Bifcode::Error::DecodeUTF8Term

Your data includes a UTF8 string that is missing a "," terminator.

=item Bifcode::Error::DecodeUsage

You called C<decode_bifcode()> with invalid arguments.

=item Bifcode::Error::DiffUsage

You called C<diff_bifcode()> with invalid arguments.

=item Bifcode::Error::EncodeBytesUndef

You attempted to encode C<undef> as a byte string.

=item Bifcode::Error::EncodeFloat

You attempted to encode something as a float that isn't recognised as
one.

=item Bifcode::Error::EncodeFloatUndef

You attempted to encode C<undef> as a float.

=item Bifcode::Error::EncodeInteger

You attempted to encode something as an integer that isn't recognised
as one.

=item Bifcode::Error::EncodeIntegerUndef

You attempted to encode C<undef> as an integer.

=item Bifcode::Error::EncodeUTF8Undef

You attempted to encode C<undef> as a UTF8 string.

=item Bifcode::Error::EncodeUnhandled

You are trying to serialise a data structure that contains a data type
not supported by the I<bifcode> format.

=item Bifcode::Error::EncodeUsage

You called C<encode_bifcode()> with invalid arguments.

=item Bifcode::Error::ForceUsage

You called C<force_bifcode()> with invalid arguments.

=back

=head1 BUGS AND LIMITATIONS

Strings and numbers are practically indistinguishable in Perl, so
C<encode_bifcode()> has to resort to a heuristic to decide how to
serialise a scalar. This cannot be fixed.

At the moment all Perl hash keys are encoded as BIFCODE_UTF8 as I have
not yet had the need for BIFCODE_BYTES keys or found a cheap, obvious
way to distinguish the two.

=head1 SEE ALSO

This distribution includes the L<diff-bifcode> command-line utility for
comparing Bifcodes in files.

=head1 AUTHOR

Mark Lawrence <nomad@null.net>, heavily based on Bencode by Aristotle
Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c):

=over

=item * 2015 by Aristotle Pagaltzis

=item * 2017-2018 by Mark Lawrence.

=back

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

