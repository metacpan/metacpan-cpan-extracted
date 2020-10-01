package Crypt::Perl::ECDSA;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::ECDSA - Elliptic curve cryptography in pure Perl

=head1 SYNOPSIS

    my $pub_key1 = Crypt::Perl::ECDSA::Parse::public($pem_or_der);
    my $prv_key1 = Crypt::Perl::ECDSA::Parse::private($pem_or_der);

    #----------------------------------------------------------------------

    my $prkey_by_name = Crypt::Perl::ECDSA::Generate::by_curve_name('secp521r1');

    #Probably only useful for trying out a custom curve?
    my $prkey_by_curve = Crypt::Perl::ECDSA::Generate::by_explicit_curve(
        {
            p => ..., #isa Crypt::Perl::BigInt
            a => ..., #isa Crypt::Perl::BigInt
            b => ..., #isa Crypt::Perl::BigInt
            n => ..., #isa Crypt::Perl::BigInt

            # Supposedly this can be deduced from the above, but I don’t
            # see the math for this around. It’s not in libtomcryt, AFAICT.
            # It may have to do with Schoof’s Algorithm?
            h => ..., #isa Crypt::Perl::BigInt

            gx => ..., #isa Crypt::Perl::BigInt
            gy => ..., #isa Crypt::Perl::BigInt
        },
    );

    #----------------------------------------------------------------------

    my $msg = 'My message';

    # Deterministic signatures. This is probably the way to go
    # for normal use cases. You can use sha1, sha224, sha256, sha384,
    # or sha512.
    my $det_sig = $private->sign_sha256($msg);

    my $msg_hash = Digest::SHA::sha256($msg);

    # NB: This verifies a *digest*, not the original message.
    die 'Wut' if !$public->verify($msg_hash, $sig);
    die 'Wut' if !$private->verify($msg_hash, $sig);

    # Signature in JSON Web Algorithm format (deterministic):
    my $jwa_sig = $private->sign_jwa($msg);

    # You can also create non-deterministic signatures. These risk a
    # security compromise if there is any flaw in the underlying CSPRNG.
    # Note that this signs a *digest*, not the message itself.
    my $sig = $private->sign($msg_hash);

    #----------------------------------------------------------------------

    $key->to_der_with_curve_name();
    $key->to_der_with_curve_name( compressed => 1 );
    $key->to_pem_with_curve_name();
    $key->to_pem_with_curve_name( compressed => 1 );

    $key->to_der_with_explicit_curve();
    $key->to_der_with_explicit_curve( seed => 1 );
    $key->to_der_with_explicit_curve( compressed => 1 );
    $key->to_der_with_explicit_curve( seed => 1, compressed => 1 );
    $key->to_pem_with_explicit_curve();
    $key->to_pem_with_explicit_curve( seed => 1 );
    $key->to_pem_with_explicit_curve( compressed => 1 );
    $key->to_pem_with_explicit_curve( seed => 1, compressed => 1 );

=head1 DISCUSSION

See the documentation for L<Crypt::Perl::ECDSA::PublicKey> and
L<Crypt::Perl::ECDSA::PrivateKey> for discussions of what these interfaces
can do.

=head1 SECURITY

The security advantages of elliptic-curve cryptography (ECC) are a matter of
some controversy. While the math itself is apparently bulletproof, there are
varying opinions about the integrity of the various curves that are recommended
for ECC. Some believe that some curves contain backdoors that would allow
L<NIST|https://www.nist.gov> to sniff a transmission. For more information,
look at L<http://safecurves.cr.yp.to>.

That said, RSA will eventually no longer be viable: as RSA keys get bigger, the
security advantage of increasing their size diminishes.

C<Crypt::Perl> “has no opinion” regarding which curves you use; it ships all
of the prime-field curves that (L<OpenSSL|http://openssl.org>) includes and
works with any of them. You can try out custom curves as well.

=head2 Deterministic Signatures

This library can create deterministic signatures, as per
L<RFC 6979|https://tools.ietf.org/html/rfc6979>. Read that RFC’s
introduction to learn why this is a good idea.

=head1 FORMATS SUPPORTED

Elliptic-curve keys can be in a variety of formats. This library supports
almost all of them:

=over

=item Parse and export of named curves and explicit curves. (See below
about explicit curve parameters.)

=item Parse and export of curve points in compressed or uncompressed form,
and parse of points in hybrid form.
(NB: L<RFC 5480|https://www.rfc-editor.org/rfc/rfc5480.txt>
prohibits use of the hybrid form.)

=back

Explicit curves (i.e., giving the curve by full parameters rather than by
name reference) may be a known curve or an arbitrary curve.
Explicit curves may include or omit the seed value. It is omitted in output
by default. Explicit curves may also include or
omit the cofactor, but if the curve is unknown the cofactor is required.
This is because this library’s export of explicit curves always includes the
cofactor. While it’s not required for ECDSA, it’s recommended, and it’s
required for ECDH. Moreover, unlike the seed (which nither ECDSA nor ECDH
requires), the cofactor is small enough that its inclusion only enlarges the
key by a few bytes.

I believe the cofactor can be deduced from the other curve parameters;
if someone wants to submit a PR to do this that would be nice.

Generator/base points will be exported as compressed or uncompressed
according to the public point. If for some reason you really need a
compressed base point but an uncompressed public point or vice-versa,
and you need this library to do it for you,
please explain your need for such a thing in your pull request. :-)

=head1 TODO

Functionality can be augmented as feature requests come in.
Patches are welcome—particularly with tests!

In particular, it would be great to support characteristic-two curves,
though almost everything seems to expect the prime-field variety.
(OpenSSL is the only implementation I know of that
supports characteristic-two.)

It would also be nice to have logic that deduces the cofactor from the
other curve parameters.

=head1 ACKNOWLEDGEMENTS

Most of the ECDSA logic here is ported from Kenji Urushima’s
L<jsrsasign|http://kjur.github.io/jsrsasign/>.

Curve data is copied from OpenSSL. (See the script included in the
distribution.)

The point decompression logic is ported from L<LibTomCrypt|http://libtom.net>.

Deterministic ECDSA logic derived in part from
L<python-ecdsa|https://github.com/ecdsa/python-ecdsa>.

=cut

1;
