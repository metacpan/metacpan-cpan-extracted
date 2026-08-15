package Crypt::JWS;

use 5.016;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Crypt::JWS', $VERSION);

require Crypt::JWS::Key;

our @EXPORT_OK = qw(
    sign verify peek
    sha256 sha384 sha512
    hmac_sha256 hmac_sha384 hmac_sha512
    b64url b64url_decode ct_eq random_bytes
);

1;

__END__

=head1 NAME

Crypt::JWS - JSON Web Signatures over OpenSSL's libcrypto

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Crypt::JWS qw(sign verify);
	use Crypt::JWS::Key;

	my $key = Crypt::JWS::Key->generate('ES256');

	my $token   = sign($key, $payload_bytes, alg => 'ES256',
	                   kid => $key->thumbprint, typ => 'at+jwt');

	my $payload = verify($token, $key, algs => ['ES256']);
	# undef on any failure - tampering, wrong key, alg outside the
	# allowlist, malformed token

=head1 DESCRIPTION

Crypt::JWS signs and verifies JWS compact serializations (RFC 7515)
using OpenSSL's libcrypto. 

Supported algorithms: RS256/384/512, ES256/384/512, HS256/384/512. All
three families run through one EVP code path. The C<none> algorithm has
no code path at all, and C<verify> requires a caller-supplied C<algs>
allowlist - the token header's C<alg> can only select among algorithms
the caller already agreed to, and the key's type is cross-checked
against the algorithm family in C, so RSA-key-as-HMAC-secret confusion
attacks are structurally impossible.

OpenSSL 1.1 and 3.x are both supported; the divergent key import APIs
are chosen by compile-time feature probes.

=head1 FUNCTIONS

=head2 sign ($key, $payload, %opts)

Returns the compact serialization. C<alg> is required. Optional C<kid>
and C<typ> land in the protected header; C<extra_headers> merges beneath
them and can never clobber them. The key must carry a private part and
match the algorithm family.

=head2 verify ($token, $key, algs => \@allowlist)

Returns the payload bytes, or undef on any failure - one bit of
information, never a reason. C<$key> may be a coderef called with the
decoded header (kid routing against a JWKS set); it returns the key to
use or undef.

=head2 peek ($token)

The decoded protected header, without any validation whatsoever. For
routing decisions only; never trust its contents.

=head2 sha256 / sha384 / sha512 ($bytes)

=head2 hmac_sha256 / hmac_sha384 / hmac_sha512 ($key, $bytes)

=head2 b64url ($bytes) / b64url_decode ($str)

Unpadded base64url (RFC 4648 section 5); decode tolerates padding and
the standard alphabet.

=head2 ct_eq ($a, $b)

Constant-time equality via CRYPTO_memcmp.

=head2 random_bytes ($n)

CSPRNG bytes via RAND_bytes; croaks rather than degrades on failure.

=head1 C ABI

Crypt::JWS exposes a small C ABI so that B<other XS modules> can sign,
verify, and digest entirely in C, with no per-call Perl dispatch. The
motivating consumers are PDF signing (L<PDF::Make>) and any server that
wants JWS operations on a hot path.

The header is distributed through L<ExtUtils::Depends> - a consumer
B<does not copy it>. This dist is an ExtUtils::Depends provider (it also
consumes File::Raw::JSON the same way): building installs F<jws_abi.h>
and writes C<Crypt::JWS::Install::Files>, so a dependent's
F<Makefile.PL> that says

    my $pkg = ExtUtils::Depends->new('My::Consumer', 'Crypt::JWS');
    WriteMakefile( ..., $pkg->get_makefile_vars );

picks up F<jws_abi.h> on its include path automatically.

This is an integration surface for XS authors, not part of the Perl
API. Perl callers should use L</FUNCTIONS> and L<Crypt::JWS::Key>.

=head2 The table

