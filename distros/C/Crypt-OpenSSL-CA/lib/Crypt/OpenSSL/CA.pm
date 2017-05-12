#!perl -w
# -*- coding: utf-8; -*-

use strict;
use warnings;

package Crypt::OpenSSL::CA;

our $VERSION = "0.24";
# Maintainer note: Inline::C doesn't like pre-releases (eg 0.21_01), which are not needed
# for PAUSE developer releases anyway (http://www.cpan.org/modules/04pause.html#developerreleases)

=head1 NAME

Crypt::OpenSSL::CA - The crypto parts of an X509v3 Certification Authority

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

    use Crypt::OpenSSL::CA;

    my $dn = Crypt::OpenSSL::CA::X509_NAME->new
            (C => "fr", CN => "test");

    my $privkey = Crypt::OpenSSL::CA::PrivateKey
         ->parse($pem_private_key, -password => "secret");
    my $pubkey = $privkey->get_public_key;

    my $x509 = Crypt::OpenSSL::CA::X509->new($pubkey);
    $x509->set_serial("0xdeadbeef");
    $x509->set_subject_DN($dn);
    $x509->set_issuer_DN($dn);
    $x509->set_extension("basicConstraints", "CA:TRUE",
                         -critical => 1);
    $x509->set_extension("subjectKeyIdentifier",
                         $pubkey->get_openssl_keyid);
    $x509->set_extension("authorityKeyIdentifier",
                         { keyid => $pubkey->get_openssl_keyid });
    my $pem = $x509->sign($privkey, "sha1");

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

This module performs the cryptographic operations necessary to issue
X509 certificates and certificate revocation lists (CRLs).  It is
implemented as a Perl wrapper around the popular OpenSSL library.

I<Crypt::OpenSSL::CA> is an essential building block to create an
X509v3 B<Certification Authority> or CA, a crucial part of an X509
Public Key Infrastructure (PKI). A CA is defined by RFC4210 and
friends (see L<Crypt::OpenSSL::CA::Resources>) as a piece of software
that can (among other things) issue and revoke X509v3 certificates.
To perform the necessary cryptographic operations, it needs a private
key that is kept secret (currently only RSA is supported).

Despite the name and unlike the C<openssl ca> command-line tool,
I<Crypt::OpenSSL::CA> is not designed as a full-fledged X509v3
Certification Authority (CA) in and of itself: some key features are
missing, most notably persistence (e.g. to remember issued and revoked
certificates between two CRL issuances) and security-policy based
screening of certificate requests.  I<Crypt::OpenSSL::CA> mostly does
``just the crypto'', and this is deliberate: OpenSSL's features such
as configuration file parsing, that are best implemented in Perl, have
been left out for maximum flexibility.

=head2 API Overview

The crypto in I<Crypt::OpenSSL::CA> is implemented using the OpenSSL
cryptographic library, which is lifted to Perl thanks to a bunch of
glue code in C and a lot of magic in L<Inline::C> and
L<Crypt::OpenSSL::CA::Inline::C>.

Most of said glue code is accessible as class and instance methods in
the ancillary classes such as L</Crypt::OpenSSL::CA::X509> and
L</Crypt::OpenSSL::CA::X509_CRL>; the parent namespace
I<Crypt::OpenSSL::CA> is basically empty.  Each of these ancillary
classes wrap around OpenSSL's ``object class'' with the same name
(e.g. L</Crypt::OpenSSL::CA::X509_NAME> corresponds to the
C<X509_NAME_foo> functions in C<libcrypto.so>).  OpenSSL concepts are
therefore made available in an elegant object-oriented API; moreover,
they are subjugated to Perl's automatic garbage collection, which
allows the programmer to stop worrying about that.  Additionally,
I<Crypt::OpenSSL::CA> provides some glue in Perl too, which is mostly
syntactic sugar to get a more Perlish API out of the C in OpenSSL.

Note that the OpenSSL-wrapping classes don't strive for completeness
of the exposed API; rather, they seek to export enough features to
make them simultaneously testable and useful for the purpose of
issuing X509 certificates and CRLs.  In particular,
I<Crypt::OpenSSL::CA> is currently not so good at parsing
already-existing cryptographic artifacts (However, L</PATCHES
WELCOME>, plus there are other modules on the CPAN that already do
that.)

=head2 Error Management

All functions and methods in this module, including XS code, throw
exceptions as if by L<perlfunc/die> if anything goes wrong.  The
resulting exception is either a plain string (in case of memory
exhaustion problems, incorrect arguments, and so on) or an exception
blessed in class I<Crypt::OpenSSL::CA::Error> with the following
structure:


  {
    -message => $message,
    -openssl => [
                  $openssl_error_1,
                  $openssl_error_2,
                  ...
                ]
  }

where C<$message> is a message by I<Crypt::OpenSSL::CA> and the
C<-openssl> list is the contents of OpenSSL's error stack at the time
when the exception was raised.

=begin internals

=head3 _sslcroak_callback (-message => $val)

=head3 _sslcroak_callback (-openssl => $val)

=head3 _sslcroak_callback ("DONE")

Callback that gets invoked one or several times whenever
L<Crypt::OpenSSL::CA::Inline::C/sslcroak> is run, in order to
implement L</Error Management>.  I<_sslcroak_callback> is expected to
accumulate the exception data in $@, but to not bless it until
C<<_sslcroak_callback("DONE")>> is called; in this way, I<_sslcroak>
will be able to tell that the sequence of callback invocations
terminated successfully.

A word of caution to hackers who wish to reimplement
I<_sslcroak_callback>, e.g. for testability purposes: if I<_sslcroak>
calls C<eval>, it will wipe out $@ which kind of defeats its purpose
(unless one is smart and sets $@ only at C<DONE> time); and if
I<_sslcroak_callback> throws an exception, the text thereof will end
up intermingled with the one from OpenSSL!

=cut

sub _sslcroak_callback {
    my ($key, $val) = @_;
    if ($key eq "-message") {
        $@ = { -message => $val };
    } elsif ( ($key eq "-openssl") && (ref($@) eq "HASH") ) {
        $@->{-openssl} ||= [];
        push(@{$@->{-openssl}}, $val);
    } elsif ( ($key eq "DONE") && (ref($@) eq "HASH") ) {
        bless($@, "Crypt::OpenSSL::CA::Error");
    } else {
        warn sprintf
            ("Bizarre callback state%s",
             (Data::Dumper->can("Dumper") ?
              " " . Data::Dumper::Dumper($@) : ""));
    }
}

=head3 Crypt::OpenSSL::CA::Error::stringify

String overload for displaying error messages in a friendly manner.
See L</Error management>.

=cut

{
    package Crypt::OpenSSL::CA::Error;
    use overload '""' => \&stringify;

    sub stringify {
        my ($E) = @_;
        return join("\n",
                    "Crypt::OpenSSL::CA: error: " . $E->{-message},
                    @{$E->{-openssl} || []});
    }
}

=end internals

=head1 Crypt::OpenSSL::CA::X509_NAME

This Perl class wraps around the X509_NAME_* functions of OpenSSL,
that deal with X500 DNs.  Unlike OpenSSL's X509_NAME,
I<Crypt::OpenSSL::CA::X509_NAME> objects are immutable: only the
constructor can alter them.

=cut

package Crypt::OpenSSL::CA::X509_NAME;
use Carp qw(croak);
use utf8 ();

use Crypt::OpenSSL::CA::Inline::C <<"X509_BASE";

#include <openssl/x509.h>

static
void DESTROY(SV* sv_self) {
    X509_NAME_free(perl_unwrap("${\__PACKAGE__}", X509_NAME *, sv_self));
}

X509_BASE

=head2 new ($dnkey1, $dnval1, ...)

Constructs and returns a new I<Crypt::OpenSSL::CA::X509_NAME> object;
implemented in terms of B<X509_NAME_add_entry_by_txt(3)>.  The RDN
elements are to be passed in the same order as they will appear in the
C<RDNSequence> ASN.1 object that will be constructed, that is, the
B<most-significant parts of the DN> (e.g. C<C>) must come B<first>.
Be warned that this is order is the I<reverse> of RFC4514-compliant
DNs such as those that appear in LDAP, as per section 2.1 of said
RFC4514.

Keys can be given either as uppercase short names (e.g. C<OU> - C<ou>
is not allowed), long names with the proper case
(C<organizationalUnitName>) or dotted-integer OIDs ("2.5.4.11").
Values are interpreted as strings.  Certain keys (especially
C<countryName>) limit the range of acceptable values.

All DN values will be converted to UTF-8 if needed, and the returned
DN string encodes all its RDN components as C<UTF8String>s regardless
of their value, as mandated by RFC3280 section 4.1.2.4.

I<new_utf8> does not support multiple AVAs in a single RDN.  If you
don't understand this sentence, consider yourself a lucky programmer.

See also L</get_subject_DN> and L</get_issuer_DN> for an alternative
way of constructing instances of this class.

=head2 new_utf8 ($dnkey1, $dnval1, ...)

Backward-compatible alias for L</new>.

=cut

sub new {
    my ($class, @args) = @_;
    croak("odd number of arguments required") if @args % 2;

    my $self = $class->_new;
    while(my ($k, $v) = splice(@args, 0, 2)) {
        utf8::upgrade($v);
        $self->_add_RDN_utf8($k, $v);
    }
    return $self;
}

sub new_utf8 { goto &new; }

use Crypt::OpenSSL::CA::Inline::C <<"MUTABLE_X509_NAME";

static
SV* _new(char* class) {
    X509_NAME *retval = X509_NAME_new();
    if (!retval) { croak("not enough memory for X509_NAME_new"); }
    return perl_wrap("${\__PACKAGE__}", retval);
}

static
void _add_RDN_utf8(SV* sv_self, SV* sv_key, SV* sv_val) {
    X509_NAME* self = perl_unwrap("${\__PACKAGE__}", X509_NAME *, sv_self);
    char* key = char0_value(sv_key);
    char* val = char0_value(sv_val);
    X509_NAME_ENTRY* tmpentry;

    if (! SvUTF8(sv_val)) {
        croak("Expected UTF8-encoded value");
    }

    /* use X509_NAME_ENTRY_create_by_txt to validate the contents of the
       field first, because as documented in
       X509_NAME_add_entry_by_txt(3ssl) there will be no such checks
       when using V_ASN1_UTF8STRING: */
    if (! (tmpentry = X509_NAME_ENTRY_create_by_txt
               (NULL, key, MBSTRING_UTF8,  (unsigned char*) val, -1)) ) {
         sslcroak("X509_NAME_ENTRY_create_by_txt failed for %s=%s",
                  key, val);
    }
    X509_NAME_ENTRY_free(tmpentry);

    if (! X509_NAME_add_entry_by_txt
                  (self, key, V_ASN1_UTF8STRING,
                  (unsigned char*) val, -1, -1, 0)) {
         sslcroak("X509_NAME_add_entry_by_txt failed for %s=%s", key, val);
    }
}
MUTABLE_X509_NAME

=head2 to_string ()

Returns a string representation of this DN object. Uses
B<X509_NAME_oneline(3)>.  The return value does not conform to any
standard; in particular it does B<not> comply with RFC4514, and
embedded Unicode characters will B<not> be dealt with elegantly.
I<to_string()> is therefore intended only for debugging.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"TO_STRING";

static
SV* to_string(SV* sv_self) {
    X509_NAME* self = perl_unwrap("${\__PACKAGE__}", X509_NAME *, sv_self);
    return openssl_string_to_SV(X509_NAME_oneline(self, NULL, 4096));
}

TO_STRING

=head2 to_asn1 ()

Returns an ASN.1 DER representation of this DN object, as a string of
bytes.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"TO_ASN1";

static
SV* to_asn1(SV* sv_self) {
    unsigned char* asn1buf = NULL;
    SV* retval = NULL;
    int length;
    X509_NAME* self = perl_unwrap("${\__PACKAGE__}", X509_NAME *, sv_self);
    length = i2d_X509_NAME(self, &asn1buf);
    if (length < 0) { croak("i2d_X509_NAME failed"); }
    retval = openssl_buf_to_SV((char *)asn1buf, length);
    SvUTF8_off(retval);
    return retval;
}

TO_ASN1


=head1 Crypt::OpenSSL::CA::PublicKey

This Perl class wraps around the public key abstraction of OpenSSL.
I<Crypt::OpenSSL::CA::PublicKey> objects are immutable.

=cut

package Crypt::OpenSSL::CA::PublicKey;

use Crypt::OpenSSL::CA::Inline::C <<"PUBLICKEY_BASE";
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/evp.h>
#include <openssl/x509.h>     /* For validate_SPKAC */
#include <openssl/x509v3.h>   /* For get_openssl_keyid() */
#include <openssl/objects.h>  /* For NID_subject_key_identifier
                                 in get_openssl_keyid() */

static
void DESTROY(SV* sv_self) {
    EVP_PKEY_free(perl_unwrap("${\__PACKAGE__}", EVP_PKEY *, sv_self));
}

PUBLICKEY_BASE

=head2 parse_RSA ($pemstring)

Parses an RSA public key from $pemstring and returns an
I<Crypt::OpenSSL::CA::PublicKey> instance.  See also
L</get_public_key> for an alternative way of creating instances of
this class.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"PARSE_RSA";

static
SV* parse_RSA(char *class, const char* pemkey) {
    BIO* keybio;
    RSA* pubkey;
    EVP_PKEY* retval;

    keybio = BIO_new_mem_buf((void *) pemkey, -1);
    if (keybio == NULL) {
        croak("BIO_new_mem_buf failed");
    }

    pubkey = PEM_read_bio_RSA_PUBKEY(keybio, NULL, NULL, NULL);
    BIO_free(keybio);
    if (pubkey == NULL) {
            sslcroak("unable to parse RSA public key");
    }

    retval = EVP_PKEY_new();
    if (! retval) {
        RSA_free(pubkey);
        croak("Not enough memory for EVP_PKEY_new");
    }

    if (! EVP_PKEY_assign_RSA(retval, pubkey)) {
        RSA_free(pubkey);
        EVP_PKEY_free(retval);
        sslcroak("EVP_PKEY_assign_RSA failed");
    }

    return perl_wrap("${\__PACKAGE__}", retval);
}

PARSE_RSA

=head2 validate_SPKAC ($spkacstring)

=head2 validate_PKCS10 ($pkcs10string)

Validates a L<Crypt::OpenSSL::CA::AlphabetSoup/CSR> of the respective
type and returns the public key as an object of class
L<Crypt::OpenSSL::CA::PublicKey> if the signature is correct.  Throws
an error if the signature is invalid.  I<validate_SPKAC($spkacstring)>
wants the ``naked'' Base64 string, without a leading C<SPKAC=> marker,
URI escapes, newlines or any such thing.

Note that those methods are in I<Crypt::OpenSSL::CA> only by virtue of
them requiring cryptographic operations, best implemented using
OpenSSL.  We definitely do B<not> want to emulate the request validity
checking features of C<openssl ca>, which are extremely inflexible and
that a full-fledged PKI built on top of I<Crypt::OpenSSL::CA> would
have to reimplement anyway.  If one wants to parse other details of
the SPKAC or PKCS#10 messages (including the challenge password if
present), one should use other means such as L<Convert::ASN1>; ditto
if one just wants to extract the public key and doesn't care about the
signature.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"VALIDATE";
static
SV* validate_SPKAC(char *class, const char* base64_spkac) {
    NETSCAPE_SPKI* spkac;
    EVP_PKEY* retval;

    if (! (spkac = NETSCAPE_SPKI_b64_decode(base64_spkac, -1)) ) {
        sslcroak("Unable to load Netscape SPKAC structure");
    }
    if (! (retval=NETSCAPE_SPKI_get_pubkey(spkac)) ) {
        NETSCAPE_SPKI_free(spkac);
        sslcroak("Unable to extract public key from SPKAC structure");
    }
    if (NETSCAPE_SPKI_verify(spkac, retval) < 0) {
        EVP_PKEY_free(retval);
        NETSCAPE_SPKI_free(spkac);
        sslcroak("SPKAC signature verification failed");
    }
    NETSCAPE_SPKI_free(spkac);
    return perl_wrap("${\__PACKAGE__}", retval);
}

