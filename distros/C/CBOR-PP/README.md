# NAME

CBOR::PP - CBOR in pure Perl

# SYNOPSIS

    my $value = CBOR::PP::decode( $cbor );

    my $tagged = CBOR::PP::tag( 123, 'value' );

    my $cbor = CBOR::PP::encode( [ 'some', { data => $tagged } ] );

    # canonical encoding
    $cbor = CBOR::PP::encode(
        { aa => 'last', a => 'first', z => 'middle' },
        { canonical => 1 },
    );

# DESCRIPTION

This library implements a [CBOR](https://tools.ietf.org/html/rfc7049)
encoder and decoder in pure Perl.

This module itself is a syntactic convenience. For details about what
CBOR::PP can and can’t do, see the underlying [CBOR::PP::Encode](https://metacpan.org/pod/CBOR::PP::Encode) and
[CBOR::PP::Decode](https://metacpan.org/pod/CBOR::PP::Decode) modules.

# STATUS

This distribution is an experimental effort.

That having been said, CBOR is a simple enough encoding that I
suspect—I hope!—that bugs here will be few and far between.

Note that, because [CBOR::Free](https://metacpan.org/pod/CBOR::Free) is so much faster,
there probably won’t be much further effort put into this pure-Perl code.

Note that this distribution’s interface can still change. If you decide
to use CBOR::PP in your project, please always check the changelog before
upgrading.

# FRACTIONAL (FLOATING-POINT) NUMBERS

Floating-point numbers are encoded in CBOR as IEEE 754 half-, single-,
or double-precision. If your Perl is compiled to use “long double”
floating-point numbers, you may see rounding errors when converting
to/from CBOR. If that’s a problem for you, append an empty string to
your floating-point numbers, which will cause CBOR::PP to encode
them as strings.

# SEE ALSO

[CBOR::Free](https://metacpan.org/pod/CBOR::Free) is a **much** faster, XS-based encoder/decoder.

[CBOR::XS](https://metacpan.org/pod/CBOR::XS) isn’t quite as fast as CBOR::Free but is older and
(as of this writing) more widely used. It’s also technically unsupported
on current Perl versions, though, and its GPL license makes it
useful only for open-source projects.

# AUTHOR

[Gasper Software Consulting](http://gaspersoftware.com) (FELIPE)

# LICENSE

This code is licensed under the same license as Perl itself.