The contract lives in F<include/jws_abi.h> (installed via
ExtUtils::Depends):

    #define JWS_ABI_VERSION 1

    typedef struct jws_abi {
        int version;                              /* == JWS_ABI_VERSION */

        /* key lifecycle - NULL on failure */
        void *(*key_from_pem)(pTHX_ const char *pem, STRLEN len);
        void *(*key_from_oct)(pTHX_ const unsigned char *secret, STRLEN len);
        void  (*key_free)(pTHX_ void *key);
        int   (*key_is_private)(pTHX_ void *key);

        /* raw JWS ops over signing-input bytes; alg is "RS256" etc. */
        SV  *(*sign)(pTHX_ void *key, const char *alg, STRLEN alglen,
                     const unsigned char *input, STRLEN inlen);
        int  (*verify)(pTHX_ void *key, const char *alg, STRLEN alglen,
                       const unsigned char *input, STRLEN inlen,
                       const unsigned char *sig, STRLEN siglen);

        /* primitives */
        SV  *(*sha256)(pTHX_ const unsigned char *in, STRLEN len);
        SV  *(*hmac_sha256)(pTHX_ const unsigned char *key, STRLEN keylen,
                            const unsigned char *in, STRLEN len);
        SV  *(*b64url)(pTHX_ const unsigned char *in, STRLEN len);
        SV  *(*b64url_decode)(pTHX_ const char *in, STRLEN len);
        int  (*ct_eq)(pTHX_ const unsigned char *a, STRLEN alen,
                      const unsigned char *b, STRLEN blen);
        SV  *(*random_bytes)(pTHX_ STRLEN n);
    } jws_abi;

The table is B<append-only>: new entries go at the end, JWS_ABI_VERSION
bumps, existing offsets never move. A consumer written against version
N keeps working against every later version.

=head2 Crypt::JWS::_abi_ptr

    my $iv = Crypt::JWS::_abi_ptr;

Returns the address of the process-wide C<jws_abi> table as an integer
(an C<IV>). A consumer calls this once at C<BOOT>, C<INT2PTR>s it to a
C<< const jws_abi * >>, and checks C<< ->version == JWS_ABI_VERSION >>
before using it. Not intended to be called from Perl for any other
purpose. C<Crypt::JWS::_abi_selftest> exercises the table end to end
and is what F<t/06-abi.t> runs.

=head2 Functions and ownership

Keys are opaque pointers. C<key_from_pem> parses a private or public
PEM (RSA and EC only); C<key_from_oct> wraps a shared secret for the
HS* algorithms; both return NULL on failure and everything they return
must eventually go through C<key_free>. C<key_is_private> reports
whether a signing operation is possible.

C<sign> takes the raw signing-input bytes (the consumer builds
C<b64url(header).b64url(payload)> itself, or signs arbitrary bytes for
non-JWS uses) and returns the signature bytes as an SV with a reference
count of one owned by the caller - C<sv_2mortal> it or
C<SvREFCNT_dec> when done - or NULL when the key type does not match
the algorithm family, the key is public, or OpenSSL fails. ES
signatures are returned in JOSE C<r||s> form. C<verify> returns 1 for a
valid signature and 0 for anything else, and never says why. The
key-type/algorithm cross-check applies to both: an oct key never
verifies an RS/ES token and vice versa.

Every SV-returning primitive follows the same ownership rule (+1,
caller frees). C<b64url_decode> returns NULL on invalid input;
C<random_bytes> croaks rather than degrade when the CSPRNG fails.

=head2 Example: signing detached bytes from a consumer

Vendor nothing - add Crypt::JWS via ExtUtils::Depends (above), resolve
the table at boot, then sign wherever needed:

    #include "jws_abi.h"   /* found via ExtUtils::Depends, not copied */

    static const jws_abi *JWS = NULL;

    MODULE = My::Consumer   PACKAGE = My::Consumer

    BOOT:
    {
        IV p = 0; dSP;
        eval_pv("require Crypt::JWS;", FALSE);
        PUSHMARK(SP); PUTBACK;
        if (call_pv("Crypt::JWS::_abi_ptr", G_SCALAR|G_EVAL) > 0) {
            SPAGAIN; p = POPi; PUTBACK;
        }
        if (p) {
            const jws_abi *a = INT2PTR(const jws_abi *, p);
            if (a && a->version == JWS_ABI_VERSION) JWS = a;
        }
        /* JWS == NULL => Crypt::JWS is absent or too old; croak at
         * first use, or disable the feature. */
    }

    # at boot, load the signing key once:
    #   void *key = JWS->key_from_pem(aTHX_ pem, pem_len);
    #
    # per operation:
    #   SV *sig = JWS->sign(aTHX_ key, "ES256", 5, input, input_len);
    #   ... use SvPVbyte(sig, len) ...  then SvREFCNT_dec(sig);
    #
    # at teardown:
    #   JWS->key_free(aTHX_ key);

=head1 SEE ALSO

L<Crypt::JWS::Key> - key import, generation, export, thumbprints

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
