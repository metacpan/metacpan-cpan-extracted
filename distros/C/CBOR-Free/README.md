# NAME

CBOR::Free - Fast CBOR for everyone

# SYNOPSIS

    $cbor = CBOR::Free::encode( $some_data_structure );

    $thing = CBOR::Free::decode( $cbor )

    my $tagged = CBOR::Free::tag( 1, '2019-01-02T00:01:02Z' );

Also see [CBOR::Free::Decoder](https://metacpan.org/pod/CBOR::Free::Decoder) for an object-oriented interface
to the decoder.

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
The encoder recognizes and encodes integers, floats, byte and character
strings, array and hash references, [CBOR::Free::Tagged](https://metacpan.org/pod/CBOR::Free::Tagged) instances,
[Types::Serialiser](https://metacpan.org/pod/Types::Serialiser) booleans, and undef (encoded as null).

The encoder currently does not handle any other blessed references.

%OPTS may be:

- `canonical` - A boolean that makes the encoder output
CBOR in [canonical form](https://tools.ietf.org/html/rfc7049#section-3.9).
- `string_encode_mode` - Decides the logic to use for
CBOR encoding of strings and hash keys. (The word “string”
in the below descriptions applies equally to hash keys.)

    Takes one of:

    - `sv`: The default mode of operation. If the string’s internal
    UTF8 flag is set, it will become a CBOR text string; otherwise, it will be
    CBOR binary. This is good for IPC with other Perl code but isn’t a very
    friendly default for working with other languages that probably expect more
    reliably-typed strings.

        This configuration is **NOT** recommended; it’s the default behavior because
        it’s the only configuration that can reasonably fulfill that role. This is
        also the only way to output text and binary strings in a single CBOR document.

    - `encode_text`: Treats all strings as unencoded characters.
    All CBOR strings will be text.

        This is probably what you want if you’re
        following the receive-decode-process-encode-output workflow that
        [perlunitut](https://metacpan.org/pod/perlunitut) recommends (which you might be doing via `use utf8`)
        **AND** if you intend for your CBOR to contain exclusively text.

        Think of this option as: “All my strings are decoded.”

        (Perl internals note: if !SvUTF8, the CBOR will be the UTF8-upgraded
        version.)

    - `as_text`: Treats all strings as octets of UTF-8.
    Wide characters are thus invalid input. All CBOR strings will be text.

        This is probably what you want if you forgo character decoding (and encoding),
        treating all input as octets, **BUT** you still intend for your CBOR to
        contain exclusively text.

        Think of this option as: “I’ve encoded all my strings as UTF-8.”

        (Perl internals note: if SvUTF8, the CBOR will be the downgraded version.)

    - `as_binary`: It’s like `as_text`, but outputs CBOR binary
    instead of text.

        This is probably what you want if your application is “all binary,
        all the time”.

        Think of this option as: “Just the bytes, ma’am.”

- `text_keys` - EXPERIMENTAL. Encodes all Perl hash keys as CBOR text.
If you use this mode then your strings **must** be properly decoded, or else
the output CBOR may mangle your string.

    For example, this:

        CBOR::Free::encode( { "\xc3\xa9" => 1 }, text_keys => 1 )

    … will create a CBOR map with key `"\xc3\x83\xc2\xa9"` because the key
    in the hash that was sent to `encode()` was not properly decoded.

- `preserve_references` - A boolean that makes the encoder encode
multi-referenced values via [CBOR’s “shared references” tags](https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml). This allows encoding of shared
and circular references. It also incurs a performance penalty.

    (Take care that any circular references in your application don’t cause
    memory leaks!)

- `scalar_references` - A boolean that makes the encoder accept
scalar references
(rather than reject them) and encode them via
[CBOR’s “indirection” tag](https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml).
Most languages don’t use references as Perl does, so this option seems of
little use outside all-Perl IPC contexts; it is arguably more useful, then,
for general use to have the encoder reject data structures that most other
languages cannot represent.

Notes on mapping Perl to CBOR:

- The internal state of a defined Perl scalar (e.g., whether it’s an
integer, float, string, etc.) determines its CBOR encoding.
- Perl doesn’t currently provide reliable binary/character string types.
CBOR::Free, in its default configuration, tries to distinguish anyway by
looking at a string’s UTF8 flag: if
set, then the string becomes CBOR text; otherwise, it’ll be CBOR binary.
That’s not always going to work, though. A trivial example:

        perl -MCBOR::Free -e'my $str = "abc"; utf8::decode($str); print CBOR::Free::encode($str)'

    Since `utf8::decode()` doesn’t set the UTF8 flag unless it “has to”
    (see [utf8](https://metacpan.org/pod/utf8)), that function is a no-op in the above.

    The above _will_ produce a CBOR text string, though, if you use
    [Unicode::UTF8](https://metacpan.org/pod/Unicode::UTF8) instead of [utf8](https://metacpan.org/pod/utf8):

        perl -MUnicode::UTF8 -MCBOR::Free -e'print CBOR::Free::encode(Unicode::UTF8::decode_utf8("abc"))'

    The crucial point, though, is that, because Perl itself doesn’t guarantee
    the reliable string types that CBOR recognizes, any heuristics we apply
    to distinguish one from the other are a “best-guess” merely.

    **IMPORTANT:** If you use the default encoding configuration, whatever
    consumes your Perl-sourced CBOR **MUST** account for the prospect of an
    incorrectly-typed string.

- The above applies also to strings vs. numbers: whatever consumes
your Perl-sourced CBOR **MUST** account for the prospect of numbers that
are in CBOR as strings, or vice-versa.
- Perl hash keys are serialized as strings, either binary or text
(following the algorithm described above).
- [Types::Serialiser](https://metacpan.org/pod/Types::Serialiser) booleans are encoded as CBOR booleans.
Perl undef is encoded as CBOR null. (NB: No Perl value encodes as CBOR
undefined.)
- Scalar references (including references to other references) are
unhandled by default, which makes them trigger an exception. You can
optionally tell CBOR::Free to encode them via the `scalar_references` flag.
- Via the optional `preserve_references` flag, circular and shared
references may be preserved. Without this flag, circular references cause an
exception, and other shared references are not preserved.
- Instances of [CBOR::Free::Tagged](https://metacpan.org/pod/CBOR::Free::Tagged) are encoded as tagged values.

An error is thrown on excess recursion or an unrecognized object.

## $data = decode( $CBOR )

Decodes a data structure from CBOR. Errors are thrown to indicate
invalid CBOR. A warning is thrown if $CBOR is longer than is needed
for $data.

Notes on mapping CBOR to Perl:

- `decode()` decodes CBOR text strings as UTF-8-decoded Perl strings.
CBOR binary strings become undecoded Perl strings.

    (See [CBOR::Free::Decoder](https://metacpan.org/pod/CBOR::Free::Decoder) and [CBOR::Free::SequenceDecoder](https://metacpan.org/pod/CBOR::Free::SequenceDecoder) for more
    character-decoding options.)

    Notes:

    - Invalid UTF-8 in a CBOR text string is considered
    invalid input and will thus prompt a thrown exception.
    - You can reliably use `utf8::is_utf8()` to determine if a given Perl
    string came from CBOR text or binary, but **ONLY** if you test the scalar as
    it appears in the newly-decoded data structure itself. Generally Perl code
    should avoid `is_utf8()`, but with CBOR::Free-created strings this limited
    use case is legitimate and potentially gainful.

- The only map keys that `decode()` accepts are integers and strings.
An exception is thrown if the decoder finds anything else as a map key.
Note that, because Perl does not distinguish between binary and text strings,
if two keys of the same map contain the same bytes, Perl will consider these
a duplicate key and prefer the latter.
- CBOR booleans become the corresponding [Types::Serialiser](https://metacpan.org/pod/Types::Serialiser) values.
Both CBOR null and undefined become Perl undef.
- [CBOR’s “indirection” tag](https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml) is interpreted as a scalar reference. This behavior is always
active; unlike with the encoder, there is no need to enable it manually.
- `preserve_references()` mode complements the same flag
given to the encoder.
- This function does not interpret any other tags. If you need to
decode other tags, look at [CBOR::Free::Decoder](https://metacpan.org/pod/CBOR::Free::Decoder). Any unhandled tags that
this function sees prompt a warning but are otherwise ignored.

## $obj = tag( $NUMBER, $DATA )

Tags an item for encoding so that its CBOR encoding will preserve the
tag number. (Include $obj, not $DATA, in the data structure that
`encode()` receives.)

# BOOLEANS

`CBOR::Free::true()` and `CBOR::Free::false()` are defined as
convenience aliases for the equivalent [Types::Serialiser](https://metacpan.org/pod/Types::Serialiser) functions.
(Note that there are no equivalent scalar aliases.)

# FRACTIONAL (FLOATING-POINT) NUMBERS

Floating-point numbers are encoded in CBOR as IEEE 754 half-, single-,
or double-precision. If your Perl is compiled to use anything besides
IEEE 754 double-precision to represent floating-point values (e.g.,
“long double” or “quadmath” compilation options), you may see rounding
errors when converting to/from CBOR. If that’s a problem for you, append
an empty string to your floating-point numbers, which will cause CBOR::Free
to encode them as strings.

# INTEGER LIMITS

CBOR handles up to 64-bit positive and negative integers. Most Perls
nowadays can handle 64-bit integers, but if yours can’t then you’ll
get an exception whenever trying to parse an integer that can’t be
represented with 32 bits. This means:

- Anything greater than 0xffff\_ffff (4,294,967,295)
- Anything less than -0x8000\_0000 (2,147,483,648)

Note that even 64-bit Perls can’t parse negatives that are less than
\-0x8000\_0000\_0000\_0000 (-9,223,372,036,854,775,808); these also prompt an
exception since Perl can’t handle them. (It would be possible to load
[Math::BigInt](https://metacpan.org/pod/Math::BigInt) to handle these; if that’s desirable for you,
file a feature request.)

# ERROR HANDLING

Most errors are represented via instances of subclasses of
[CBOR::Free::X](https://metacpan.org/pod/CBOR::Free::X), which subclasses [X::Tiny::Base](https://metacpan.org/pod/X::Tiny::Base).

# SPEED

CBOR::Free is pretty snappy. I find that it keeps pace with or
surpasses [CBOR::XS](https://metacpan.org/pod/CBOR::XS), [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel::JSON::XS), [JSON::XS](https://metacpan.org/pod/JSON::XS), [Sereal](https://metacpan.org/pod/Sereal),
and [Data::MessagePack](https://metacpan.org/pod/Data::MessagePack).

It’s also quite light. Its only “heavy” dependency is
[Types::Serialiser](https://metacpan.org/pod/Types::Serialiser), which is only loaded when you actually need it.
This keeps memory usage low for when, e.g., you’re using CBOR for
IPC between Perl processes and have no need for true booleans.

# AUTHOR

[Gasper Software Consulting](http://gaspersoftware.com) (FELIPE)

# LICENSE

This code is licensed under the same license as Perl itself.

# SEE ALSO

[CBOR::PP](https://metacpan.org/pod/CBOR::PP) is a pure-Perl CBOR library.

[CBOR::XS](https://metacpan.org/pod/CBOR::XS) is an older CBOR module on CPAN. It’s got more bells and
whistles, so check it out if CBOR::Free lacks a feature you’d like.
Note that [its maintainer has abandoned support for Perl versions from 5.22
onward](http://blog.schmorp.de/2015-06-06-stableperl-faq.html), though,
and its GPL license limits its usefulness in
commercial [perlcc](https://metacpan.org/pod/distribution/B-C/script/perlcc.PL)
applications.