static
SV* validate_PKCS10(char *class, const char* pem_pkcs10) {
    BIO* pkcs10bio;
    X509_REQ* req;
    EVP_PKEY* retval;
    int status;

    pkcs10bio = BIO_new_mem_buf((void *) pem_pkcs10, -1);
    if (pkcs10bio == NULL) {
        croak("BIO_new_mem_buf failed");
    }

    req = PEM_read_bio_X509_REQ(pkcs10bio, NULL, NULL, NULL);
    BIO_free(pkcs10bio);
    if (! req) { sslcroak("Error parsing PKCS#10 request"); }

    if (! (retval = X509_REQ_get_pubkey(req))) {
        X509_REQ_free(req);
        sslcroak("Error extracting public key from PKCS#10 request");
    }
    status = X509_REQ_verify(req, retval);
    X509_REQ_free(req);
    if (status < 0) {
        sslcroak("PKCS#10 signature verification problems");
    } else if (status == 0) {
        sslcroak("PKCS#10 signature does not match the certificate");
    }
    return perl_wrap("${\__PACKAGE__}", retval);
}
VALIDATE

=head2 to_PEM

Returns the contents of the public key as a PEM string.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"TO_PEM";

static
SV* to_PEM(SV* sv_self) {
    EVP_PKEY* self = perl_unwrap("${\__PACKAGE__}", EVP_PKEY *, sv_self);
    BIO* mem;
    int printstatus;

    if (! (mem = BIO_new(BIO_s_mem()))) {
        croak("Cannot allocate BIO");
    }
    if (self->type == EVP_PKEY_RSA) {
        printstatus = PEM_write_bio_RSA_PUBKEY(mem, self->pkey.rsa);
    } else if (self->type == EVP_PKEY_DSA) {
        printstatus = PEM_write_bio_DSA_PUBKEY(mem, self->pkey.dsa);
    } else {
        BIO_free(mem);
        croak("Unknown public key type %d", self->type);
    }
    printstatus = printstatus && ( BIO_write(mem, "\\0", 1) > 0 );
    if (! printstatus) {
        BIO_free(mem);
        sslcroak("Serializing public key failed");
    }
    return BIO_mem_to_SV(mem);
}

TO_PEM

=head2 get_modulus ()

Returns the modulus of this I<Crypt::OpenSSL::CA::PublicKey> instance,
assuming that it is an RSA or DSA key.  This is similar to the output
of C<openssl x509 -modulus>, except that the leading C<< Modulus= >>
identifier is trimmed and the returned string is not
newline-terminated.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"GET_MODULUS";

static
SV* get_modulus(SV* sv_self) {
    EVP_PKEY* self = perl_unwrap("${\__PACKAGE__}", EVP_PKEY *, sv_self);
    BIO* mem;
    SV* retval;
    int printstatus;

    if (! (mem = BIO_new(BIO_s_mem()))) {
        croak("Cannot allocate BIO");
    }

    if (self->type == EVP_PKEY_RSA) {
            printstatus = BN_print(mem,self->pkey.rsa->n);
    } else if (self->type == EVP_PKEY_DSA) {
            printstatus = BN_print(mem,self->pkey.rsa->n);
    } else {
            BIO_free(mem);
            croak("Unknown public key type %d", self->type);
    }

    printstatus = printstatus && ( BIO_write(mem, "\\0", 1) > 0 );
    if (! printstatus) {
        BIO_free(mem);
        sslcroak("Serializing modulus failed");
    }
    return BIO_mem_to_SV(mem);
}

GET_MODULUS

=head2 get_openssl_keyid ()

Returns a cryptographic hash over this public key, as OpenSSL's
C<subjectKeyIdentifier=hash> configuration directive to C<openssl ca>
would compute it for a certificate that contains this key.  The return
value is a string of colon-separated pairs of uppercase hex digits,
adequate e.g. for passing as the $value parameter to
L</set_extension>.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"GET_OPENSSL_KEYID";

static
SV* get_openssl_keyid(SV* sv_self) {
    EVP_PKEY* self = perl_unwrap("${\__PACKAGE__}", EVP_PKEY *, sv_self);
    X509* fakecert = NULL;
    X509V3_CTX ctx;
    ASN1_OCTET_STRING* hash = NULL;
    char* hash_hex = NULL;
    char* err = NULL;

    /* Find OpenSSL's "object class" that deals with subject
     * key identifiers: */
    const X509V3_EXT_METHOD* method = X509V3_EXT_get_nid(NID_subject_key_identifier);
    if (! method) {
        err = "X509V3_EXT_get_nid failed"; goto end;
    }

    /* Pass the public key as part of a fake certificate, itself
     * part of a mostly dummy X509V3_CTX, because that's what
     * X509V3_EXT_METHOD*'s want: */
    fakecert = X509_new();
    if (! fakecert) {
        err = "not enough memory for X509_new()"; goto end;
    }
    if (! X509_set_pubkey(fakecert, self)) {
        err = "X509_set_pubkey failed"; goto end;
    }
    X509V3_set_ctx(&ctx, NULL, fakecert, NULL, NULL, 0);

    /* Invoke the method */
    hash = (ASN1_OCTET_STRING*) method->s2i(method, &ctx, "hash");

    /* Convert the result to hex */
    hash_hex = i2s_ASN1_OCTET_STRING((X509V3_EXT_METHOD*) method, hash);
    if (! hash_hex) {
        err = "i2s_ASN1_OCTET_STRING failed"; goto end;
    }

end:

    if (fakecert) { X509_free(fakecert); }
    /* method seems to be statically allocated (no X509V3_EXT_METHOD_free
       in sight) */
    /* ctx is on the stack */
    if (hash)     { ASN1_OCTET_STRING_free(hash); }
    /* hash_hex cannot be set (else we wouldn't have an error) */

    if (err) {
        sslcroak(err);
    }
    return openssl_string_to_SV(hash_hex);
}

GET_OPENSSL_KEYID

=head1 Crypt::OpenSSL::CA::PrivateKey

This Perl class wraps around the private key abstraction of OpenSSL.
I<Crypt::OpenSSL::CA::PrivateKey> objects are immutable.

=cut

package Crypt::OpenSSL::CA::PrivateKey;
use Carp qw(croak);

use Crypt::OpenSSL::CA::Inline::C <<"PRIVATEKEY_BASE";
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/engine.h>
#include <openssl/ui.h>
#include <openssl/evp.h>

static
void DESTROY(SV* sv_self) {
    EVP_PKEY_free(perl_unwrap("${\__PACKAGE__}", EVP_PKEY *, sv_self));
}

PRIVATEKEY_BASE

=head2 parse ($pemkey, %named_options)

Parses a private key $pemkey and returns an instance of
I<Crypt::OpenSSL::CA::PrivateKey>.  Available named options are:

=over

=item I<< -password => $password >>

Tells that $pemkey is a software key encrypted with password
$password.

=back

Only software keys are supported for now (see L</TODO> about engine
support).

=cut

sub parse {
    croak("incorrect number of arguments to parse()")
        if (@_ % 2);
    my ($self, $keytext, %options) = @_;
    if (defined(my $pass = $options{-password})) {
        return $self->_parse($keytext, $pass, undef, undef);
    } else {
        return $self->_parse($keytext, undef, undef, undef);
    }
}

=begin internals

=head2 _parse ($pemkey, $password, $engineobj, $use_engine_format)

The XS counterpart of L</parse>, sans the syntactic sugar. Parses a
PEM-encoded private key and returns an instance of
I<Crypt::OpenSSL::CA::PrivateKey> wrapping a OpenSSL C<EVP_PKEY *>
handle.  All four arguments are mandatory. I<$engineobj> and
I<$use_engine_format> are B<UNIMPLEMENTED> and should both be passed
as undef.

=end internals

=cut

use Crypt::OpenSSL::CA::Inline::C <<"_PARSE";
/* Returns a password stored in memory.  Callback invoked by
   PEM_read_bio_PrivateKey() when parsing a password-protected
   software private key */
static int gimme_password(char *buf, int bufsiz, int __unused_verify,
    void *cb_data) {
    int pwlength;
    const char *password = (const char *) cb_data;
    if (!password) { return -1; }
    pwlength = strlen(password);
    if (pwlength > bufsiz) { pwlength = bufsiz; }
    memcpy(buf, password, pwlength);
    return pwlength;
}

/* Ditto, but using the ui_method API.  Callback invoked by
   ENGINE_load_private_key when parsing an engine-based
   private key */
/* UNIMPLEMENTED */

static
SV* _parse(char *class, const char* pemkey, SV* svpass,
         SV* engine, SV* parse_using_engine_p) {
    /* UNIMPLEMENTED: engine and parse_using_engine don't work */
    BIO* keybio = NULL;
    EVP_PKEY* pkey = NULL;
    ENGINE* e;
    char* pass = NULL;

    if (SvOK(svpass)) { pass = char0_value(svpass); }

    if (SvTRUE(parse_using_engine_p)) {
        static UI_METHOD *ui_method = NULL;

        croak("UNIMPLEMENTED, UNTESTED");

        if (! (engine &&
               (e = perl_unwrap("Crypt::OpenSSL::CA::ENGINE",
                                ENGINE*, engine)))) {
              croak("no engine specified");
        }

        /* UNIMPLEMENTED: must parse from memory not file; must coerce
        that wonky ui_method stuff into * passing C<pass> to the
        engine */
        /* pkey = (EVP_PKEY *)ENGINE_load_private_key
            (e, file, ui_method, (void *) pass); */
    } else {
            keybio = BIO_new_mem_buf((void *) pemkey, -1);
            if (keybio == NULL) {
                croak("BIO_new failed");
            }
            pkey=PEM_read_bio_PrivateKey(keybio, NULL,
                                         gimme_password, (void *) pass);
    }
    if (keybio != NULL) BIO_free(keybio);
    if (pkey == NULL) {
            sslcroak("unable to parse private key");
    }
    return perl_wrap("${\__PACKAGE__}", pkey);
}
_PARSE

=head2 get_public_key ()

Returns the public key associated with this
I<Crypt::OpenSSL::CA::PrivateKey> instance, as an
L</Crypt::OpenSSL::CA::PublicKey> object.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"GET_PUBLIC_KEY";

#if OPENSSL_VERSION_NUMBER < 0x00908000
#define CONST_IF_D2I_PUBKEY_WANTS_ONE
#else
#define CONST_IF_D2I_PUBKEY_WANTS_ONE const
#endif

static
SV* get_public_key(SV* sv_self) {
    EVP_PKEY* self = perl_unwrap("${\__PACKAGE__}", EVP_PKEY *, sv_self);
    EVP_PKEY* retval = NULL;
    unsigned char* asn1buf = NULL;
    CONST_IF_D2I_PUBKEY_WANTS_ONE unsigned char* asn1buf_copy;
    int size;

    /* This calling idiom requires OpenSSL 0.9.7 */
    size = i2d_PUBKEY(self, &asn1buf);
    if (size < 0) { sslcroak("i2d_PUBKEY failed"); }

    /* d2i_PUBKEY advances the pointer that is passed to it,
       so we need to make a copy: */
    asn1buf_copy = asn1buf;
    d2i_PUBKEY(&retval, &asn1buf_copy, size);
    OPENSSL_free(asn1buf);
    if (! retval) {
        sslcroak("d2i_PUBKEY failed");
    }
    return perl_wrap("Crypt::OpenSSL::CA::PublicKey", retval);
}

GET_PUBLIC_KEY

=begin OBSOLETE

=head2 get_RSA_modulus ()

For compatibility with 0.03. Use ->get_public_key->get_modulus
instead.

=end OBSOLETE

=cut

sub get_RSA_modulus { shift->get_public_key->get_modulus }

=begin UNIMPLEMENTED

=head1 Crypt::OpenSSL::CA::ENGINE

This package models the C<ENGINE_*> functions of OpenSSL.

=cut

package Crypt::OpenSSL::CA::ENGINE;

#use Crypt::OpenSSL::CA::Inline::C <<"ENGINE_BASE";
(undef) = <<"ENGINE_BASE";
#include <openssl/engine.h>

static
void DESTROY(SV* sv_self) {
        ENGINE_free(perl_unwrap("${\__PACKAGE__}", ENGINE *, sv_self));
}

ENGINE_BASE

=head2 setup_simple ($engine, $debugp)

Starts engine $engine (a string), optionally enabling debug if $debugp
(an integer) is true.  Returns a structural reference to same (see
B<engine(3)> to find out what that means).

The code is lifted from OpenSSL's C<setup_engine()> in C<apps.c>, which despite
falling short from C<engine.c> feature-wise (hence the name, I<setup_simple>)
proves sufficient in practice to have the C</usr/bin/openssl> command-line tool
perform all relevant RSA operations with a variety of
L<Crypt::OpenSSL::CA::AlphabetSoup/HSM>s.  Therefore, in spite of not having
tested it due to lack of appropriate hardware, I am confident that
I<Crypt::OpenSSL::CA> can be make to work with the hardware OpenSSL engines with
relatively little fuss.

=cut

