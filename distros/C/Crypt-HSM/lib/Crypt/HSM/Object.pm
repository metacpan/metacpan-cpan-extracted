package Crypt::HSM::Object;
$Crypt::HSM::Object::VERSION = '0.032';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 object

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Object - A PKCS11 object

=head1 VERSION

version 0.032

=head1 SYNOPSIS

 my ($key) = $session->find_objects({ label => $label, encrypt => 1 });
 if (not $key) {
    my %attrs = { label => $label, sensitive => 1, "value-len" => 32 };
    $key = $session->generate_key('aes-key-gen', \%attrs);
 }
 $session->encrypt('aes-gcm', $key, $plaintext, $nonce);

=head1 DESCRIPTION

This class represents an object (usually a key) in the HSM's database. The type of the object us stored in the C<class> attribute, this type will define what other attributes are available for it.

It's returned by L<Crypt::HSM::Session|Crypt::HSM::Session> methods like C<find_object> and C<generate_key>, and used in methods such as C<encrypt>, C<decrypt>, C<sign> and C<verify>.

=head1 METHODS

=head2 copy_object($attributes = {})

Copy the object, optionally adding/modifying the given attributes.

=head2 destroy_object()

This deletes this object from the slot.

=head2 get_attribute($attribute_name)

This returns the value of the named attribute of the object.

=head2 get_attributes(@attribute_list)

This returns a hash with the attributes of the object that are asked for.

=head2 object_size()

This returns the size of this object.

=head2 set_attributes($attributes)

This sets the C<$attributes> on this object.

=head1 ATTRIBUTES

=head2 Universal attributes

Only one attribute is present in all objects:

=over 4

=item * C<class>

This enum value van be one of C<data>, C<certificate>, C<public-key>, C<private-key>, C<secret-key>, C<hw-feature>, C<domain-parameters>, C<mechanism>, C<profile>, C<validation>, C<trust>, or C<vendor-defined>.

=back

=head2 Storage objects

All certificate, key, en data objects are storage objects and contain the following attributes:

=over 4

=item * C<token>

True if the object is a token object, false if the object is a session object.

=item * C<private>

If true, a user may not access the object until the user has been authenticated to the token.

=item * C<modifiable>

If true (the default) the object can be modified.

=item * C<label>

Description of the object (default empty).

=item * C<copyable>

True if object can be copied using C<copy_object>. Defaults to true. Can’t be set to true once it is set to false.

=item * C<destroyable>

True if the object can be destroyed using destroy_object.  Default is true.

=item * C<unique-id>

The unique identifier assigned to the object.

=back

Of these attributes, only C<label> may be modified after the object is created.

=head3 Certificates

Several attributes are shared between all certificate types:

=over 4

=item * C<certificate-type>

This can be any of C<x-509>, C<x-509-attr-cert>, C<wtls> or C<vendor-defined>.

=item * C<trusted>

True if the certificate can be trusted for the application that it was created. It MUST be set by a token initialization application or by the token’s SO. Trusted certificates cannot be modified.

=item * C<certificate-category>

This can be any of C<unspecified>, C<token-user>, C<authority> or C<other-entity>.

=item * C<check-value>

The checksum of the certificate.

=item * C<start-date>

Start date for the certificate.

=item * C<end-date>

End date for the certificate.

=item * C<public-key-info>

DER-encoding of the SubjectPublicKeyInfo for the public key contained in this certificate.

=back

=head4 X509 certificates

=over 4

=item * C<subject>

DER-encoding of the certificate subject name.

=item * C<id>

Key identifier for public/private key pair.

=item * C<issuer>

DER-encoding of the certificate issuer name.

=item * C<serial-number>

DER-encoding of the certificate serial number.

=item * C<value>

BER-encoding of the certificate. MUST be non-empty if C<url> is empty.

=item * C<url>

If not empty this attribute gives the URL where the complete certificate can be obtained. MUST be non-empty if C<value> is empty.

=item * C<hash-of-subject-public-key>

Hash of the subject public key (default empty). Hash algorithm is defined by C<name-hash-algorithm>.

=item * C<hash-of-issuer-public-key>

Hash of the issues public key (default empty). Hash algorithm is defined by C<name-hash-algorithm>.

=item * C<java-midp-security-domain>

Java MIDP security domain. This must be one of C<unspecified>, C<manufacturer>, C<operator> or C<third-party>.

=item * C<name-hash-algorithm>

