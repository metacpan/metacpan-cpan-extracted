# NAME

CBOR::Free - Fast CBOR for everyone

# SYNOPSIS

    $cbor = CBOR::Free::encode( $scalar_or_ar_or_hr );

    $thing = CBOR::Free::decode( $cbor )

    my $tagged = CBOR::Free::tag( 1, '2019-01-02T00:01:02Z' );

# DESCRIPTION

This library implements [CBOR](https://tools.ietf.org/html/rfc7049)
via XS under a license that permits commercial usage with no “strings
attached”.

# STATUS

This distribution is an experimental effort. Its interface is still
subject to change. If you decide to use CBOR::Free in your project,
please always check the changelog before upgrading.

# FUNCTIONS

## $cbor = encode( $DATA, %OPTS )

Encodes a data structure or non-reference scalar to CBOR.
The encoder recognizes and encodes integers, floats, binary and UTF-8
strings, array and hash references, [CBOR::Free::Tagged](https://metacpan.org/pod/CBOR::Free::Tagged) instances,
[Types::Serialiser](https://metacpan.org/pod/Types::Serialiser) booleans, and undef (encoded as null).

The encoder currently does not handle any other blessed references.

%OPTS may be:

- `canonical` - A boolean that makes the function output
CBOR in [canonical form](https://tools.ietf.org/html/rfc7049#section-3.9).

Notes on mapping Perl to CBOR:

- The internal state of a defined Perl scalar (e.g., whether it’s an
integer, float, binary string, or UTF-8 string) determines its CBOR
encoding.
- [Types::Serialiser](https://metacpan.org/pod/Types::Serialiser) booleans are encoded as CBOR booleans.
Perl undef is encoded as CBOR null. (NB: No Perl value encodes as CBOR
undefined.)
- Instances of [CBOR::Free::Tagged](https://metacpan.org/pod/CBOR::Free::Tagged) are encoded as tagged values.

An error is thrown on excess recursion or an unrecognized object.

## $data = decode( $CBOR )

Decodes a data structure from CBOR. Errors are thrown to indicate
invalid CBOR. A warning is thrown if $CBOR is longer than is needed
for $data.

Notes on mapping CBOR to Perl:

- CBOR UTF-8 strings become Perl UTF-8 strings. CBOR binary strings
become Perl binary strings. (This may become configurable later.)

    Note that invalid UTF-8 in a CBOR UTF-8 string is considered
    invalid input and will thus prompt a thrown exception.

- CBOR null, undefined, true, and false are considered invalid input
when given as map keys. An exception is thrown if the decoder finds these.
- CBOR booleans become the corresponding [Types::Serialiser](https://metacpan.org/pod/Types::Serialiser) values.
Both CBOR null and undefined become Perl undef.
- Tags are IGNORED for now. (This may become configurable later.)

## $obj = tag( $NUMBER, $DATA )

Tags an item for encoding so that its CBOR encoding will preserve the
tag number. (Include $obj, not $DATA, in the data structure that
`encode()` receives.)

# BOOLEANS

`CBOR::Free::true()`, `CBOR::Free::false()`,
`$CBOR::Free::true`, and `$CBOR::Free::false` are defined as
convenience aliases for the equivalent [Types::Serialiser](https://metacpan.org/pod/Types::Serialiser) values.

# FRACTIONAL (FLOATING-POINT) NUMBERS

Floating-point numbers are encoded in CBOR as IEEE 754 half-, single-,
or double-precision. If your Perl is compiled to use “long double”
floating-point numbers, you may see rounding errors when converting
to/from CBOR. If that’s a problem for you, append an empty string to
your floating-point numbers, which will cause CBOR to encode
them as strings.

# INTEGER LIMITS

CBOR handles up to 64-bit unsigned and signed integers. Most Perls
nowadays can handle this just fine, but if yours can’t then you’ll
get an exception whenever trying to parse an integer that can’t be
represented with 32 bits. This means:

- Anything greater than 0xffff\_ffff (4,294,967,295)
- Anything less than -0x8000\_0000 (2,147,483,648)

Note that even 64-bit Perls can’t parse negatives that are less than
\-0x8000\_0000\_0000\_0000 (-9,223,372,036,854,775,808); these also prompt an
exception since Perl can’t handle them.

# ERROR HANDLING

Most errors are represented via instances of subclasses of
[CBOR::Free::X](https://metacpan.org/pod/CBOR::Free::X).

# AUTHOR

[Gasper Software Consulting](http://gaspersoftware.com) (FELIPE)

# LICENSE

This code is licensed under the same license as Perl itself.

# SEE ALSO

[CBOR::XS](https://metacpan.org/pod/CBOR::XS) is an older CBOR module on CPAN. It implements
some behaviors around CBOR tagging that you might find useful.
Its maintainer has [abandoned support for Perl versions from 5.22
onward](http://blog.schmorp.de/2015-06-06-stableperl-faq.html), though,
and its GPL license limits its usefulness in
commercial [perlcc](https://metacpan.org/pod/distribution/B-C/script/perlcc.PL)
applications.