#use Crypt::OpenSSL::CA::Inline::C <<"ENGINE_CODE";
(undef) = <<"ENGINE_CODE";
static
SV* setup_simple(const char *engine, int debug) {
    ENGINE *e = NULL;

    if (! engine) { croak("Expected engine name"); }

    if(strcmp(engine, "auto") == 0) {
            croak("engine \\"auto\\" is not supported.");
    }
    if((e = ENGINE_by_id(engine)) == NULL
       && (e = try_load_engine(err, engine, debug)) == NULL) {
            croak("invalid engine \\"%s\\", engine);
    }
    if (debug) {
            ENGINE_ctrl(e, ENGINE_CTRL_SET_LOGSTREAM,
                    0, err, 0);
    }
    ENGINE_ctrl_cmd(e, "SET_USER_INTERFACE", 0, ui_method, 0, 1);
    if(!ENGINE_set_default(e, ENGINE_METHOD_ALL)) {
            ENGINE_free(e);
            croak("can't use that engine");
    }

    return perl_wrap("${\__PACKAGE__}", e);
}

ENGINE_CODE

=end UNIMPLEMENTED

=begin internals

=head1 Crypt::OpenSSL::CA::CONF

A wrapper around an OpenSSL C<CONF *> data structure that contains the
OpenSSL configuration data.  Used by L</add_extension> and friends.

This POD is not made visible in the man pages (for now), as
L</add_extension> totally shadows the use of this class.

=cut

package Crypt::OpenSSL::CA::CONF;

use Crypt::OpenSSL::CA::Inline::C <<"CONF_BASE";
#include <openssl/conf.h>
/* (Sigh) There appears to be no public way of filling out a CONF*
   structure, except using the contents of a config file (in memory
   or on disk): */
#include <openssl/conf_api.h>
#include <string.h>           /* for strlen */

static
void DESTROY(SV* sv_self) {
    NCONF_free(perl_unwrap("${\__PACKAGE__}", CONF *, sv_self));
}

CONF_BASE

=head2 new ($confighash)

Creates the configuration file data structure.  C<$confighash>
parameter is a reference to a hash of hashes; the first-level keys are
section names, and the second-level keys are parameter names.  Returns
an immutable object of class I<Crypt::OpenSSL::CA::CONF>.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"NEW";
static
SV* new(SV* class, SV* configref) {
    CONF* self;
    HV* hv_config;
    SV* sv_sectionref;
    HV* hv_section;
    CONF_VALUE* section;
    char* sectionname;
    char* key;
    SV* sv_value;
    CONF_VALUE* value_struct;
    char* value;
    I32 unused;

    if (! (self = NCONF_new(NULL))) {
        croak("NCONF_new failed");
    }

    if (! (_CONF_new_data(self))) {
        croak("_CONF_new_data failed");
    }

    if (! (SvOK(configref) && SvROK(configref) &&
           SvTYPE(SvRV(configref)) == SVt_PVHV)) {
        NCONF_free(self);
        croak("Incorrect data structure for configuration object");
    }
    hv_iterinit(hv_config = (HV*) SvRV(configref));
    while( (sv_sectionref =
            hv_iternextsv(hv_config, &sectionname, &unused)) ) {
        section = _CONF_new_section(self, sectionname);
        if (! section) {
            NCONF_free(self);
            sslcroak("_CONF_new_section failed");
        }

        if (! (SvOK(sv_sectionref) && SvROK(sv_sectionref) &&
               SvTYPE(SvRV(sv_sectionref)) == SVt_PVHV)) {
            NCONF_free(self);
            croak("Incorrect data structure for configuration section %s",
                  sectionname);
        }
        hv_iterinit(hv_section = (HV*) SvRV(sv_sectionref));
        while( (sv_value =
                hv_iternextsv(hv_section, &key, &unused)) ) {
            value = char0_value(sv_value);
            if (! strlen(value)) {
                NCONF_free(self);
                croak("bad structure: hash contains %s",
                      (SvPOK(sv_value) ? "a null-string value" :
                       "an undef value"));
            }

        if (!(value_struct =
                  (CONF_VALUE *)OPENSSL_malloc(sizeof(CONF_VALUE)))) {
                NCONF_free(self);
                croak("OPENSSL_malloc failed");
            }
            memset(value_struct, 0, sizeof(CONF_VALUE));
            if (! (value_struct->name = BUF_strdup(key))) {
                NCONF_free(self);
                croak("BUF_strdup()ing the key failed");
            }
            if (! (value_struct->value = BUF_strdup(value))) {
                NCONF_free(self);
                croak("BUF_strdup()ing the value failed");
            }
            _CONF_add_string(self, section, value_struct);
        }
    }

    return perl_wrap("${\__PACKAGE__}", self);
}
NEW

=head2 get_string ($section, $key)

Calls OpenSSL's C<CONF_get_string>.  Throws an exception as described
in L</Error Management> if the configuration entry is not found.
Unused in I<Crypt::OpenSSL::CA>, for test purposes only.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"GET_STRING";

static
SV* get_string(SV* sv_self, char* section, char* key) {
    CONF* self = perl_unwrap("${\__PACKAGE__}", CONF *, sv_self);
    char* retval;

    retval = NCONF_get_string(self, section, key);
    if (! retval) { sslcroak("NCONF_get_string failed"); }
    return newSVpv(retval, 0);
}

GET_STRING

=head1 Crypt::OpenSSL::CA::X509V3_EXT

Instances of this class model OpenSSL's C<X509V3_EXT *> extensions
just before they get added to a certificate or a CRL by
L</add_extension>.  They are immutable.

Like L</Crypt::OpenSSL::CA::CONF>, this POD section is not made
visible in the man pages (for now), as L</add_extension> totally
shadows the use of this class.  Furthermore, the API of this class
stinks from a Perl's hacker point of view (mainly because of the
positional parameters).  Granted, the only point of this class is to
have several constructors, so as to introduce polymorphism into
->_do_add_extension without overflowing its argument list in an even
more inelegant fashion.

=cut

package Crypt::OpenSSL::CA::X509V3_EXT;

use Crypt::OpenSSL::CA::Inline::C <<"X509V3_EXT_BASE";
#include <openssl/x509v3.h>

static
void DESTROY(SV* sv_self) {
    X509_EXTENSION_free(perl_unwrap("${\__PACKAGE__}",
                                    X509_EXTENSION *, sv_self));
}

X509V3_EXT_BASE

=head2 new_from_X509V3_EXT_METHOD ($nid, $value, $CONF)

Creates and returns an extension using OpenSSL's I<X509V3_EXT_METHOD>
mechanism, which is summarily described in
L<Crypt::OpenSSL::CA::Resources/openssl.txt>.  $nid is the NID of the
extension type to add, as returned by L</extension_by_name>.  $value
is the string value as it would be found in OpenSSL's configuration
file under the entry that defines this extension
(e.g. "critical;CA:FALSE").  $CONF is an instance of
L</Crypt::OpenSSL::CA::CONF> that provides additional configuration
for complex X509v3 extensions.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"NEW_FROM_X509V3_EXT_METHOD";
static
SV* new_from_X509V3_EXT_METHOD(SV* class, int nid, char* value, SV* sv_config) {
    X509V3_CTX ctx;
    X509_EXTENSION* self;
    CONF* config = perl_unwrap("Crypt::OpenSSL::CA::CONF",
                                CONF *, sv_config);

    if (! nid) { croak("Unknown extension specified"); }
    if (! value) { croak("No value specified"); }

    X509V3_set_ctx(&ctx, NULL, NULL, NULL, NULL, 0);
    X509V3_set_nconf(&ctx, config);
    self = X509V3_EXT_nconf_nid(config, &ctx, nid, value);
    if (!self) { sslcroak("X509V3_EXT_conf_nid failed"); }

    return perl_wrap("${\__PACKAGE__}", self);
}

NEW_FROM_X509V3_EXT_METHOD

=head2 new_authorityKeyIdentifier (critical => $critical,
          keyid => $keyid, issuer => $issuerobj,
          serial => $serial_hexstring)

Creates and returns an X509V3 authorityKeyIdentifier extension as per
RFC3280 section 4.2.1.1, with the keyid set to $keyid (if not undef)
and the issuer and serial set to $issuer and $serial, respectively (if
both are not undef).  This extension is adequate both for certificates
and CRLs.  Oddly enough, such a construct is not possible using
L</new_from_X509V3_EXT_METHOD>: OpenSSL does not support storing a
literal value in the configuration file for C<authorityKeyIdentifier>,
it only supports copying it from the CA certificate (whereas we don't
want to insist on the user of I<Crypt::OpenSSL::CA> having said CA
certificate at hand).

$critical is a boolean indicating whether the extension should be
marked critical.  $keyid (if defined) is a string of colon-separated
pairs of uppercase hex digits typically obtained using
L</get_subject_keyid> or L</get_openssl_keyid>.  $issuerobj (if
defined) is an L</Crypt::OpenSSL::CA::X509_NAME> object.
$serial_hexstring (if defined) is a scalar containing a lowercase,
hexadecimal string that starts with "0x".

Note that identifying the authority key by issuer name and serial
number (that is, passing non-undef values for $issuerobj and
$serial_hexstring) is frowned upon in
L<Crypt::OpenSSL::CA::Resources/X509 Style Guide>.

=cut

{
    my $fake_pubkey;

    sub new_authorityKeyIdentifier {
        $fake_pubkey ||=
            Crypt::OpenSSL::CA::PublicKey->parse_RSA(<<"RSA_32BIT");
-----BEGIN PUBLIC KEY-----
MCAwDQYJKoZIhvcNAQEBBQADDwAwDAIFAM7azvECAwEAAQ==
-----END PUBLIC KEY-----
RSA_32BIT

        my ($class, %opts) = @_;

        my $fakecert = Crypt::OpenSSL::CA::X509->new($fake_pubkey);
        my $wants_serial_and_issuer =
            ($opts{serial} && $opts{issuer}) ? 1 : 0;
        if ($wants_serial_and_issuer) {
            $fakecert->set_serial($opts{serial});
            $fakecert->set_issuer_DN($opts{issuer});
        }
        if ($opts{keyid}) {
            $fakecert->add_extension(subjectKeyIdentifier => $opts{keyid});
        }

        return $class->_new_authorityKeyIdentifier_from_fake_cert
            ($fakecert, ($opts{critical} ? 1 : 0),
             $wants_serial_and_issuer);
    }
}

=head2 _new_authorityKeyIdentifier_from_fake_cert
             ($fakecert, $is_critical, $wants_serial_and_issuer)

Does the job of L</new_authorityKeyIdentifier>: creates an
C<authorityKeyIdentifier> extension by extracting the keyid, serial
and issuer information from $fakecert, as OpenSSL would.  $fakecert is
an L</Crypt::OpenSSL::CA::X509> object that mimics the issuer of the
certificate with which the returned extension will be fitted; it is
typcally created on the spot by I<new_authorityKeyIdentifier()>, and
may be almost completely bogus, as all its fields except the
aforementioned three are ignored.  $is_critical is 1 or 0, depending
on whether the extension should be made critical.
$wants_serial_and_issuer is 1 or 0, depending on whether the C<issuer>
and C<serial> authority key identifier information should be scavenged
from $fakecert (by contrast,
I<_new_authorityKeyIdentifier_from_fake_cert> will always attempt to
duplicate $fakecert's C<subjectKeyIdentifier>, so if you don't want
one in the returned extension, simply don't put it there).

This supremely baroque kludge is needed because creating an
authorityKeyIdentifier X509_EXTENSION ``by hand'' with OpenSSL is
nothing short of impossible: the AUTHORITY_KEYID ASN.1 structure,
which would be the ASN.1 value of the extension, is not exported by
OpenSSL.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"_NEW_AUTHORITYKEYIDENTIFIER_ETC";
static
SV* _new_authorityKeyIdentifier_from_fake_cert(SV* class, SV* fakecert_sv,
                int is_critical, int wants_serial_and_issuer) {
    X509V3_CTX ctx;
    X509* fakecert = perl_unwrap("Crypt::OpenSSL::CA::X509",
                                 X509 *, fakecert_sv);
    X509_EXTENSION* self;

    X509V3_set_ctx_nodb(&ctx);
    X509V3_set_ctx(&ctx, fakecert, fakecert, NULL, NULL, 0);

    self = X509V3_EXT_nconf_nid(NULL, &ctx, NID_authority_key_identifier,
            (wants_serial_and_issuer ? "keyid,issuer:always" : "keyid"));
    if (!self) {
        sslcroak("failed to copy the key identifier as a new extension");
    }
    X509_EXTENSION_set_critical(self, is_critical ? 1 : 0);
    return perl_wrap("${\__PACKAGE__}", self);
}
_NEW_AUTHORITYKEYIDENTIFIER_ETC

=head2 new_CRL_serial ($critical, $oid, $serial)

This constructor implements the C<crlNumber> and C<deltaCRLIndicator>
CRL extensions as described in L</Crypt::OpenSSL::CA::X509_CRL>.
$critical is the criticality flag, as integer (to be interpreted as a
Boolean).  $oid is the extension's OID, as a dot-separated sequence of
decimal integers.  $serial is a serial number with the same syntax as
described in L</set_serial>.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"NEW_CRL_SERIAL";
static
SV* new_CRL_serial(char* class, int critical, char* oidtxt, char* value) {
    int nid;
    X509_EXTENSION* self;
    ASN1_INTEGER* serial;

    /* Oddly enough, the NIDs for crlNumber and deltaCRLIndicator are
       known to OpenSSL as of 2004 (if the copyright header of
       crypto/x509v3/v3_int.c is to be trusted), and there is support
       in "openssl ca" for emitting CRL numbers (as mandated by
       RFC3280); yet these extensions still aren't fully integrated
       with the CONF stuff. */
    if (! strcmp(oidtxt, "2.5.29.20")) { /* crlNumber */
        nid = NID_crl_number;
    } else if (! strcmp(oidtxt, "2.5.29.27")) { /* deltaCRLIndicator */
        nid = NID_delta_crl;
    } else {
        croak("Unknown serial-like CRL extension %s", oidtxt);
    }

    serial = parse_serial_or_croak(value);
    self = X509V3_EXT_i2d(nid, critical, serial);
    ASN1_INTEGER_free(serial);
    if (! self) { sslcroak("X509V3_EXT_i2d failed"); }
    return perl_wrap("${\__PACKAGE__}", self);
}
NEW_CRL_SERIAL

=head2 new_freshestCRL ($value, $CONF)

This constructor implements the C<freshestCRL> CRL extension, as
described in L</Crypt::OpenSSL::CA::X509_CRL>. The parameters
C<$value> and C<$CONF> work the same as in
L</new_from_X509V3_EXT_METHOD>, including the criticality-in-$value
trick.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"NEW_FRESHESTCRL";
static
SV* new_freshestCRL(char* class, char* value, SV* sv_config) {
    X509V3_CTX ctx;
    X509_EXTENSION* self;
    CONF* config = perl_unwrap("Crypt::OpenSSL::CA::CONF",
                                CONF *, sv_config);
    static int nid_freshest_crl = 0;

    if (! value) { croak("No value specified"); }

    if (! nid_freshest_crl && ! (nid_freshest_crl = OBJ_txt2nid("freshestCRL"))) {
        nid_freshest_crl = OBJ_create("2.5.29.46", "freshestCRL",
                                      "Delta CRL distribution points");
    }

    X509V3_set_ctx(&ctx, NULL, NULL, NULL, NULL, 0);
    X509V3_set_nconf(&ctx, config);
    self = X509V3_EXT_nconf_nid
             (config, &ctx, NID_crl_distribution_points, value);
    if (!self) { sslcroak("X509V3_EXT_conf_nid failed"); }
    self->object = OBJ_nid2obj(nid_freshest_crl);
    return perl_wrap("${\__PACKAGE__}", self);
}

NEW_FRESHESTCRL

=end internals

=head1 Crypt::OpenSSL::CA::X509

This Perl class wraps around the X509 certificate creation routines of
OpenSSL.  I<Crypt::OpenSSL::CA::X509> objects are mutable; they
typically get constructed piecemeal, and signed once at the end with
L</sign>.

There is also limited support in this class for parsing certificates
using L</parse> and various read accessors, but only insofar as it
helps I<Crypt::OpenSSL::CA> be feature-compatible with OpenSSL's
command-line CA.  Namely, I<Crypt::OpenSSL::CA::X509> is currently
only able to extract the information that customarily gets copied over
from the CA's own certificate to the certificates it issues: the DN
(with L</get_subject_DN> on the CA's certificate), the serial number
(with L</get_serial>) and the public key identifier (with
L</get_subject_keyid>).  Patches are of course welcome, but TIMTOWTDI:
please consider using a dedicated ASN.1 parser such as
L<Convert::ASN1> or L<Crypt::X509> instead.

=cut

package Crypt::OpenSSL::CA::X509;
use Carp qw(croak);

use Crypt::OpenSSL::CA::Inline::C <<"X509_BASE";
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/evp.h> /* For EVP_get_digestbyname() */
#include <openssl/bn.h>  /* For BN_hex2bn in set_serial() */
static
void DESTROY(SV* sv_self) {
    X509_free(perl_unwrap("${\__PACKAGE__}", X509 *, sv_self));
}
X509_BASE

=head2 Support for OpenSSL-style extensions

L</set_extension> and L</add_extension> work with OpenSSL's
I<X509V3_EXT_METHOD> mechanism, which is summarily described in
L<Crypt::OpenSSL::CA::Resources/openssl.txt>.  This means that most
X509v3 extensions that can be set through OpenSSL's configuration file
can be passed to this module as Perl strings in exactly the same way;
see L</set_extension> for details.

=head2 Constructors and Methods

=head3 new ($pubkey)

Create an empty certificate shell waiting to be signed for public key
C<$pubkey>, an instance of L</Crypt::OpenSSL::CA::PublicKey>.  All
mandatory values in an X509 certificate are set to a dummy default
value, which the caller will probably want to alter using the various
I<set_*> methods in this class. Returns an instance of the class
I<Crypt::OpenSSL::CA::X509>, wrapping around an OpenSSL C<X509 *>
handle.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"NEW";
static
SV* new(char* class, SV* sv_pubkey) {
    X509* self;
    EVP_PKEY* pubkey = perl_unwrap("Crypt::OpenSSL::CA::PublicKey",
                                   EVP_PKEY *, sv_pubkey);
    char* err;

    self = X509_new();
    if (! self) { err = "not enough memory for X509_new"; goto error; }
    if (! X509_set_version(self, 2))
        { err = "X509_set_version failed"; goto error; }
    if (! X509_set_pubkey(self, pubkey))
        { err = "X509_set_pubkey failed"; goto error; }
    if (! ASN1_INTEGER_set(X509_get_serialNumber(self), 1))
        { err = "ASN1_INTEGER_set failed"; goto error; }
    if (! ASN1_TIME_set(X509_get_notBefore(self), 0))
        { err = "ASN1_TIME_set failed for notBefore"; goto error; }
    if (! ASN1_TIME_set(X509_get_notAfter(self), 0))
        { err = "ASN1_TIME_set failed for notAfter"; goto error; }

    return perl_wrap("${\__PACKAGE__}", self);

 error:
    if (self) { X509_free(self); }
    sslcroak(err);
    return NULL; // Not reached
}
NEW

=head3 parse ($pemcert)

Parses a PEM-encoded X509 certificate and returns an instance of
I<Crypt::OpenSSL::CA::X509> that already has a number of fields set.
Despite this, the returned object can be L</sign>ed anew if one wants.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"PARSE";
static
SV* parse(char *class, const char* pemcert) {
    BIO* keybio = NULL;
    X509* retval = NULL;

    keybio = BIO_new_mem_buf((void *) pemcert, -1);
    if (keybio == NULL) {
        croak("BIO_new failed");
    }
    retval = PEM_read_bio_X509(keybio, NULL, NULL, NULL);
    BIO_free(keybio);

    if (retval == NULL) {
            sslcroak("unable to parse certificate");
    }
    return perl_wrap("${\__PACKAGE__}", retval);
}
PARSE

=head3 verify ($pubkey)

Verifies that this certificate is validly signed by $pubkey, an
instance of L</Crypt::OpenSSL::CA::PublicKey>, and throws an exception
if not.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"VERIFY";
static
int verify(SV* sv_self, SV* sv_pubkey) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    EVP_PKEY* pubkey = perl_unwrap("Crypt::OpenSSL::CA::PublicKey",
                                   EVP_PKEY *, sv_pubkey);
    int result;

    result = X509_verify(self, pubkey);

    if (result > 0) { return result; }
    sslcroak("Certificate verify failed");
    return -1; /* Not reached */
}
VERIFY

=head3 get_public_key ()

Returns an instance of L</Crypt::OpenSSL::CA::PublicKey> that
corresponds to the RSA or DSA public key in this certificate.
Memory-management wise, this performs a copy of the underlying
C<EVP_PKEY *> structure; therefore it is safe to destroy this
certificate object afterwards and keep only the returned public key.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"GET_PUBLIC_KEY";
static
SV* get_public_key(SV* sv_self) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    EVP_PKEY* pkey = X509_get_pubkey(self);
    if (! pkey) { sslcroak("Huh, no public key in this certificate?!"); }

    return perl_wrap("Crypt::OpenSSL::CA::PublicKey", pkey);
}
GET_PUBLIC_KEY