Defines the mechanism used to calculate C<hash-of-subject-public-key> and C<hash-of-issues-public-key>. If the attribute is not present then the type defaults to SHA-1.

=back

=head4 WTLS certificates

=over 4

=item * C<subject>

DER-encoding of the certificate subject name.

=item * C<issuer>

DER-encoding of the certificate issuer name.

=item * C<value>

WTLS-encoding of the certificate. MUST be non-empty if C<url> is empty.

=item * C<url>

If not empty this attribute gives the URL where the complete certificate can be obtained. MUST be non-empty if C<value> is empty.

=item * C<hash-of-subject-public-key>

Hash of the subject public key (default empty). Hash algorithm is defined by C<name-hash-algorithm>.

=item * C<hash-of-issuer-public-key>

Hash of the issues public key (default empty). Hash algorithm is defined by C<name-hash-algorithm>.

=item * C<name-hash-algorithm>

Defines the mechanism used to calculate C<hash-of-subject-public-key> and C<hash-of-issues-public-key>. If the attribute is not present then the type defaults to SHA-1.

=back

=head4 X509 attribute certificates

=over 4

=item * C<owner>

DER-encoding of the attribute certificate's subject field. This is distinct from the C<subject> attribute contained in X509 certificates because the ASN.1 syntax and encoding are different.

=item * C<ac-issuer>

DER-encoding of the attribute certificate's issuer field. This is distinct from the C<issuer> attribute contained in X509 certificates because the ASN.1 syntax and encoding are different.

=item * C<serial-number>

DER-encoding of the certificate serial number.

=item * C<attr-types>

BER-encoding of a sequence of object identifier values corresponding to the attribute types contained in the certificate. When present, this field offers an opportunity for applications to search for a particular attribute certificate without fetching and parsing the certificate itself. (default empty).

=item * C<value>

BER-encoding of the certificate.

=back

=head3 Key objects

All key types share the following attributes:

=over 4

=item * C<key-type>

The type of the key. Valid values include: C<rsa>, C<dsa>, C<dh>, C<ec>, C<ecdsa>, C<x9-42-dh>, C<kea>, C<generic-secret>, C<rc2>, C<rc4>, C<des>, C<des2>, C<des3>, C<cast>, C<cast3>, C<cast128>, C<cast5>, C<rc5>, C<idea>, C<skipjack>, C<baton>, C<juniper>, C<cdmf>, C<aes>, C<blowfish>, C<twofish>, C<securid>, C<hotp>, C<acti>, C<camellia>, C<aria>, C<md5-hmac>, C<sha1-hmac>, C<ripemd128-hmac>, C<ripemd160-hmac>, C<sha256-hmac>, C<sha384-hmac>, C<sha512-hmac>, C<sha224-hmac>, C<seed>, C<gostr3410>, C<gostr3411>, C<gost28147>, C<chacha20>, C<poly1305>, C<aes-xts>, C<sha3-224-hmac>, C<sha3-256-hmac>, C<sha3-384-hmac>, C<sha3-512-hmac>, C<blake2b-160-hmac>, C<blake2b-256-hmac>, C<blake2b-384-hmac>, C<blake2b-512-hmac>, C<salsa20>, C<x2ratchet>, C<ec-edwards>, C<ec-montgomery>, C<hkdf>, C<sha512-224-hmac>, C<sha512-256-hmac>, C<sha512-t-hmac>, C<hss>, C<xmss>, C<xmssmt>, C<ml-kem>, C<ml-dsa>, C<slh-dsa>, and C<vendor-defined>

=item * C<id>

Key identifier for key.

=item * C<start-date>

Start date for the key.

=item * C<end-date>

End date for the key.

=item * C<derive>

True if key supports key derivation (i.e., if other keys can be derived from this one).

=item * C<local>

True only if key was either:

=over 2

=item * Generated locally (i.e., on the token) with a C<generate_key> or C<generate_keypair> call.

=item * Created with a C_CopyObject call as a copy of a key which had its C<local> attribute set to true.

=back

=item * C<key-gen-mechanism>

The L<mechanism|Crypt::HSM::Mechanism> used to generate a new value of this key type.

=item * C<allowed-mechanisms>

An arrayref of L<mechanisms|Crypt::HSM::Mechanism> that can be used with this key type.

=item * C<parameter-set>

This represents the parameter set of a cryptographic operation. The meaning of this integer depends on the involved algorithm. For some algoritms, textual input aliases are defined:

