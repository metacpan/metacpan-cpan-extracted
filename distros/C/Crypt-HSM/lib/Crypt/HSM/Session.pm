package Crypt::HSM::Session;
$Crypt::HSM::Session::VERSION = '0.016';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 session

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Session - A PKCS11 session

=head1 VERSION

version 0.016

=head1 SYNOPSIS

 $session->encrypt('aes-cbc', $key, $plaintext, $iv);

 $session->sign('sha256-hmac', $key, $data);

 $session->verify('sha256-rsa-pkcs', $key, $data, $signature);

 my $key = $session->generate_key($type, { token => 1, sensitive => 1 });

 my @keys = $session->find_objects({ class => 'secret-key' });

 my $attrs = $session->get_attributes($key, [ 'private', 'sensitive' ]);

=head1 DESCRIPTION

This represents a session with a PKCS module such as an HSM. It does most of the cryptographic work of using a PKCS11 interface.

=head2 Constants

This module uses hundreds of constants from the PKCS11 standard as short stings. They're all lowercased, without prefix and with hyphens instead of underscores. So C<CKM_SHA256_RSA_PKCS> becomes C<'sha256-rsa-pkcs'>. In KDF names, the <-kdf> part is eliminated.

=head2 Types

Various types of arguments are recurring its methods, these are:

=over 4

=item key/object

This is an identifier that refers to resource inside the HSM, it has no meaning outside of it.

=item mechanism

This is a mechanism for a cryptographic operation, e.g. C<'aes-gcm'>, C<'sha256-rsa-pkcs'> or C<'sha512-hmac'>. The list of supported mechanisms can be retrieved using the C<mechanisms> method on the C<Crypt::HSM> object.

Cryptographic methods taking taking an argument will also take zero or more mechanism specific arguments after their generic arguments, for example an IV or nonce for a symmetric cipher that uses such, or a public key for a Diffie-Hellman derivation.

=item attributes

This is an hash of attributes. The key is the name of the attribute (e.g. C<'class'>, C<'sensitive'>), the value depends on the key but is usually either an integer, a string or a bool.

=back

=head1 METHODS

=head2 copy_object($object, $attributes)

Copy an object, optionally adding/modifying the given attributes.

=head2 create_object($attributes)

Create an object with the given C<$attribute> hash.

=head2 decrypt($mechanism, $key, $ciphertext, ...)

Decrypt C<$ciphertext> with C<$mechanism> and C<$key>.

=head2 derive_key($mechanism, $key, $attributes, ...)

Derive a new key from C<$key>, using mechanism and setting C<$attributes> on it.

=head2 destroy_object($object)

This deletes the object with the identifier C<$object>.

=head2 digest($mechanism, $key, $input, ...)

Digest C<$input> with C<$mechanism> and C<$key>.

=head2 encrypt($mechanism, $key, $plaintext, ...)

Encrypt C<$plaintext> with C<$mechanism> and C<$key>.

=head2 find_objects($attributes)

Find all objects that satisfy the given C<$attributes>.

=head2 generate_key($mechanism, $attributes, ...)

Generate a new key for C<$mechanism> with C<$attributes>. Some relevant attributes are:

=over 4

=item * label

A label to your key, this helps with alter retreiving the key.

=item * token

If true this will store the key on the token, if false it will create a session key.

=item * sensitive

Sensitive keys cannot be revealed in plaintext, this is almost always desired for non-public keys.

=item * extractable

This allows the key to be extractable, for example using wrapping. 

=item * wrap-with-trusted

If true a key can only be extracted with a trusted key

=item * trusted

This marks the key as trusted, this usually requires logging in as security officer.

=item * private

If true the key can't be used without logging in.

=item * value-len

This sets the length of a key, this can be useful when creating a C<'generic-secret-key-gen'> in particular.

=back

Most of these have implementation-specific defaults.

=head2 generate_keypair($mechanism, $public_attributes, $private_attributes, ...)

This generates a key pair. The attributes for the public and private keys work similar to `generate_key`.

=head2 generate_random($length)

This generate C<$length> bytes of randomness.

=head2 get_attribute($object, $attribute_name)

This returns the value of the named attribute.

=head2 get_attributes($object, $attribute_list)

This returns a hash with the attributes that are asked for.

=head2 info()

This returns information about the current session.

=head2 init_pin($pin)

This initializes the PIN for this slot.

=head2 login($type, $pin)

Log in the current session. C<$type> should be either C<'user'> (most likely), C<'so'> (security officer, for elevated privileges), or C<'context-dependent'>. C<$pin> is your password.

=head2 logout()

Log the current session out.

=head2 object_size($object)

This returns the size of C<$object>.

=head2 open_decrypt($mechanism, $key, ...)

Start a decryption with C<$mechanism> and C<$key>. This returns a L<Crypt::HSM::Decrypt|Crypt::HSM::Decrypt> object.

=head2 open_digest($mechanism, ...)

Start a digest with C<$mechanism>. This returns a L<Crypt::HSM::Digest|Crypt::HSM::Digest> object.

=head2 open_encrypt($mechanism, $key, ...)

Start an encryption with C<$mechanism> and C<$key>. This returns a L<Crypt::HSM::Encrypt|Crypt::HSM::Encrypt> object.

=head2 open_sign($mechanism, $key, ...)

Start an signing with C<$mechanism> and C<$key>. This returns a L<Crypt::HSM::Sign|Crypt::HSM::Sign> object.

=head2 open_verify($mechanism, $key, ...)

Start an verification with C<$mechanism> and C<$key>. This returns a L<Crypt::HSM::Verify|Crypt::HSM::Verify> object.

=head2 provider()

Returns the provider object for this session.

=head2 seed_random($seed)

Mix additional seed material into the token’s random number generator.

=head2 set_attributes($object, $attributes)

This sets the C<$attributes> on C<$object>.

=head2 set_pin($old_pin, $new_pin)

This changes the PIN from C<$old_pin> to C<$new_pin>.

=head2 sign($mechanism, $key, $input, ...)

This creates a signature over C<$input> using C<$mechanism> and C<$key>.

=head2 slot()

Returns the slot identifier used for this session.

=head2 unwrap_key($mechanism, $unwrap_key, $wrapped_key, $attributes, ...)

This unwraps the key wrapped in the bytearray C<$wrapped_key> using C<mechanism> and key C<$unwrap_key>, setting C<$attributes> on the new key.

=head2 verify($mechanism, $key, $data, $signature, ...)

Verify that C<$signature> matches C<$data>, using C<$mechanism> and C<$key>.

=head2 wrap_key($mechanism, $wrap_key, $key, ...)

This wraps key C<$key> using C<$mechanism> and key C<$wrap_key>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