=head3 get_subject_DN ()

=head3 get_issuer_DN ()

Returns the subject DN (resp. issuer DN) of this
I<Crypt::OpenSSL::CA::X509> instance, as an
L</Crypt::OpenSSL::CA::X509_NAME> instance.  Memory-management wise,
this performs a copy of the underlying C<X509_NAME *> structure;
therefore it is safe to destroy this certificate object afterwards and
keep only the returned DN.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"GET_DN";
static
SV* get_subject_DN(SV* sv_self) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    X509_NAME* name = X509_get_subject_name(self);

    if (! name) { sslcroak("Huh, no subject name in certificate?!"); }

    name = X509_NAME_dup(name);
    if (! name) { croak("Not enough memory for get_subject_DN"); }

    return perl_wrap("Crypt::OpenSSL::CA::X509_NAME", name);
}

static
SV* get_issuer_DN(SV* sv_self) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    X509_NAME* name = X509_get_issuer_name(self);

    if (! name) { sslcroak("Huh, no issuer name in certificate?!"); }

    name = X509_NAME_dup(name);
    if (! name) { croak("Not enough memory for get_issuer_DN"); }

    return perl_wrap("Crypt::OpenSSL::CA::X509_NAME", name);
}
GET_DN


=head3 set_subject_DN ($dn_object)

=head3 set_issuer_DN ($dn_object)

Sets the subject and issuer DNs from L</Crypt::OpenSSL::CA::X509_NAME>
objects.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"SET_DN";
static
void set_subject_DN(SV* sv_self, SV* dn_object) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    X509_NAME* dn = perl_unwrap("Crypt::OpenSSL::CA::X509_NAME",
                                X509_NAME *, dn_object);
    if (! X509_set_subject_name(self, dn)) {
        sslcroak("X509_set_subject_name failed");
    }
}

static
void set_issuer_DN(SV* sv_self, SV* dn_object) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    X509_NAME* dn = perl_unwrap("Crypt::OpenSSL::CA::X509_NAME",
                                X509_NAME *, dn_object);
    if (! X509_set_issuer_name(self, dn)) {
        sslcroak("X509_set_issuer_name failed");
    }
}

SET_DN

=head3 get_subject_keyid ()

Returns the contents of the C<subjectKeyIdentifier> field, if present,
as a string of colon-separated pairs of uppercase hex digits.  If no
such extension is available, returns undef.  Depending on the whims of
the particular CA that signed this certificate, this may or may not be
the same as C<< $self->get_public_key->get_openssl_keyid >>.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"GET_SUBJECT_KEYID";
static
SV* get_subject_keyid(SV* sv_self) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    X509_EXTENSION *ext;
    ASN1_OCTET_STRING *ikeyid;
    char* retval;
    int i;

    i = X509_get_ext_by_NID(self, NID_subject_key_identifier, -1);
    if (i < 0) {
        return newSVsv(&PL_sv_undef);
    }
    if (! ((ext = X509_get_ext(self, i)) &&
           (ikeyid = X509V3_EXT_d2i(ext))) ) {
        sslcroak("Failed extracting subject keyID from certificate");
        return NULL; /* Not reached */
    }
    retval = i2s_ASN1_OCTET_STRING(NULL, ikeyid);
    ASN1_OCTET_STRING_free(ikeyid);
    if (! retval) { croak("Converting to hex failed"); }
    return openssl_string_to_SV(retval);
}

GET_SUBJECT_KEYID

=head3 get_serial ()

Returns the serial number as a scalar containing a lowercase,
hexadecimal string that starts with "0x".

=head3 set_serial ($serial_hexstring)

Sets the serial number to C<$serial_hexstring>, which must be a scalar
containing a lowercase, hexadecimal string that starts with "0x".

=cut

use Crypt::OpenSSL::CA::Inline::C <<"GET_SET_SERIAL";
static
SV* get_serial(SV* sv_self) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    ASN1_INTEGER* serial_asn1;
    BIO* mem = BIO_new(BIO_s_mem());
    int status = 1;
    int i;

    if (! mem) {
        croak("Cannot allocate BIO");
    }

    /* Code inspired from X509_print_ex in OpenSSL's sources */
    if (! (serial_asn1 = X509_get_serialNumber(self)) ) {
        BIO_free(mem);
        sslcroak("X509_get_serialNumber failed");
    }
    if (!serial_asn1->type == V_ASN1_NEG_INTEGER) {
        status = status && ( BIO_puts(mem, "-") > 0 );
    }
    status = status && ( BIO_puts(mem, "0x") > 0 );
    for (i=0; i<serial_asn1->length; i++) {
        status = status &&
            (BIO_printf(mem, "%02x", serial_asn1->data[i]) > 0);
    }
    status = status && ( BIO_write(mem, "\\0", 1) > 0 );
    if (! status) {
        BIO_free(mem);
        croak("Could not pretty-print serial number");
    }
    return BIO_mem_to_SV(mem);
}

static
void set_serial(SV* sv_self, char* serial_hexstring) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    ASN1_INTEGER* serial_asn1;
    int status;

    serial_asn1 = parse_serial_or_croak(serial_hexstring);
    status = X509_set_serialNumber(self, serial_asn1);
    ASN1_INTEGER_free(serial_asn1);
    if (! status) { sslcroak("X509_set_serialNumber failed"); }
}


/* OBSOLETE because set_serial_hex lacks the ability to evolve
   to support other serial number formats in the future. Use
   L</set_serial> instead with a 0x prefix.  */
static
void set_serial_hex(SV* sv_self, char* serial_hexstring) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    ASN1_INTEGER* serial_asn1;
    BIGNUM* serial = NULL;

    if (! BN_hex2bn(&serial, serial_hexstring)) {
        sslcroak("BN_hex2bn failed");
    }
    if (! BN_to_ASN1_INTEGER(serial, X509_get_serialNumber(self))) {
        BN_free(serial);
        sslcroak("BN_to_ASN1_INTEGER failed");
    }
    BN_free(serial);
}
GET_SET_SERIAL

=head3 get_notBefore ()

=head3 set_notBefore ($startdate)

=head3 get_notAfter ()

=head3 set_notAfter ($enddate)

Get or set the validity period of the certificate.  The dates are in
the GMT timezone, with the format yyyymmddhhmmssZ (it's a literal Z at
the end, meaning "Zulu" in case you care).

=cut

sub _zuluize {
    my ($time) = @_;
    croak "UNIMPLEMENTED" if ($time !~ m/Z$/);
    if (length($time) eq length("YYYYMMDDHHMMSSZ")) {
        return $time;
    } elsif (length($time) eq length("YYMMDDHHMMSSZ")) {
        # RFC2480 § 4.1.2.5.1
        return ($time =~ m/^[5-9]/ ? "19" : "20") . $time;
    } else {
        croak "Bad time format $time";
    }
}

sub get_notBefore { _zuluize(_get_notBefore_raw(@_)) }
sub get_notAfter { _zuluize(_get_notAfter_raw(@_)) }

use Crypt::OpenSSL::CA::Inline::C <<"GET_SET_DATES";
static
SV* _get_notBefore_raw(SV* sv_self) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    if (! X509_get_notBefore(self)) { return Nullsv; }
    return newSVpv((char *)X509_get_notBefore(self)->data,
                   X509_get_notBefore(self)->length);
}

static
SV* _get_notAfter_raw(SV* sv_self) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    if (! X509_get_notAfter(self)) { return Nullsv; }
    return newSVpv((char *)X509_get_notAfter(self)->data,
                   X509_get_notAfter(self)->length);
}

static
void set_notBefore(SV* sv_self, char* startdate) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    ASN1_TIME* time = parse_RFC3280_time_or_croak(startdate);
    X509_set_notBefore(self, time);
    ASN1_TIME_free(time);
}

static
void set_notAfter(SV* sv_self, char* enddate) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    ASN1_TIME* time = parse_RFC3280_time_or_croak(enddate);
    X509_set_notAfter(self, time);
    ASN1_TIME_free(time);
}
GET_SET_DATES

=head3 extension_by_name ($extname)

Returns true if and only if $extname is a valid X509v3 certificate
extension, susceptible of being passed to L</set_extension> and
friends.

=begin internal

Specifically, returns the OpenSSL NID associated with
$extname, as an integer.

=end internal

=cut

# This one is callable from both Perl and C, kewl!
use Crypt::OpenSSL::CA::Inline::C << "EXTENSION_BY_NAME";
static
int extension_by_name(SV* unused, char* extname) {
    int nid;

    if (! extname) { return 0; }
    nid = OBJ_txt2nid(extname);

    if (! nid) { return 0; }
    const X509V3_EXT_METHOD* method = X509V3_EXT_get_nid(nid);
    if (!method) { return 0; }

    /* Extensions that cannot be created are obviously not supported. */
    if (! (method->v2i || method->s2i || method->r2i) ) { return 0; }
    /* This is also how we check whether this extension is for
       certificates or for CRLs: there simply is no support for
       creating the latter!  When CRL extension support finally gets
       added to OpenSSL, we'll have to change that. */

    return nid;
}
EXTENSION_BY_NAME

=head3 set_extension ($extname, $value, %options, %more_openssl_config)

Sets X509 extension $extname to the value $value in the certificate,
erasing any extension previously set for $extname in this certificate.
To make a long story short, $extname and $value may be almost any
B<explicit> legit key-value pair in the OpenSSL configuration file's
section that is pointed to by the C<x509_extensions> parameter (see
the details in the B<x509v3_config(5ssl)> manpage provided with
OpenSSL).  For example, OpenSSL's

   subjectKeyIdentifier=00:DE:AD:BE:EF

becomes

=for My::Tests::Below "set_extension subjectKeyIdentifier" begin

   $cert->set_extension( subjectKeyIdentifier => "00:DE:AD:BE:EF");

=for My::Tests::Below "set_extension subjectKeyIdentifier" end

However, B<implicit> extension values (ie, deducted from the CA
certificate or the subject DN) are B<not> supported:

=for My::Tests::Below "nice try with set_extension, no cigar" begin

  $cert->set_extension("authorityKeyIdentifier",
                       "keyid:always,issuer:always");  # WRONG!

=for My::Tests::Below "nice try with set_extension, no cigar" end

  $cert->set_extension(subjectAltName  => 'email:copy');  # WRONG!

The reason is that we don't want the API to insist on the CA certificate when
setting these extensions.  You can do this instead:

=for My::Tests::Below "set_extension authorityKeyIdentifier" begin

  $cert->set_extension(authorityKeyIdentifier =>
                       { keyid  => $ca->get_subject_keyid(),
                         issuer => $ca->get_issuer_dn(),
                         serial => $ca->get_serial() });

  $cert->set_extension(subjectAltName  => 'foo@example.com');

=for My::Tests::Below "set_extension authorityKeyIdentifier" end

where $ca is the CA's L</Crypt::OpenSSL::CA::X509> object, constructed
for instance with L</parse>.

(Note in passing, that using the C<issuer> and C<serial> elements for
an authorityKeyIdentifier, while discussed in RFC3280 section 4.2.1.1,
is frowned upon in L<Crypt::OpenSSL::CA::Resources/X509 Style Guide>).

The arguments to I<set_extension> after the first two are interpreted
as a list of key-value pairs.  Those that start with a hyphen are the
named options; they are interpreted like so:

=over

=item I<< -critical => 1 >>

Sets the extension as critical.  You may alternatively use the OpenSSL
trick of prepending "critical," to $value, but that's ugly.

=item I<< -critical => 0 >>

Do not set the extension as critical.  If C<critical> is present in
$value, an exception will be raised.

=back

The extra key-value key arguments that do B<not> start with a hyphen
are passed to OpenSSL as sections in its configuration file object;
the corresponding values must therefore be references to hash tables.
For example, here is how to transcribe the C<certificatePolicies>
example from L<Crypt::OpenSSL::CA::Resources/openssl.txt> into Perl:

=for My::Tests::Below "set_extension certificatePolicies" begin

    $cert->set_extension(certificatePolicies =>
                          'ia5org,1.2.3.4,1.5.6.7.8,@polsect',
                         -critical => 0,
                         polsect => {
                            policyIdentifier => '1.3.5.8',
                            "CPS.1"        => 'http://my.host.name/',
                            "CPS.2"        => 'http://my.your.name/',
                            "userNotice.1" => '@notice',
                         },
                         notice => {
                            explicitText  => "Explicit Text Here",
                            organization  => "Organisation Name",
                            noticeNumbers => '1,2,3,4',
                         });

=for My::Tests::Below "set_extension certificatePolicies" end

=cut

sub set_extension {
    my ($self, $extname, @stuff) = @_;
    my $real_extname = $extname;
    $real_extname = "authorityKeyIdentifier" if
        ($extname =~ m/^authorityKeyIdentifier/i); # OBSOLETE support
    # for authorityKeyIdentifier_keyid as was present in 0.04
    $self->remove_extension($real_extname);
    $self->add_extension($extname, @stuff);
}