For C<ml-dsa> the following parameter sets are defined: C<mk-dsa-44> (C<1>), C<ml-dsa-65> (C<2>), and C<ml-dsa-87> (C<3>).

For C<slh-dsa> the following parameter sets are defined: C<slh-dsa-sha2-128s> (C<1>), C<slh-dsa-shake-128s> (C<2>), C<slh-dsa-sha2-128f> (C<3>), C<slh-dsa-shake-128f> (C<4>), C<slh-dsa-sha2-192s> (C<5>), C<slh-dsa-shake-192s> (C<6>), C<slh-dsa-sha2-192f> (C<7>), C<slh-dsa-shake-192f> (C<8>), C<slh-dsa-sha2-256s> (C<9>), C<slh-dsa-shake-256s> (C<10>), C<slh-dsa-sha2-256f> (C<11>), C<slh-dsa-shake-256f> (C<12>) are defined.

For C<ml-kem> the following parameter sets are defined: C<ml-kem-512> (C<1>), C<ml-kem-768> (C<2>), C<ml-kem-1024> (C<3>)

For C<xmms> and C<xmssmt>, valid values are defined by I<NIST SP800-208>.

=back

=head3 Public key objects

=over 4

=item * C<subject>

DER-encoding of the key subject name.

=item * C<encrypt>

True if key supports encryption.

=item * C<verify>

True if key supports verification where the signature is an appendix to the data.

=item * C<verify-recover>

True if key supports verification where the data is recovered from the signature.

=item * C<wrap>

True if key supports wrapping (i.e., can be used to wrap other keys).

=item * C<trusted>

The key can be trusted for the application that it was created.

The wrapping key can be used to wrap keys with C<wrap-with-trusted> set to true.

=item * C<wrap-template>

For wrapping keys. The attribute template to match against any keys wrapped using this wrapping key. Keys that do not match cannot be wrapped.

=item * C<public-key-info>

DER-encoding of the SubjectPublicKeyInfo for the public key contained in this certificate.

=back

=head3 Private key objects

=over 4

=item * C<subject>

DER-encoding of certificate subject name.

=item * C<sensitive>

True if key is sensitive.

=item * C<decrypt>

True if key supports C<decrypt>.

=item * C<sign>

True if key supports C<sign>.

=item * C<sign-recover>

True if key supports C<sign_recover>.

=item * C<unwrap>

True if key supports C<unwrap>.

=item * C<extractable>

True if key is extractable and can be wrapped.

=item * C<always-sensitive>

True if key has always had the C<sensitive> attribute set to true.

=item * C<never-extractable>

True if key has never had the C<extractable> attribute set to true.

=item * C<wrap-with-trusted>

True if the key can only be wrapped with a wrapping key that has C<trusted> set to true.

=item * C<unwrap-template>

For wrapping keys. The attribute template to apply to any keys unwrapped using this wrapping key. Any user supplied template is applied after this template as if the object has already been created.

=item * C<always-authenticate>

If true, the user has to supply the PIN for each use (sign or decrypt) with the key. Default is false.

=item * C<public-key-info>

DER-encoding of the SubjectPublicKeyInfo for the public key contained in this certificate.

=item * c<derive-template>

For deriving keys. The attribute template to match against any keys derived using this derivation key. Any user supplied template is applied after this template as if the object has already been created.

=back

=head4 RSA private key objects

=over 4

=item * C<modulus>

Modulus n

=item * C<public-exponent>

Public exponent e.

=item * C<private-exponent>

Private exponent d.

=item * C<prime-1>

Prime p.

=item * C<prime-2>

Prime q.

=item * C<exponent-1>

Private exponent d modulo p-1.

=item * C<exponent-2>

Private exponent d modulo q-1.

=item * C<coefficient>

CRT coefficient q-1 mod p.

=back

=head3 Secret key objects

=over 4

=item * C<sensitive>

True if key is sensitive.

=item * C<encrypt>

True if key supports C<encrypt>.

=item * C<decrypt>

True if key supports C<decrypt>.

=item * C<sign>

True if key supports C<sign>.

=item * C<verify>

True if key supports C<verify> (i.e., of authentication codes) where the signature is an appendix to the data.

=item * C<wrap>

True if key supports C<wrap> (i.e., can be used to wrap other keys).

=item * C<unwrap>

True if key supports C<unwrap> (i.e., can be used to unwrap other keys).

=item * C<extractable>