=head3 add_extension ($extname, $value, %options, %more_openssl_config)

Just like L</set_extension>, except that if there is already a
value for this extension, it will not be removed; instead there will
be a duplicate extension in the certificate.  Note that this is
explicitly forbiden by RFC3280 section 4.2, third paragraph, so maybe
you shouldn't do that.

=cut

sub add_extension {
    die("incorrect number of arguments to add_extension()")
        unless (@_ % 2);
    my ($self, $extname, $value, %options) = @_;
    croak("add_extension: name is mandatory") unless
        ($extname && length($extname));
    croak("add_extension: value is mandatory") unless
        ($value && length($value));

    my $critical = "";
    $critical = "critical," if ($value =~ s/^critical(,|$)//i);

    foreach my $k (keys %options) {
        next unless $k =~ m/^-/;
        my $v = delete $options{$k};

        if ($k eq "-critical") {
            if ($v) {
                $critical = "critical,";
            } else {
                croak("add_extension: -critical => 0 conflicts" .
                      " with ``$_[2]''") if ($critical);
            }
        }
        # Other named options may be added later.
    }

    # OBSOLETE, for compatibility only:
    if ($extname eq "authorityKeyIdentifier_keyid") {
        $extname = "authorityKeyIdentifier";
        $value = { keyid => $value };
    }

    my $ext;
    if ($extname eq "authorityKeyIdentifier") {
        $ext = Crypt::OpenSSL::CA::X509V3_EXT->
            new_authorityKeyIdentifier(critical => $critical, %$value);
    } elsif (my $nid = $self->extension_by_name($extname)) {
        $ext = Crypt::OpenSSL::CA::X509V3_EXT->new_from_X509V3_EXT_METHOD(
            $nid, "$critical$value", Crypt::OpenSSL::CA::CONF->new(\%options));
    } else {
        croak "Unknown extension name $extname";
    }
    $self->_do_add_extension($ext);
}



=head3 remove_extension ($extname)

Removes any and all extensions named $extname in this certificate.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"REMOVE_EXTENSION";
static
void remove_extension(SV* sv_self, char* key) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    X509_EXTENSION* deleted;
    int nid, i;

    nid = extension_by_name(NULL, key);
    if (! nid) { croak("Unknown extension specified"); }

    while( (i = X509_get_ext_by_NID(self, nid, -1)) >= 0) {
        if (! (deleted = X509_delete_ext(self, i)) ) {
            sslcroak("X509_delete_ext failed");
        }
        X509_EXTENSION_free(deleted);
    }
}
REMOVE_EXTENSION

=begin internals

=head3 _do_add_extension ($extension)

Does the actual job of L</add_extension>, sans all the syntactic
sugar. $extension is an instance of
L</Crypt::OpenSSL::CA::X509V3_EXT>.

=end internals

=cut

use Crypt::OpenSSL::CA::Inline::C <<"DO_ADD_EXTENSION";
static
void _do_add_extension(SV* sv_self, SV* sv_extension) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    X509_EXTENSION *ex = perl_unwrap("Crypt::OpenSSL::CA::X509V3_EXT",
                                     X509_EXTENSION *, sv_extension);

    if (! X509_add_ext(self, ex, -1)) {
        sslcroak("X509_add_ext failed");
    }
}
DO_ADD_EXTENSION

=head3 dump ()

Returns a textual representation of all the fields inside the
(unfinished) certificate.  This is done using OpenSSL's
C<X509_print()>.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"DUMP";
static
SV* dump(SV* sv_self) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    BIO* mem = BIO_new(BIO_s_mem());

    if (! mem) {
        croak("Cannot allocate BIO");
    }

    if (! (X509_print(mem, self) && ( BIO_write(mem, "\\0", 1) > 0)) ) {
        sslcroak("X509_print failed");
    }

    return BIO_mem_to_SV(mem);
}
DUMP

=head3 sign ($privkey, $digestname)

Signs the certificate (TADA!!).  C<$privkey> is an instance of
L</Crypt::OpenSSL::CA::PrivateKey>; C<$digestname> is the name of one
of cryptographic digests supported by OpenSSL, e.g. "sha1" or "sha256"
(notice that using "md5" is B<strongly discouraged> due to security
considerations; see
L<http://www.win.tue.nl/~bdeweger/CollidingCertificates/>).  Returns
the PEM-encoded certificate as a string.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"SIGN";
static
SV* sign(SV* sv_self, SV* privkey, char* digestname) {
    X509* self = perl_unwrap("${\__PACKAGE__}", X509 *, sv_self);
    EVP_PKEY* key = perl_unwrap("Crypt::OpenSSL::CA::PrivateKey",
         EVP_PKEY *, privkey);
    const EVP_MD* digest;
    BIO* mem;

    if (! (digest = EVP_get_digestbyname(digestname))) {
        sslcroak("Unknown digest name: %s", digestname);
    }

    if (! X509_sign(self, key, digest)) {
        sslcroak("X509_sign failed");
    }

    if (! (mem = BIO_new(BIO_s_mem()))) {
        croak("Cannot allocate BIO");
    }
    if (! (PEM_write_bio_X509(mem, self) &&
           (BIO_write(mem, "\\0", 1) > 0)) ) {
        BIO_free(mem);
        croak("Serializing certificate failed");
    }
    return BIO_mem_to_SV(mem);
}

SIGN

=head2 supported_digests()

This is a class method (invoking it as an instance method also works
though).  Returns the list of all supported digest names for the
second argument of L</sign>.  The contents of this list depends on the
OpenSSL version and the details of how it was compiled.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"SUPPORTED_DIGESTS";
#include <openssl/objects.h>

static void _push_name_to_Perl(const OBJ_NAME* obj, void* unused) {
    /* Use dSP here ("declare stack pointer") instead of the more heavyweight
     * Inline_Stack_Vars (aka dXSARGS), which would truncate the Perl stack
     * every time.  See L<perlapi/dSP> and L<perlapi/dXSARGS>.
     */
    dSP;
    Inline_Stack_Push(sv_2mortal(newSVpv(obj->name, 0)));
    Inline_Stack_Done;  /* It's okay if we are actually not quite done yet. */
}

static
void supported_digests(SV* unused_self) {
    Inline_Stack_Vars;
    Inline_Stack_Reset;
    OBJ_NAME_do_all_sorted(OBJ_NAME_TYPE_MD_METH, &_push_name_to_Perl, NULL);
    /* No Inline_Stack_Done here: that would reinstate *our* copy of the stack
     * pointer, like it was at function entry (ie empty stack).
     */
}

SUPPORTED_DIGESTS

=head1 Crypt::OpenSSL::CA::X509_CRL

This Perl class wraps around OpenSSL's CRL creation features.

=cut

package Crypt::OpenSSL::CA::X509_CRL;
use Carp qw(croak);
use Crypt::OpenSSL::CA::Inline::C <<"X509_CRL_BASE";
#include <openssl/pem.h>
#include <openssl/bio.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>

static
void DESTROY(SV* sv_self) {
    X509_CRL_free(perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self));
}
X509_CRL_BASE

=head2 new ()

=head2 new ($version)

Creates and returns an empty I<Crypt::OpenSSL::CA::X509_CRL> object.
$version is the CRL version, e.g. C<1> or C<2> or C<CRLv1> or C<CRLv2>
for idiomatics.  The default is CRLv2, as per RFC3280.  Setting the
version to 1 will cause I<add_extension()> and L</add_entry> with
extensions to throw an exception instead of working.

=cut

sub new {
    my ($class, $version) = @_;
    $version = "CRLv2" if (! defined $version);
    unless ($version =~ m/([12])$/) {
        croak("Incorrect version string $version");
    }
    return $class->_new($1 - 1);
}

=head2 is_crlv2 ()

Returns true iff this CRL object was set to CRLv2 at L</new> time.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"IS_CRLV2";
static
int is_crlv2(SV* sv_self) {
    return X509_CRL_get_version
       (perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self));
}

IS_CRLV2

=head2 set_issuer_DN ($dn_object)

Sets the CRL's issuer name from an L</Crypt::OpenSSL::CA::X509_NAME>
object.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"SET_ISSUER_DN";

static
void set_issuer_DN(SV* sv_self, SV* sv_dn) {
    X509_CRL* self = perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self);
    X509_NAME* dn = perl_unwrap("Crypt::OpenSSL::CA::X509_NAME",
                                X509_NAME *, sv_dn);
    if (! X509_CRL_set_issuer_name(self, dn)) {
        sslcroak("X509_CRL_set_issuer_name failed");
    }
}
SET_ISSUER_DN

=head2 set_lastUpdate ($enddate)

=head2 set_nextUpdate ($startdate)

Sets the validity period of the certificate.  The dates must be in the
GMT timezone, with the format yyyymmddhhmmssZ (it's a literal Z at the
end, meaning "Zulu" in case you care).

=cut

use Crypt::OpenSSL::CA::Inline::C <<"SET_UPDATES";

static
void set_lastUpdate(SV* sv_self, char* startdate) {
    X509_CRL* self = perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self);
    ASN1_TIME* time = parse_RFC3280_time_or_croak(startdate);
    X509_CRL_set_lastUpdate(self, time);
    ASN1_TIME_free(time);
}

static
void set_nextUpdate(SV* sv_self, char* enddate) {
    ASN1_TIME* newtime;
    X509_CRL* self = perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self);

    ASN1_TIME* time = parse_RFC3280_time_or_croak(enddate);
    X509_CRL_set_nextUpdate(self, time);
    ASN1_TIME_free(time);
}
SET_UPDATES

=head2 set_extension ($extname, $value, %options, %more_openssl_config)

=head2 add_extension ($extname, $value, %options, %more_openssl_config)

=head2 remove_extension ($extname)

Manage CRL extensions as per RFC3280 section 5.2. These methods work
like their respective counterparts in L<Crypt::OpenSSL::CA::X509>.
Recognized CRL extensions are:

=over

=item I<authorityKeyIdentifier>

Works the same as in L</Crypt::OpenSSL::CA::X509>. Implements RFC3280
section 5.2.1.

=item I<crlNumber>

An extension (described in RFC3280 section 5.2.3, and made mandatory
by section 5.1.2.1) to identify the CRL by a monotonically increasing
sequence number.  The value of this extension must be a serial number,
with the same syntax as the first argument to L</set_serial>.

=item I<freshestCRL>

An optional RFC3280 extension that indicates support for delta-CRLs,
as described by RFC3280 section 5.2.6.  The expected $value and
%more_openssl_config are the same as for C<cRLDistributionPoints> in
an extension for certificates (see L</Crypt::OpenSSL::CA::X509>).

=item I<deltaCRLIndicator>

An optional RFC3280 extension that indicates that this CRL is as a
delta-CRL, pursuant to RFC3280 section 5.2.4.  For this extension,
$value must be a serial number, with the same syntax as the
first argument to L</set_serial>.

=back

Note that CRL extensions are B<not> implemented by OpenSSL as of
version 0.9.8c, but rather by C glue code directly in
I<Crypt::OpenSSL::CA>.

=cut

use vars qw(%ext2oid %oid2ext);
# RFC3280 Â§Â§ 4.2.1 and 5.2; http://www.alvestrand.no/objectid/2.5.29.html
%ext2oid = (crlNumber => "2.5.29.20",
            deltaCRLIndicator => "2.5.29.27",
            authorityKeyIdentifier => "2.5.29.35",
            freshestCRL => "2.5.29.46",
            );
%oid2ext = reverse %ext2oid;

sub set_extension {
    my ($self, $extname, @stuff) = @_;
    my $real_extname = $extname;
    $real_extname = "authorityKeyIdentifier" if
        ($extname =~ m/^authorityKeyIdentifier/i); # OBSOLETE support
    # for authorityKeyIdentifier_keyid as was present in 0.04
    $self->remove_extension($real_extname);
    $self->add_extension($extname, @stuff);
}

sub add_extension {
    die("incorrect number of arguments to add_extension()")
        unless (@_ % 2);
    my ($self, $extname, $value, %options) = @_;
    croak("add_extension: name is mandatory") unless
        ($extname && length($extname));
    croak("add_extension: value is mandatory") unless
        ($value && length($value));

    my $critical = "";
    $critical = "critical," if ($value =~ s/^critical(,|$)//i);

    foreach my $k (keys %options) {
        next unless $k =~ m/^-/;
        my $v = delete $options{$k};

        if ($k eq "-critical") {
            if ($v) {
                $critical = "critical,";
            } else {
                croak("add_extension: -critical => 0 conflicts" .
                      " with ``$_[2]''") if ($critical);
            }
        }
        # Other named options may be added later.
    }

    # OBSOLETE, for compatibility only:
    if ($extname eq "authorityKeyIdentifier_keyid") {
        $extname = "authorityKeyIdentifier";
        $value = { keyid => $value };
    }

    my $ext;
    if ($extname eq "authorityKeyIdentifier") {
        $ext = Crypt::OpenSSL::CA::X509V3_EXT->
            new_authorityKeyIdentifier(critical => $critical, %$value);
    } elsif ($extname eq "freshestCRL") {
        $ext = Crypt::OpenSSL::CA::X509V3_EXT->
            new_freshestCRL("$critical$value",
                            Crypt::OpenSSL::CA::CONF->new(\%options));
    } elsif (grep { $extname eq $_ } (qw(crlNumber deltaCRLIndicator))) {
        $ext = Crypt::OpenSSL::CA::X509V3_EXT->
            new_CRL_serial(($critical ? 1 : 0),
                           $ext2oid{$extname}, $value);
    } else {
        croak("Unknown CRL extension $extname");
    }
    $self->_do_add_extension($ext);
}

sub remove_extension {
    my ($self, $extname) = @_;
    my $extoid = $extname;
    $extoid = $ext2oid{$extoid} if exists $ext2oid{$extoid};
    croak("Unknown CRL extension: $extname") unless
        (exists $oid2ext{$extoid});
    $self->_remove_extension_by_oid($extoid);
}

=head2 add_entry ($serial_hex, $revocationdate, %named_options)

Adds an entry to the CRL.  $serial_hex is the serial number of the
certificate to be revoked, as a scalar containing a lowercase,
hexadecimal string starting with "0x".  $revocationdate is a time in
"Zulu" format, like in L</set_lastUpdate>.

The following named options provide access to CRLv2 extensions as
defined in RFC3280 section 5.3:

=over

=item I<< -reason => $reason >>

Sets the revocation reason to $reason, a plain string.  Available
reasons are C<unspecified> (which is B<not> the same thing as not
setting a revocation reason at all), C<keyCompromise>,
C<CACompromise>, C<affiliationChanged>, C<superseded>,
C<cessationOfOperation>, C<certificateHold> and C<removeFromCRL>.

=item I<< -compromise_time => $time >>

The time at which the compromise is suspected to have taken place,
which may be earlier than the $revocationdate.  The syntax for $time
is the same as that for $revocationdate.  Note that this CRL extension
only makes sense if I<< -reason >> is either I<keyCompromise> or
I<CACompromise>.

=item I<< -hold_instruction => $oid >>

=item I<< -hold_instruction => $string >>

Sets the hold instruction token to $oid (which is a string containing
a dot-separated sequence of decimal integers), or $string (one of the
predefined string constants C<none>, C<callIssuer>, C<reject> and
C<pickupToken>, case-insensitive).  This option only makes sense if
the revocation reason is C<certificateHold>.  See also
L</Crypt::OpenSSL::CA::X509_CRL::holdInstructionNone>,
L</Crypt::OpenSSL::CA::X509_CRL::holdInstructionCallIssuer>,
L</Crypt::OpenSSL::CA::X509_CRL::holdInstructionReject> and
L</Crypt::OpenSSL::CA::X509_CRL::holdInstructionPickupToken>.

=back

All the above options should be specified at most once.  If they are
specified several times, only the last occurence in the parameter list
will be taken into account.

The criticality is set according to the recommendations of RFC3280
section 5.3; practically speaking, all certificate entry extensions
are noncritical, given that 5.3.4-style C<certificateIssuer> is
B<UNIMPLEMENTED>.  Support for critical certificate entry extensions
may be added in a future release of I<Crypt::OpenSSL::CA>.

=cut

sub add_entry {
    croak("Wrong number of arguments to add_entry") unless @_ % 2;
    my ($self, $serial_hex, $revocationdate, %named_options) = @_;

    my $reason = do {
        # RFC3280 section 5.3.1:
        my @rfc3280_revocation_reasons =
            qw(unspecified keyCompromise cACompromise
               affiliationChanged superseded cessationOfOperation
               certificateHold __UNUSED__ removeFromCRL privilegeWithdrawn
               aACompromise);
        my %reason = map { ( $rfc3280_revocation_reasons[$_] => $_ ) }
            (0..$#rfc3280_revocation_reasons);
        $reason{$named_options{-reason} || ""};
    };
    my $holdinstr = do {
        local $_ = $named_options{-hold_instruction};
        if (defined($_)) {
            if (m/none/i) { $_ = holdInstructionNone(); }
            elsif (m/callissuer/i) { $_ = holdInstructionCallIssuer(); }
            elsif (m/reject/i) { $_ = holdInstructionReject(); }
            elsif (m/pickuptoken/i) { $_ = holdInstructionPickupToken(); }
            elsif (m/^\d+(\.\d+)*$/) { }  # No transformation
            else { croak("Unknown hold instruction $_"); }
        }
        $_;
    };

    my $comptime = $named_options{-compromise_time};

    return $self->_do_add_entry
        ($serial_hex, $revocationdate, $reason, $holdinstr, $comptime);
}

=head2 sign ($privkey, $digestname)

Signs the CRL.  C<$privkey> is an instance of
L</Crypt::OpenSSL::CA::PrivateKey>; C<$digestname> is the name of one
of cryptographic digests supported by OpenSSL, e.g. "sha1" or "sha256"
(notice that using "md5" is B<strongly discouraged> due to security
considerations; see
L<http://www.win.tue.nl/~bdeweger/CollidingCertificates/>).  Returns
the PEM-encoded CRL as a string.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"SIGN";
static
SV* sign(SV* sv_self, SV* sv_key, char* digestname) {
    X509_CRL* self = perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self);
    EVP_PKEY* key = perl_unwrap("Crypt::OpenSSL::CA::PrivateKey",
         EVP_PKEY *, sv_key);
    const EVP_MD* digest;
    BIO* mem;

    if (! (digest = EVP_get_digestbyname(digestname))) {
        sslcroak("Unknown digest name: %s", digestname);
    }

    if (! X509_CRL_sort(self)) { sslcroak("X509_CRL_sort failed"); }

    if (! X509_CRL_sign(self, key, digest)) {
        sslcroak("X509_CRL_sign failed");
    }

    if (! (mem = BIO_new(BIO_s_mem()))) {
        croak("Cannot allocate BIO");
    }
    if (! (PEM_write_bio_X509_CRL(mem, self) &&
          (BIO_write(mem, "\\0", 1) > 0)) ) {
        BIO_free(mem);
        croak("Serializing certificate failed");
    }
    return BIO_mem_to_SV(mem);
}
SIGN

=head2 supported_digests()

This is a class method (invoking it as an instance method also works
though).  Returns the list of all supported digest names for the
second argument of L</sign>.  The contents of this list depends on the
OpenSSL version and the details of how it was compiled.

=cut

sub supported_digests { Crypt::OpenSSL::CA::X509->supported_digests }

=head2 dump ()

Returns a textual representation of all the fields inside the
(unfinished) CRL.  This is done using OpenSSL's
C<X509_CRL_print()>.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"DUMP";
static
SV* dump(SV* sv_self) {
    X509_CRL* self = perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self);
    BIO* mem = BIO_new(BIO_s_mem());

    if (! mem) {
        croak("Cannot allocate BIO");
    }

    if (! (X509_CRL_print(mem, self) &&
          (BIO_write(mem, "\\0", 1) > 0)) ) {
        sslcroak("X509_CRL_print failed");
    }

    return BIO_mem_to_SV(mem);
}
DUMP

=head2 Crypt::OpenSSL::CA::X509_CRL::holdInstructionNone

=head2 Crypt::OpenSSL::CA::X509_CRL::holdInstructionCallIssuer

=head2 Crypt::OpenSSL::CA::X509_CRL::holdInstructionReject

=head2 Crypt::OpenSSL::CA::X509_CRL::holdInstructionPickupToken

OID constants for the respective hold instructions (see the
I<-hold_instruction> named option in L</add_entry>).  All these
functions return a string containing a dot-separated sequence of
decimal integers.

=cut

sub holdInstructionNone        { "1.2.840.10040.2.1" }
sub holdInstructionCallIssuer  { "1.2.840.10040.2.2" }
sub holdInstructionReject      { "1.2.840.10040.2.3" }
sub holdInstructionPickupToken { "1.2.840.10040.2.4" }

=begin internals

=head2 _new ($x509_crl_version)

Does the actual job of L</new>.  $x509_crl_version must be an integer,
0 for CRLv1 and 1 for CRLv2.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"_NEW";
static
SV* _new(char *class, int x509_crl_version) {
    X509_CRL* retval = X509_CRL_new();

    if (! retval) {
        croak("X509_CRL_new failed");
    }
    if (! X509_CRL_set_version(retval, x509_crl_version)) {
        X509_CRL_free(retval);
        sslcroak("X509_CRL_set_version failed");
    }

    return perl_wrap("${\__PACKAGE__}", retval);
}
_NEW

=head2 _do_add_extension ($extension)

Does the actual job of L</add_extension>, sans all the syntactic
sugar. $extension is an instance of
L</Crypt::OpenSSL::CA::X509V3_EXT>.

=cut

use Crypt::OpenSSL::CA::Inline::C <<"_DO_ADD_EXTENSION";
static
void _do_add_extension(SV* sv_self, SV* sv_extension) {
    X509_CRL* self = perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self);
    if (! X509_CRL_get_version(self)) {
        croak("Cannot add extensions to a CRLv1");
    }
    X509_EXTENSION *ex = perl_unwrap("Crypt::OpenSSL::CA::X509V3_EXT",
                                     X509_EXTENSION *, sv_extension);

    if (! X509_CRL_add_ext(self, ex, -1)) {
        sslcroak("X509_CRL_add_ext failed");
    }
}
_DO_ADD_EXTENSION

=head2 _remove_extension_by_oid ($oid_text)

Like L</remove_extension>, except that the parameter is an ASN.1
Object Identifier in dotted-decimal form (e.g. "2.5.29.20" instead of
C<cRLNumber>).

=cut

use Crypt::OpenSSL::CA::Inline::C <<"_REMOVE_EXTENSION_BY_OID";
static
void _remove_extension_by_oid(SV* sv_self, char* oidtxt) {
    X509_CRL* self = perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self);
    X509_EXTENSION* deleted;
    ASN1_OBJECT* obj;
    int i;

    if (! (obj = OBJ_txt2obj(oidtxt, 1))) {
        sslcroak("OBJ_txt2obj failed on %s", oidtxt);
    }

    while( (i = X509_CRL_get_ext_by_OBJ(self, obj, -1)) >= 0) {
        if (! (deleted = X509_CRL_delete_ext(self, i)) ) {
            ASN1_OBJECT_free(obj);
            sslcroak("X509_delete_ext failed");
        }
        X509_EXTENSION_free(deleted);
    }
    ASN1_OBJECT_free(obj);
}
_REMOVE_EXTENSION_BY_OID

=head2 _do_add_entry ($serial, $date, $reason_code, $hold_instr,
                      $compromise_time)

Does the actual job of L</add_entry>, sans all the syntactic sugar.
All arguments are strings, except $reason_code which is an integer
according to the enumeration set forth in RFC3280 section 5.3.1.
$reason_code, $hold_instr and $compromise_time can be omitted (that
is, passed as undef).

This already ugly API will of course have to "evolve" as we implement
more CRL entry extensions.

=end internals

=cut

use Crypt::OpenSSL::CA::Inline::C <<"_DO_ADD_ENTRY";
static
void _do_add_entry(SV* sv_self, char* serial_hex, char* date,
                   SV* sv_reason, SV* sv_holdinstr,
                   SV* sv_compromisetime) {
    X509_CRL* self = perl_unwrap("${\__PACKAGE__}", X509_CRL *, sv_self);
    ASN1_INTEGER* serial_asn1;
    ASN1_TIME* revocationtime;
    ASN1_GENERALIZEDTIME* compromisetime;
    ASN1_OBJECT* holdinstr;
    ASN1_ENUMERATED* reason;
    X509_REVOKED* entry;
    int status;
    char* plainerr = NULL; char* sslerr = NULL;

    if (! (entry = X509_REVOKED_new())) {
        croak("X509_REVOKED_new failed");
    }

    if (! (revocationtime = parse_RFC3280_time(date, &plainerr, &sslerr))) {
        goto error;
    }

    status = X509_REVOKED_set_revocationDate(entry, revocationtime);
    ASN1_TIME_free(revocationtime);
    if (! status) {
        sslerr = "X509_REVOKED_set_revocationDate failed";
        goto error;
    }

    if (! (serial_asn1 = parse_serial(serial_hex, &plainerr, &sslerr)) ) {
        goto error;
    }
    status = X509_REVOKED_set_serialNumber(entry, serial_asn1);
    ASN1_INTEGER_free(serial_asn1);
    if (! status) {
        sslerr = "X509_REVOKED_set_serialNumber failed";
        goto error;
    }

    /* CRLv2 entry extensions */
    if ( (! is_crlv2(sv_self)) &&
         (SvOK(sv_reason) || SvOK(sv_holdinstr) ||
          SvOK(sv_compromisetime))) {
        plainerr = "Cannot add entry extensions to CRLv1 CRL";
        goto error;
    }
    if (SvOK(sv_reason)) {
        if (! (reason = ASN1_ENUMERATED_new())) {
            plainerr = "Not enough memory for ASN1_ENUMERATED_new";
            goto error;
        }
        if (! ASN1_ENUMERATED_set(reason, SvIV(sv_reason))) {
            ASN1_ENUMERATED_free(reason);
            sslerr = "ASN1_ENUMERATED_set failed";
            goto error;
        }
        status = X509_REVOKED_add1_ext_i2d
            (entry, NID_crl_reason, reason, 0, 0);
        ASN1_ENUMERATED_free(reason);
        if (! status) {
            sslerr = "X509_REVOKED_add1_ext_i2d failed";
            goto error;
        }
    }
    if (SvOK(sv_holdinstr)) {
        if (! (holdinstr = OBJ_txt2obj(char0_value(sv_holdinstr), 1))) {
            sslerr = "OBJ_txt2obj failed";
            goto error;
        }
        status = X509_REVOKED_add1_ext_i2d
            (entry, NID_hold_instruction_code, holdinstr, 0, 0);
        ASN1_OBJECT_free(holdinstr);
        if (! status) {
            sslerr = "X509_REVOKED_add1_ext_i2d failed";
            goto error;
        }
    }
    if (SvOK(sv_compromisetime)) {
        if (! (compromisetime = ASN1_GENERALIZEDTIME_new())) {
            plainerr = "Not enough memory for ASN1_GENERALIZEDTIME_new";
            goto error;
        }
        if (! (ASN1_GENERALIZEDTIME_set_string
                  (compromisetime, char0_value(sv_compromisetime)))) {
            ASN1_GENERALIZEDTIME_free(compromisetime);
            sslerr = "ASN1_GENERALIZEDTIME_set_string failed";
            goto error;
        }
        status = X509_REVOKED_add1_ext_i2d
            (entry, NID_invalidity_date, compromisetime, 0, 0);
        ASN1_GENERALIZEDTIME_free(compromisetime);
        if (! status) {
            sslerr = "X509_REVOKED_add1_ext_i2d failed";
            goto error;
        }
    }

    /* All set */

    if (! X509_CRL_add0_revoked(self, entry)) {
        sslcroak("X509_CRL_add0_revoked failed");
    }
    return;

error:
        X509_REVOKED_free(entry);
        if (plainerr) { croak("%s", plainerr); }
        if (sslerr) { sslcroak("%s", sslerr); }
        sslcroak("Unknown error in _do_add_entry");
}
_DO_ADD_ENTRY

=head1 TODO

Add centralized key generation.

Add some comfort features such as the ability to transfer
certification information automatically from the CA certificate to the
issued certificates and CRLs, RFC3280 compliance checks (especially as
regards the criticality of X509v3 certificate extensions) and so on.

OpenSSL engines are only a few hours of work away, but aren't done
yet.

Key formats other than RSA are not (fully) supported, and at any rate,
not unit-tested.

Only the subset of the CRL extensions required to support delta-CRLs
is working, as documented in L<Crypt::OpenSSL::CA::X509_CRL>; RFC3280
sections 5.2.2 (C<issuerAltName>), 5.2.5 (C<issuingDistributionPoint>)
and 5.3.4 (C<certificateIssuer> entry extension) are B<UNIMPLEMENTED>.
I am quite unlikely to implement these arcane parts of the
specification myself; L</PATCHES WELCOME>.

=head1 SEE ALSO

L<Crypt::OpenSSL::CA::Resources>, L<Crypt::OpenSSL::CA::Inline::C>.

=head1 AUTHOR

Dominique QUATRAVAUX, C<< <domq at cpan.org> >>

=head1 PATCHES WELCOME

If you feel that a key feature is missing in I<Crypt::OpenSSL::CA>,
please feel free to send me patches; I'll gladly apply them and
re-release the whole module within a short time.  The only thing I
require is that the patch cover all three of documentation, unit tests
and code; and that tests pass successfully afterwards, of course, at
least on your own machine.  In particular, this means that patches
that only add code will be declined, no matter how desirable the new
features are.

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-openssl-ca at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-OpenSSL-CA>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::OpenSSL::CA

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-OpenSSL-CA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-OpenSSL-CA>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-OpenSSL-CA>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-OpenSSL-CA>

=back

=head1 ACKNOWLEDGEMENTS