True if key is extractable and can be wrapped.

=item * C<always-sensitive>

True if key has always had the C<sensitive> attribute set to true.

=item * C<never-extractable>

True if key has never had the C<extractable> attribute set to true.

=item * C<check-value>

Key checksum.

=item * C<wrap-with-trusted>

True if the key can only be wrapped with a wrapping key that has C<trusted> set to true.

=item * C<trusted>

The wrapping key can be used to wrap keys with C<wrap-with-trusted> set to true.

=item * C<wrap-template>

For wrapping keys. The attribute template to match against any keys wrapped using this wrapping key. Keys that do not match cannot be wrapped.

=item * C<unwrap-template>

For wrapping keys. The attribute template to apply to any keys unwrapped using this wrapping key. Any user supplied template is applied after this template as if the object has already been created.

=item * c<derive-template>

For deriving keys. The attribute template to match against any keys derived using this derivation key. Any user supplied template is applied after this template as if the object has already been created.

=back

=head3 Data objects

=over 4

=item * C<application>

Description of the application that manages the object.

=item * C<object-id>

DER-encoding of the object identifier indicating the data object type.

=item * C<value>

Value of the object.

=back

=head3 Domain parameter objects

=over 4

=item * C<key-type>

Type of key the domain parameters can be used to generate.

=item * C<local>

True only if key was either:

=over 2

=item * Generated locally (i.e., on the token) with a C<generate_key> or C<generate_keypair> call.

=item * Created with a C<copy-object> call as a copy of a key which had its C<local> attribute set to true.

=back

=back

=head3 Mechanism objects

=over 4

=item * C<mechanism-type>

The L<mechanism|Crypt::HSM::Mechanism> object.

=back

=head3 Profile options

=over 4

=item * C<profile-id>

This can be C<baseline-provider>, C<extended-provider>,	C<authentication-token>, C<public-certificates-token>, C<complete-provider>, C<hkdf-tls-token>, C<vendor-provided>, or C<invalid-id>.

=back

=head3 Hardware objects

=over 4

=item * C<hardware-feature-type>

This can be one of C<monotonic-counter>, C<clock>, C<user-interface>, C<vendor-defined>.

=back

=head4 Monotonic counter

=over 4

=item * C<reset-on-init>

The value of the counter will reset to a previously returned value if the token is initialized using C<init-token>.

=item * C<has-reset>

The value of the counter has been reset at least once at some point in time.

=item * C<value>

The current version of the monotonic counter. The value is returned in big endian order.

=back

=head4 Clock

=over 4

=item * C<value>

Current time as a character-string of length 16, represented in the format YYYYMMDDhhmmssxx (4 characters for the year;  2 characters each for the month, the day, the hour, the minute, and the second; and 2 additional reserved ‘0’ characters).

=back

=head4 User Interface

=over 4

=item * C<pixel-x>

Screen resolution (in pixels) in X-axis (e.g. 1280).

=item * C<pixel-y>

Screen resolution (in pixels) in Y-axis (e.g. 1024).

=item * C<resolution>

DPI, pixels per inch.

=item * C<char-rows>

For character-oriented displays; number of character rows (e.g. 24).

=item * C<char-columns>

For character-oriented displays: number of character columns (e.g. 80). If display is of proportional-font type, this is the width of the display in “em”-s (letter “M”).

=item * C<color>

Color support.

=item * C<bits-per-pixel>

The number of bits of color or grayscale information per pixel.

=item * C<char-sets>

String indicating supported character sets, as defined by IANA MIBenum sets (www.iana.org). Supported character sets are separated with “;”. E.g. a token supporting iso-8859-1 and US-ASCII would set the attribute value to “4;3”.

=item * C<encoding-methods>

String indicating supported content transfer encoding methods, as defined by IANA (www.iana.org). Supported methods are separated with “;”. E.g. a token supporting 7bit, 8bit and base64 could set the attribute value to “7bit;8bit;base64”.

=item * C<mime-types>

String indicating supported (presentable) MIME-types, as defined by IANA (www.iana.org). Supported types are separated with “;”. E.g. a token supporting MIME types "a/b", "a/c" and "a/d" would set the attribute value to “a/b;a/c;a/d”.

=back

=head3 Validation objects

Validation objects describe which third party validations the module conforms to. Validation objects are read only, token objects.

The have the following attributes:

=over 4

=item * C<validation-type>

Identifier indicating the validation type. This must be one of: C<unspecified>, C<software>, C<hardware>, C<firmware> or C<hybrid>

=item * C<validation-version>

Version of the validation standard or specification

=item * C<validation-level>

Validation level, Meaning is Validation type specific

=item * C<validation-module-id>

How the module is identified in the validation documentation

=item * C<validation-flag>

Flags identifying this validation in sessions and objects

=item * C<validation-authority-type>

Identifies the authority that issues the validation. This must be one of: C<unspecified>, C<nist-cmvp> or C<common-criteria>.

=item * C<validation-country>

2 letter ISO country code

=item * C<validation-certificate-identifier>

Identifier of the validation certificate

=item * C<validation-certificate-uri>

Validation authority URI from which information related to the validation is available. If the Validation Certificate URI is not provided, the validation object SHOULD include a Validation Vendor URI.

=item * C<validation-vendor-uri>

Validation Vendor URI from which information related to the validation is available.

=item * C<validation-profile>

Profile used for validation

=back

=head3 Trust objects

Trust objects bind trusted usages to individual certificates. Trust objects for a given certificate are accessed using the C<issuer> and C<serial-number> attributes, and may be confirmed by comparing C<hash-of-certificate> with a recomputed hash value. The corresponding certificate does not necessarily have to exist in the same token as its trust object. Multiple trust objects for the same certificate can exist in different tokens, but each token should have no more than one trust object for a given certificate.

The have the following attributes:

=over 4

=item * C<issuer>

DER-encoding of the certificate issuer name (default empty)

=item * C<serial-number>

DER-encoding of the certificate serial number (default empty)

=item * C<hash-of-certificate>

Cryptographic hash of the certificate computed by C<name-hash-algorithm> (default empty)

=item * C<name-hash-algorithm>

Mechanism used to calculate hash-of-certificate (defaults to SHA-1 if not present)

=item * C<trust-server-auth>

Trust for authenticating the server in a client/server interaction (as in TLS/SSL/SSH)

=item * C<trust-client-auth>

Trust for authenticating the client in a client/server interaction (as in TLS/SSL/SSH)

=item * C<trust-code-signing>

Trust for authenticating a code fragment

=item * C<trust-email-protection>

Trust for authenticating an email user

=item * C<trust-ipsec-ike>

Trust for IPSEC

=item * C<trust-time-stamping>

Trust for timestamping

=item * C<trust-ocsp-signing>

Trust for OCSP Signing

=back

The C<trust-> values

=over 4

=item * C<trusted>

The certificate is trusted for the associated operation.

=item * C<trust-anchor>

The certificate is trusted as a root signing certificate for chain validation of a cert that is trusted for the associate operation; this applies even when the certificate is not self-signed and when the certificate does not have the proper attributes to be CA certificate.

=item * C<not-trusted>

The certificate is explicitly not trusted for the associated operation, nor can trust chain through the certificate to an otherwise trusted root; this attribute can be used to ‘revoke’ intermediate CA certificates that have been compromised without removing trust from the parent certificate.

=item * C<trust-must-verify-trust>

The certificate is neither trusted nor untrusted for the associated operation.

=item * C<trust-unknown>

The certificate is neither trusted nor untrusted for the associated operation.

=back

To obtain the effective trust attributes for a given certificate, the typical application will first:

=over 4

=item 1. identify the tokens containing a Trust object with matching CKA_ISSUER and CKA_SERIAL_NUMBER (and optionally check that CKA_HASH_OF_CERTIFICATE agrees with the hash of the certificate computed using CKA_NAME_HASH_ALGORITHM),

=item 2. determine which of those Trust objects should be processed (presumably according to an established security policy), and

=item 3. arrange the selected Trust objects in a list sorted in order of increasing priority.

=back

Now, taking the first Trust object in the list as the initial working Trust object (WTO) with all omitted attributes assumed to have the value C<trust-unknown>, the remaining Trust objects in the list are iteratively merged into it as follows:

=over 4

=item 1. if the value of a trust attribute in the current object is CKT_TRUST_UNKNOWN, that attribute is left unchanged in the WTO,

=item 2. otherwise, the current attribute value replaces the attribute value in the WTO .

=back

Note that at any step of this process, an attribute value of CKT_TRUST_MUST_VERIFY_TRUST in the current Trust object resets any trust or distrust assigned to that attribute in the WTO by a lower priority token.

When the process is complete, the final (“effective”) trust attribute values are to be interpreted as follows:

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