IDEALX (L<http://www.idealx.com/>) is the company that put food on my
family's table for 5 years while I was busy coding IDX-PKI.  I owe
them pretty much everything I know about PKIX, and a great deal of my
todays' Perl-fu.  However, the implementation of this module is
original and does not re-use any code in IDX-PKI.

=head1 COPYRIGHT & LICENSE


Copyright (C) 2007 Siemens Business Services France SAS, all rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use Crypt::OpenSSL::CA::Inline::C "__END__";

require My::Tests::Below unless caller();
1;

__END__

=begin testsuite

=head1 TEST SUITE

=cut

use Test::More "no_plan";
use Test::Group;
use Crypt::OpenSSL::CA::Test;
use Data::Dumper;

=head2 X509_NAME tests

=cut

use Crypt::OpenSSL::CA::Test qw(test_simple_utf8 test_bmp_utf8
                                x509_decoder);

test "X509_NAME" => sub {
    my $name = Crypt::OpenSSL::CA::X509_NAME->new();
    ok($name->isa("Crypt::OpenSSL::CA::X509_NAME"));
    is($name->to_string(), "");

    $name = Crypt::OpenSSL::CA::X509_NAME->new
        ("2.5.4.11" => "Internet widgets", CN => "John Doe");
    like($name->to_string(), qr/cn=John Doe/i);
    like($name->to_string(), qr/ou=Internet widgets/i);

    eval {
        my $name = Crypt::OpenSSL::CA::X509_NAME->new("John Doe");
        fail("should have thrown - Bad number of arguments");
    };
    like($@, qr/arg/);

    {
        my $dn = Crypt::OpenSSL::CA::X509_NAME->new
            (C => "fr", CN => test_simple_utf8);
        like($dn->to_string, qr/cn=zoinx/i);
        my $asn1 = x509_decoder('Name');
        my $tree = $asn1->decode($dn->to_asn1);
        if (! isnt($tree, undef, "decoding succesful")) {
            diag $asn1->error;
            diag run_dumpasn1($dn->to_asn1);
        } else {
            my $rdn_asn1 = $tree->{rdnSequence}->[1]->[0];
            my ($rdn_type) = keys %{$rdn_asn1->{value}};
            is($rdn_type, "utf8String");
        }
    }

    {
        my $dn = Crypt::OpenSSL::CA::X509_NAME
             ->new(C => "fr", CN => test_bmp_utf8);
        my $tree = x509_decoder('Name')->decode
            ($dn->to_asn1);
        if (isnt($tree, undef, "decoding succesful")) {
            my $rdn_asn1 = $tree->{rdnSequence}->[1]->[0];
            my ($rdn_type) = keys %{$rdn_asn1->{value}};
            is($rdn_type, "utf8String");
        }
    }
};

skip_next_test "Devel::Mallinfo needed" if cannot_check_bytes_leaks;
test "X509_NAME leaks" => sub {
    leaks_bytes_ok {
        for(1..10000) {
            my $name = Crypt::OpenSSL::CA::X509_NAME->new
                (CN => "coucou", "2.5.4.11.1.2.3.4" => "who cares?");
            $name->to_string();
            $name->to_asn1();

            $name = Crypt::OpenSSL::CA::X509_NAME->new_utf8
                (CN => "coucou", "2.5.4.11.1.2.3.4" => "who cares?");
            $name->to_string();
            $name->to_asn1();
        }
    };
};

=head2 PublicKey tests

=cut

use Crypt::OpenSSL::CA::Test qw(%test_public_keys);

test "PublicKey" => sub {
    errstack_empty_ok();

    my $pubkey = Crypt::OpenSSL::CA::PublicKey->parse_RSA
        ($test_public_keys{rsa1024});
    is(ref($pubkey), "Crypt::OpenSSL::CA::PublicKey");
    like($pubkey->get_modulus, qr/^[0-9A-F]+$/);
    like($pubkey->get_openssl_keyid, qr/^[0-9A-F]{2}(:[0-9A-F]{2})*$/);

    errstack_empty_ok();
};

skip_next_test if cannot_check_bytes_leaks;
test "PublicKey leakage" => sub {
        leaks_bytes_ok {
            for(1..1000) {
                my $pubkey = Crypt::OpenSSL::CA::PublicKey
                    ->parse_RSA($test_public_keys{rsa1024});
                $pubkey->to_PEM;
                $pubkey->get_modulus;
                $pubkey->get_openssl_keyid;
                # One more time, as ->get_openssl_keyid does an
                # X509_free() on a fake cert that points to the public
                # key and that's where things could go medieval:
                $pubkey->get_modulus;
                $pubkey->get_openssl_keyid;
            }
        };
};

use Crypt::OpenSSL::CA::Test qw(%test_reqs_SPKAC %test_reqs_PKCS10);
test "SPKAC key extraction" => sub {
    my $spkac = $test_reqs_SPKAC{rsa1024};
    my $pubkey = Crypt::OpenSSL::CA::PublicKey->validate_SPKAC
        ($spkac);
    is($pubkey->to_PEM, $test_public_keys{rsa1024});
    $spkac =~ tr/12345ABCDE/67890UVWXY/;
    eval {
         Crypt::OpenSSL::CA::PublicKey->validate_SPKAC($spkac);
         fail("should have thrown");
     };
    is(ref($@), "Crypt::OpenSSL::CA::Error", "nifty exception object");
};

skip_next_test if cannot_check_bytes_leaks;
test "SPKAC key extraction leakage" => sub {
    leaks_bytes_ok {
        for (1..1000) {
            Crypt::OpenSSL::CA::PublicKey->validate_SPKAC
                ($test_reqs_SPKAC{rsa1024});
        }
    };
};

test "PKCS#10 key extraction" => sub {
    my $pkcs10 = $test_reqs_PKCS10{rsa1024};
    my $pubkey = Crypt::OpenSSL::CA::PublicKey->validate_PKCS10
        ($pkcs10);
    is($pubkey->to_PEM, $test_public_keys{rsa1024});
    $pkcs10 =~ tr/12345ABCDE/67890UVWXY/;
    eval {
         Crypt::OpenSSL::CA::PublicKey->validate_PKCS10($pkcs10);
         fail("should have thrown");
     };
    is(ref($@), "Crypt::OpenSSL::CA::Error", "nifty exception object");
};

skip_next_test if cannot_check_bytes_leaks;
test "PKCS#10 key extraction leakage" => sub {
    leaks_bytes_ok {
        for (1..1000) {
            Crypt::OpenSSL::CA::PublicKey->validate_PKCS10
                ($test_reqs_PKCS10{rsa1024});
        }
    };
};

=head2 PrivateKey tests

=cut

use Crypt::OpenSSL::CA::Test qw(%test_keys_plaintext %test_keys_password);


test "PrivateKey: parse plaintext software key" => sub {
    ok($test_keys_plaintext{rsa1024});
    errstack_empty_ok();

    my $key = Crypt::OpenSSL::CA::PrivateKey->
        parse($test_keys_plaintext{rsa1024});
    is(ref($key), "Crypt::OpenSSL::CA::PrivateKey");

    is($key->get_public_key->to_PEM, $test_public_keys{rsa1024},
       "matching private and public key");

    errstack_empty_ok();
};

test "PrivateKey: parse password-protected software key" => sub {
    ok($test_keys_password{rsa1024});

    my $key = Crypt::OpenSSL::CA::PrivateKey->
        parse($test_keys_password{rsa1024}, -password => "secret");
    is(ref($key), "Crypt::OpenSSL::CA::PrivateKey");
    is($key->get_public_key->to_PEM, $test_public_keys{rsa1024});

    # wrong password:
    eval {
        my $key = Crypt::OpenSSL::CA::PrivateKey->
            parse($test_keys_password{rsa1024}, -password => "coucou");
        fail("Should have thrown - Bad password");
    };
    is(ref($@), "Crypt::OpenSSL::CA::Error",
       "nifty exception object");
    my $firsterror = $@->{-openssl}->[0];

    # no password, despite one needed:
    eval {
        my $key = Crypt::OpenSSL::CA::PrivateKey->
            parse($test_keys_password{rsa1024});
        fail("Should have thrown - No password");
    };
    is(ref($@), "Crypt::OpenSSL::CA::Error",
       "nifty exception object");
    isnt($@->{-openssl}->[0], $firsterror,
         "Different exceptions, allowing one to discriminate errors");

};

{
  local $TODO = "UNIMPLEMENTED";
  test "PrivateKey: parse engine key" => sub {
    fail;
  };

  test "PrivateKey: parse engine key with some engine parameters" => sub {
    fail;
  };
}

skip_next_test if cannot_check_bytes_leaks;
test "PrivateKey: memory leaks" => sub {
    leaks_bytes_ok {
        for(1..1000) {
            Crypt::OpenSSL::CA::PrivateKey
                ->parse($test_keys_plaintext{rsa1024})->get_public_key;
        }
    };
};

=head2 CONF tests

=cut

test "CONF functionality" => sub {
    my $conf = Crypt::OpenSSL::CA::CONF->new
        ({ sect1 => { key1 => "val1", key2 => "val2" }});
    is($conf->get_string("sect1", "key1"), "val1");
    is($conf->get_string("sect1", "key2"), "val2");
    # ->get_string is allowed to either return undef or throw
    # for nonexistent keys:
    is(eval { $conf->get_string("sect2", "key1") }, undef);
};

test "CONF defensiveness" => sub {
    eval {
        Crypt::OpenSSL::CA::CONF->new(\"");
        fail("Should not accept bizarre data structure");
    };
    like($@, qr/structure/);
    eval {
        Crypt::OpenSSL::CA::CONF->new
            ({ sect1 => [ key1 => "val1", key2 => "val2" ]});
        fail("Should not accept bizarre data structure");
    };
    like($@, qr/structure/);
};

skip_next_test if cannot_check_bytes_leaks;
test "CONF memory management" => sub {
    leaks_bytes_ok {
        for (1..100) {
            my $conf = Crypt::OpenSSL::CA::CONF->new
                ({ section => { bigkey => "A" x 6000 }});
            $conf->get_string("section", "bigkey");
        }
    }
};

=head2 X509 Tests

=cut

use Crypt::OpenSSL::CA::Test qw(%test_self_signed_certs);

test "X509 parsing" => sub {
    errstack_empty_ok();

    my $x509 = Crypt::OpenSSL::CA::X509->parse
        ($test_self_signed_certs{rsa1024});
    is(ref($x509->get_public_key), "Crypt::OpenSSL::CA::PublicKey");;

    like($x509->get_subject_DN()->to_string(),
         qr/Internet Widgits/);
    like($x509->get_issuer_DN()->to_string(),
         qr/Internet Widgits/);
    like($x509->get_serial, qr/^0x[1-9a-f][0-9a-f]*/);

    like($x509->dump, qr/Internet Widgits/);

    like($x509->get_notBefore, qr/^\d{14}Z$/, "notBefore syntax");
    like($x509->get_notAfter, qr/^\d{14}Z$/, "notAfter syntax");

    is(Crypt::OpenSSL::CA::PrivateKey->
       parse($test_keys_plaintext{rsa1024})->get_public_key->to_PEM,
       $x509->get_public_key->to_PEM,
       "matching private key and certificate");

    is($x509->get_subject_keyid,
       $x509->get_public_key->get_openssl_keyid,
       "this certificate was signed by OpenSSL, it seems");

    my $anotherx509 =Crypt::OpenSSL::CA::X509->parse
        ($Crypt::OpenSSL::CA::Test::test_rootca_certs{rsa1024});
    is($anotherx509->get_subject_keyid,
       $x509->get_public_key->get_openssl_keyid,
       "this certificate was also signed by OpenSSL")
        or warn $anotherx509->dump;

    errstack_empty_ok();

    my $rightpubkey = Crypt::OpenSSL::CA::PublicKey->parse_RSA
                     ($test_public_keys{rsa1024});
    my $wrongpubkey = Crypt::OpenSSL::CA::PublicKey->parse_RSA
        (<<"ANOTHER_PUBLIC_KEY");
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCxMU9SUakTmhw/y8YMDK9YlEQ0
Fjn7FLTWlnk1GUVJDkmrJKeO/RHv9xU9sH+slNvKcJYDMAPulkNmWLUE3WcqxUc1
BZWoEyy4Q2O6rcQ1pguHaxRUZ5ewMzpNbAhB+ZSbJ1SqJcraYqMVKrF+QL5Xsvad
HG+cnQY/bBZ9V7YqwwIDAQAB
-----END PUBLIC KEY-----
ANOTHER_PUBLIC_KEY
    ok($x509->verify($rightpubkey));
    ok(! eval { $x509->verify($wrongpubkey); 1 });
    is(ref($@), "Crypt::OpenSSL::CA::Error");

    errstack_empty_ok();
};

skip_next_test if cannot_check_bytes_leaks;
test "X509 read accessor memory leaks" => sub {
    my $pubkey = Crypt::OpenSSL::CA::PublicKey->parse_RSA
        ($test_public_keys{rsa1024});
    leaks_bytes_ok {
        for(1..1000) {
            my $x509 = Crypt::OpenSSL::CA::X509
                ->parse($test_self_signed_certs{rsa1024});
            $x509->get_public_key->get_modulus;
            $x509->get_subject_DN;
            $x509->get_issuer_DN;
            $x509->get_serial;
            $x509->get_subject_keyid;
            $x509->get_notBefore;
            $x509->get_notAfter;
            $x509->dump;
        }
    };
};

my $cakey = Crypt::OpenSSL::CA::PrivateKey
    ->parse($test_keys_plaintext{rsa1024});
my $eepubkey = Crypt::OpenSSL::CA::PublicKey
    ->parse_RSA($test_public_keys{rsa1024});

use Crypt::OpenSSL::CA::Test qw(certificate_chain_invalid_ok
                                %test_rootca_certs);
test "minimalistic certificate" => sub {
    my $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
    my $pem = $cert->sign($cakey, "sha1");
    certificate_looks_ok($pem);
    # There is a *zillion* of reasons why this certificate is invalid:
    certificate_chain_invalid_ok($pem, [ $test_rootca_certs{rsa1024} ]);
};

skip_next_test if cannot_check_bytes_leaks;
test "signing several times over the same ::X509 instance" => sub {
    my $pubkey = Crypt::OpenSSL::CA::PublicKey
        ->parse_RSA($test_public_keys{rsa2048});
    my $cert = Crypt::OpenSSL::CA::X509->new($pubkey);
    my $anothercert = Crypt::OpenSSL::CA::X509->parse
        ($test_self_signed_certs{rsa1024});
    my @issuer_DN = (O => "Zoinx") x 50;
    my @subject_DN = (CN => "Olivera da Figueira") x 50;
    leaks_bytes_ok {
        for(1..1000) {
            $cert->set_subject_DN
                (Crypt::OpenSSL::CA::X509_NAME->new(@subject_DN));
            $cert->set_issuer_DN
                (Crypt::OpenSSL::CA::X509_NAME->new(@issuer_DN));
            $cert->sign($cakey, "sha1");
        }
        for(1..1000) {
            $anothercert->set_subject_DN
                (Crypt::OpenSSL::CA::X509_NAME->new(@subject_DN));
            $anothercert->set_issuer_DN
                (Crypt::OpenSSL::CA::X509_NAME->new(@issuer_DN));
            $anothercert->sign($cakey, "sha1");
        }
    } -max => 60000;
};

test "->supported_digests()" => sub {
    my @supported_digests = Crypt::OpenSSL::CA::X509->supported_digests();
    ok(grep { $_ eq "md5" } @supported_digests)
      or warn join(" ", @supported_digests);
    unless(cannot_check_bytes_leaks) {
        leaks_bytes_ok {
            for(1..5000) {
                my @unused = Crypt::OpenSSL::CA::X509->supported_digests();
                # Should also withstand scalar and void contexts, even if the
                # return value makes little sense in these cases:
                my $unused = Crypt::OpenSSL::CA::X509->supported_digests();
                Crypt::OpenSSL::CA::X509->supported_digests();
            }
        };
    }
};

skip_next_test if cannot_check_bytes_leaks;
test "REGRESSION: set_serial memory leak" => sub {
    leaks_bytes_ok {
        for(1..100) {
            my $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
            for(1..200) { # Checks for robustness and leaks
                $cert->set_serial("0x1234567890abcdef1234567890ABCDEF");
            }
            $cert->sign($cakey, "sha1");
        }
    };
};

test "extension registry" => sub {
    is(Crypt::OpenSSL::CA::X509
       ->extension_by_name("FooBar"), 0, "bogus extension");
    isnt(Crypt::OpenSSL::CA::X509
         ->extension_by_name("basicConstraints"), 0, "legit extension");
    is(Crypt::OpenSSL::CA::X509
         ->extension_by_name("serverAuth"), 0, "not an extension");
    is(Crypt::OpenSSL::CA::X509
         ->extension_by_name("crlNumber"), 0,
       "this extension is for CRLs, not certificates");
};

# RT #95437: in some older versions of OpenSSL, freshestCRL was an unknown
# extension. In newer versions of OpenSSL, it is known but trying to OBJ_create
# it anyway (as the code did in versions up to 0.19) resulted in a clash.
test "Regression for RT #95437: extension redeclaration clash" => sub {
  my $name = "fresheshCRL";
  my $nid = Crypt::OpenSSL::CA::X509->extension_by_name($name);
  if (! $nid) {
    pass("Old version of OpenSSL doesn't know of freshestCRL, test skipped");
    return;
  }
  my $crl = Crypt::OpenSSL::CA::X509_CRL->new;
  $crl->set_extension($name => '@s', s => { "URI.0" => "http://example.com/"});
  is(Crypt::OpenSSL::CA::X509->extension_by_name($name), $nid,
     "Creating a CRL with freshestCRL extension doesn't corrupt the NID registry");
};

skip_next_test if cannot_check_bytes_leaks;
test "extension registry memory leak" => sub {
    leaks_bytes_ok {
        for(1..50000) {
            Crypt::OpenSSL::CA::X509
                ->extension_by_name("basicConstraints");
        }
    };
};

test "monkeying with ->set_extension and ->add_extension in various ways"
=> sub {
    my $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
    eval (My::Tests::Below->pod_code_snippet
          ("nice try with set_extension, no cigar")
          . 'fail("should have thrown");');
    my $exn = $@;
    eval {
        $cert->add_extension(undef, "WTF");
        fail("should have thrown");
    };
    isnt($@, '', "congratulations, you dodged a SEGV!");
    eval {
        $cert->add_extension("subjectKeyIdentifier", undef);
        fail("should have thrown");
    };
    isnt($@, '', "... again!");
    eval {
        $cert->add_extension("crlNumber", 4);
    };
    like($@, qr/unknown|unsupported/i, <<WITTY_COMMENT);
You definitely shouldn't be able to set the crlNumber of a certificate.
WITTY_COMMENT
};

skip_next_test if cannot_check_bytes_leaks;
test "no leak on ->set_extension called multiple times" => sub {
    my $longstring = "00:DE:AD:BE:EF" x 200;
    my $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
    leaks_bytes_ok {
        for (1..200) {
            $cert->set_extension("subjectKeyIdentifier", $longstring);
            $cert->sign($cakey, "sha1");
        }
    };
    leaks_bytes_ok {
        for (1..40) {
            for (1..5) {
                $cert->set_extension("subjectKeyIdentifier", $longstring);
                $cert->sign($cakey, "sha1");
            }
        }
    };
};

use Crypt::OpenSSL::CA::Test qw(@test_DN_CAs);

# Part of this function's code is in the POD.  Compile it once here,
# rather than call eval() in a leaks_bytes_ok loop.
*call_pod_snippets_with_set_extensions = do {
  my $code_from_pod = My::Tests::Below->pod_code_snippet
    ("set_extension subjectKeyIdentifier");
  $code_from_pod .= My::Tests::Below->pod_code_snippet
    ("set_extension authorityKeyIdentifier");
  $code_from_pod .= My::Tests::Below->pod_code_snippet
    ("set_extension certificatePolicies");
  return (eval(sprintf(<<'GENERATED_SUB',  $code_from_pod)) or die $@);
sub {
    my ($cert) = @_;

    my $dnobj = Crypt::OpenSSL::CA::X509_NAME->new
         (CN => "bogus issuer");

    {
      package Bogus::CA;
      sub get_subject_keyid { return "00:DE:AD:BE:EF" }
      sub get_issuer_dn { return shift->{dn} }
      sub get_serial { return "0x1234" }
    }
    my $ca = bless { dn => $dnobj }, "Bogus::CA";

    %s
}
GENERATED_SUB
};

sub christmasify_cert {
    my ($cert) = @_;
    $cert->set_serial("0x1234567890abcdef1234567890ABCDEF");

    $cert->set_subject_DN
        (Crypt::OpenSSL::CA::X509_NAME->new
         (CN => "coucou", "2.5.4.11.1.2.3.4" => "who cares?"));
    $cert->set_issuer_DN
        (Crypt::OpenSSL::CA::X509_NAME->new(@test_DN_CAs));

    $cert->set_notBefore("20060108000000Z");
    $cert->set_notAfter("21060108000000Z");
    $cert->set_extension("basicConstraints", "CA:FALSE",
                         -critical => 1);
    call_pod_snippets_with_set_extensions($cert);
    # 'mkay, but if we want the path validation to succeed we'd better
    # use a non-deadbeef authority key id, so here we go again:
    my $keyid = Crypt::OpenSSL::CA::X509
        ->parse($test_self_signed_certs{"rsa1024"})
            ->get_public_key->get_openssl_keyid;
    $cert->set_extension("authorityKeyIdentifier", { keyid => $keyid },
                         -critical => 0); # RFC3280 section 4.2.1.1

    $cert->set_extension
       (subjectAltName =>
        'email:johndoe@example.com,email:johndoe@example.net');
}

# christmasify_cert runs the POD snippets and that's neat, but we
# want to call Perl's eval only once for fear of memory leakage in
# Perl.

test "Authority key identifier" => sub {
    my $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
    $cert->set_extension("authorityKeyIdentifier",
                         { keyid => "DE:AD:BE:EF" });
    my $pem = $cert->sign($cakey, "sha1");
    my $certdump = run_thru_openssl($pem, qw(x509 -noout -text));
    unlike($certdump, qr/issuer/,
         "authority key ID sans issuer + serial");
    like($certdump, qr/de.ad.be.ef/i, "authority key id");

    $cert->set_extension
        ("authorityKeyIdentifier" =>
         { issuer => Crypt::OpenSSL::CA::X509_NAME->new
           (CN => "bogus issuer"),
           serial => "0x1234abcd" });
    $pem = $cert->sign($cakey, "sha1");
    $certdump = run_thru_openssl($pem, qw(x509 -noout -text));
    like($certdump, qr/bogus issuer/,
         "authority key ID sans issuer + serial");
    like($certdump, qr/12.?34.?ab.?cd.?/i,
         "authority key ID sans issuer + serial, redux");
    unlike($certdump, qr/keyid/i, "authority key id");

    $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
    call_pod_snippets_with_set_extensions($cert);
    $pem = $cert->sign($cakey, "sha1");
    $certdump = run_thru_openssl($pem, qw(x509 -noout -text));
    like($certdump, qr/bogus issuer/,
         "authority key ID as issuer + serial");
    like($certdump, qr/12.?34.?ab.?cd.?/i,
         "authority key ID as issuer + serial, redux");
    like($certdump, qr/de.ad.be.ef/i, "authority key id");
};

test "Christmas tree certificate" => sub {
    my $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
    christmasify_cert($cert);
    my $pem = $cert->sign($cakey, "sha1");
    certificate_looks_ok($pem);

    my $certdump = run_thru_openssl($pem, qw(x509 -noout -text));
    like($certdump, qr/12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF/i,
         "big hex serial");
    like($certdump, qr/Issuer:.*Widgits/, "issuer DN");
    like($certdump, qr/Subject:.*who cares/, "subject DN");
    like($certdump, qr/basic.*constraints.*critical.*\n.*CA:FALSE/i,
         "Critical basicConstraints");
    like($certdump, qr/example.com/, "subjectAltName 1/2");
    like($certdump, qr/example.net/, "subjectAltName 2/2");
    like($certdump, qr/Subject Key Identifier.*\n.*DE.AD.BE.EF/i,
         "subject key ID");
    like($certdump, qr/Authority Key Identifier/i,
         "authority key ID");
    unlike($certdump,
           qr/Authority Key Identifier.*critical.*\n.*DE.AD.BE.EF/i,
           "authority key ID *must not* be the same as subject key ID");
    like($certdump, qr|Policy: 1.5.6.7.8|i, "policy identifiers 1/4");
    like($certdump, qr|CPS: http://my.host.name/|i,
         "policy identifiers 2/4");
    like($certdump, qr|Numbers: 1, 2, 3, 4|i,
         "policy identifiers 3/4");
    like($certdump, qr|Explicit Text: Explicit Text Here|i,
         "policy identifiers 4/4");

    if (dumpasn1_available()) {
      my $dumpasn1 = run_dumpasn1
        (run_thru_openssl($pem, qw(x509 -outform der)));
      like($dumpasn1, qr/UTCTime.*2006.*\n.*GeneralizedTime.*2106/,
           "Proper detection of time format");
    }
};

test "Christmas tree validates OK in certificate chain" => sub {
    my $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
    christmasify_cert($cert);
    my $pem = $cert->sign($cakey, "sha1");
    certificate_chain_ok($pem, [ $test_rootca_certs{rsa1024} ]);
};

skip_next_test if cannot_check_bytes_leaks;
test "X509 memory leaks" => sub {
    leaks_bytes_ok {
        for(1..100) {
            my $cert = Crypt::OpenSSL::CA::X509->new($eepubkey);
            for(1..200) { # Checks for robustness and leaks
                christmasify_cert($cert);
            }
            $cert->sign($cakey, "sha1");
        }
        for(1..100) {
            my $cert = Crypt::OpenSSL::CA::X509->parse
                ($test_self_signed_certs{rsa1024});
            for(1..200) {
                christmasify_cert($cert);
            }
            $cert->sign($cakey, "sha1");
        }
    };
};

=head2 CRL tests

=cut

my $crl_issuer_dn = Crypt::OpenSSL::CA::X509_NAME->new(@test_DN_CAs);

test "CRLv1" => sub {
    my $crl = new Crypt::OpenSSL::CA::X509_CRL("CRLv1");
    ok($crl->isa("Crypt::OpenSSL::CA::X509_CRL"));
    ok(! $crl->is_crlv2);
    $crl->set_issuer_DN($crl_issuer_dn);
    $crl->set_lastUpdate("20070101000000Z");
    $crl->set_nextUpdate("20570101000000Z");
    $crl->add_entry("0x10", "20070212100000Z");

    my $crlpem = $crl->sign($cakey, "sha1");
    my ($crldump, $err) =
        run_thru_openssl($crlpem, qw(crl -noout -text));
    is($?, 0, "``openssl crl'' ran successfully")
        or die $err;
    like($crldump, qr/Version 1/, "CRLv1");
    like($crldump, qr/Issuer.*Internet Widgits/, "Issuer name");
    like($crldump, qr/last update.*2007/i, "Last update");
    like($crldump, qr/next update.*2057/i, "Next update");

    eval {
        $crl->set_extension("authorityKeyIdentifier", { keyid => "de:ad:be:ef" });
        fail("Should have thrown");
    };
    like(Dumper($@), qr/extension/i);

    eval {
        $crl->add_entry("0x11", "20070212100000Z",
                        -reason => "cessationOfOperation");
        fail("Should have thrown");
    };
    like(Dumper($@), qr/extension/i);
    like(Dumper($@), qr/crlv1/i);
};

sub christmasify_crl {
    my ($crl) = @_;
    $crl->set_issuer_DN($crl_issuer_dn);
    $crl->set_lastUpdate("20070101000000Z");
    $crl->set_nextUpdate("20570101000000Z");

    $crl->set_extension("authorityKeyIdentifier",
                        { keyid => "de:ad:be:ef",
                          issuer => $crl_issuer_dn,
                          serial => "0x41" });
    $crl->set_extension("crlNumber", "0x42deadbeef42", -critical => 1);

    $crl->set_extension("freshestCRL",
                        "URI:http://www.example.com/deltacrl.crl",
                        -critical => 0);
}

sub add_entries_to_crl {
    my ($crl) = @_;
    $crl->add_entry("0x10", "20070212100000Z");
    $crl->add_entry("0x11", "20070212100100Z", -reason => "unspecified");
    $crl->add_entry("0x42deadbeef32", "20070212090100Z",
                    -hold_instruction => "holdInstructionPickupToken");
    $crl->add_entry("0x12", "20070212100200Z", -reason => "keyCompromise",
                    -compromise_time => "20070210000000Z");
}

test "Christmas-tree CRL" => sub {
    my $crl = Crypt::OpenSSL::CA::X509_CRL->new();
    ok($crl->is_crlv2);
    christmasify_crl($crl);
    add_entries_to_crl($crl);
    my $crlpem = $crl->sign($cakey, "sha1");
    my ($crldump, $err) =
        run_thru_openssl($crlpem, qw(crl -noout -text));
    is($?, 0, "``openssl crl'' ran successfully")
        or die $err;
    like($crldump, qr/last update:.*2007/i);
    like($crldump, qr/next update:.*2057/i);
    like($crldump, qr/keyid.*DE:AD:BE:EF/);
    like($crldump, qr/CRL Number.*critical/i);
    # Right now OpenSSL cannot parse freshest CRL indicator:
    like($crldump, qr/deltacrl\.crl/);

    my @crlentries = split m/Serial Number: /, $crldump;
    shift(@crlentries); # Leading garbage
    my %crlentries;
    for(@crlentries) {
        if (! m/^([0-9A-F]+)(.*)$/si) {
            fail("Incorrect CRL entry\n$_\n");
            next;
        }
        $crlentries{uc($1)} = $2;
    }
    like($crlentries{"10"}, qr/Feb 12/, "revocation dates");
    like($crlentries{"11"}, qr/unspecified/i) or do {
        my $dumpasn1 = run_dumpasn1
            (run_thru_openssl($crlpem, qw(crl -outform der)));
        warn $dumpasn1;
    };
    like($crlentries{"12"}, qr/key.*compromise/i);
    like($crlentries{"12"}, qr/Invalidity Date/i);
    like($crlentries{"42DEADBEEF32"}, qr/hold/i)
        or warn $crldump;
};

skip_next_test if cannot_check_bytes_leaks;
test "CRL memory leaks" => sub {
    leaks_bytes_ok {
        for(1..100) {
            my $crl = Crypt::OpenSSL::CA::X509_CRL->new();
            for(1..200) { # Checks for robustness and leaks
                christmasify_crl($crl);
            }
            for(1..20) { # Not too many entries, as that would cause
                # false positives
                add_entries_to_crl($crl);
            }
            $crl->sign($cakey, "sha1");
        }
    };
};


=head2 Synopsis test

We only check that it runs.  Thorough black-box testing of
I<Crypt::OpenSSL::CA> happens in C<t/> instead.

=cut

test "synopsis" => sub {
    my $synopsis = My::Tests::Below->pod_code_snippet("synopsis");
    $synopsis = <<'PREAMBLE' . $synopsis;
my $pem_private_key = $test_keys_plaintext{rsa1024};
PREAMBLE
    eval $synopsis; die $@ if $@;
    pass;
};

=head2 Obsolete stuff

Yet still under test.

=cut

test "obsolete ::PrivateKey->get_RSA_modulus" => sub {
    my $key = Crypt::OpenSSL::CA::PrivateKey
        ->parse($test_keys_plaintext{rsa1024});

    is($key->get_RSA_modulus, $key->get_public_key->get_modulus);
};

test "obsolete ::X509->set_serial_hex" => sub {
    my $cert = Crypt::OpenSSL::CA::X509->new
        (Crypt::OpenSSL::CA::PublicKey
         ->parse_RSA($test_public_keys{rsa1024}));
    $cert->set_serial_hex("abcd1234");
    is($cert->get_serial, "0xabcd1234");
};

test "obsolete authorityKeyIdentifier_keyid extension" => sub {
    my $pubkey = Crypt::OpenSSL::CA::PublicKey
        ->parse_RSA($test_public_keys{rsa1024});
    my $privkey = Crypt::OpenSSL::CA::PrivateKey
        ->parse($test_keys_plaintext{rsa1024});

    my $x509 = Crypt::OpenSSL::CA::X509->new($pubkey);
    $x509->set_extension("authorityKeyIdentifier_keyid", "de:ad:be:ef");
    $x509->sign($privkey, "sha1");
    like($x509->dump, qr/de.ad.be.ef/i);

    my $crl = Crypt::OpenSSL::CA::X509_CRL->new();
    $crl->set_extension("authorityKeyIdentifier_keyid", "de:ad:be:ef");
    $crl->sign($privkey, "sha1");
    like($crl->dump, qr/de.ad.be.ef/i);
};

=head2 Symbol leakage test

Validates that no symbols are leaked at the .so interface boundary, as
documented in L</the static-newline trick>.  This test must be kept
after all XS tests, as it needs all relevant .so modules loaded.

=cut

use DynaLoader;
test "symbol leak" => sub {
    is(DynaLoader::dl_find_symbol_anywhere($_), undef,
       "symbol $_ not visible")
        for(qw(sslcroak new load parse to_string to_asn1 sign DESTROY));
};

