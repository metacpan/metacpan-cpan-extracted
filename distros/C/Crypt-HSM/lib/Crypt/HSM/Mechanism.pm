package Crypt::HSM::Mechanism;
$Crypt::HSM::Mechanism::VERSION = '0.030';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

# Backwards compatibility
for my $method (qw/min_key_size max_key_size flags has_flags/) {
	no strict 'refs';
	*{$method} = sub {
		my ($self, @args) = @_;
		return $self->info->$method(@args);
	}
}

1;

#ABSTRACT: A PKCS11 mechanism

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Mechanism - A PKCS11 mechanism

=head1 VERSION

version 0.030

=head1 SYNOPSIS

 my @signers = grep { $_->info->has_flags('sign', 'verify') } $slot->mechanisms;

=head1 DESCRIPTION

This represents a mechanism in a PKCS implementation.

=head1 METHODS

=head2 name()

This looks up the name of the mechanism, or C<undef> if the name is unknown.

=head2 info()

This returns an L<information|Crypt::HSM::Mechanism::Info> object about the mechanism.

=head1 ADDITIONAL ARGUMENTS

The following mechanism types have the following additional arguments for their respective operations:

=over 4

=item * C<'aes-cbc'>

=item * C<'aes-cbc-pad'>

=item * C<'aes-ofb'>

=item * C<'aes-cfb8'>

=item * C<'aes-cfb128'>

=item * C<'des-cbc'>

=item * C<'des-cbc-pad'>

=item * C<'des-ofb'>

=item * C<'des-cfb8'>

=item * C<'des-cfb128'>

=item * C<'des3-cbc'>

These take an IV as mandatory additional argument.

=item * C<'aes-ctr'>

This take an IV as mandatory additional argument. It also takes a counter length (in bits) as an optional argument, defaulting to 128.

=item * C<'aes-gcm'>

This take an IV as mandatory additional argument. It also takes an additional authenticated data section argument (defaulting to empty), and a tag length (in bits), defaulting to 128.

=item * C<'chacha20-poly1305'>

=item * C<'salsa20-poly1305'>

These take a nonce as mandatory additional argument. It also takes an additional authenticated data section argument (defaulting to empty).

=item * C<'rsa-pkcs-pss'>

This takes one mandatory argument: the hash function. It takes two optional arguments: the message generator function (defaulting to the hash function), and optionally a salt length in bits (defaulting to 0).

=item * C<'sha224-rsa-pkcs-pss'>

=item * C<'sha256-rsa-pkcs-pss'>

=item * C<'sha384-rsa-pkcs-pss'>

=item * C<'sha512-rsa-pkcs-pss'>

These take an optional salt length in bits (defaulting to 0).

=item * C<'ecdh1-derive'>

=item * C<'ecdh1-cofactor-derive'>

These takes one mandatory argument: the public key to derive the new key with. It also takes two option arguments: the first is the key derivation function (defaulting to C<"null">), the second is the shared data for key derivation (defaulting to none).

=item * C<'concatenate-data-and-base'>

=item * C<'concatenate-base-and-data'>

=item * C<'aes-ecb-encrypt-data'>

=item * C<'des-ecb-encrypt-data'>

These takes the public data as mandatory additional argument.

=item * C<'concatenate-base-and-key'>

This takes a key identifier as mandatory additional argument.

=item * C<'aes-cbc-encrypt-data'>

=item * C<'des-cbc-encrypt-data'>

These takes the public data and an IV as mandatory additional arguments.

=item * C<'rsa-pkcs-oaep'>

This takes one mandatory argument: the hash function. It takes two optional arguments: the message generator function (defaulting to the hash function), and a label/encoding parameter.

=item * C<'eddsa'>

This takes two optional arguments. If no arguments are given it's run in pure mode, if they are given it's run in contextual mode. The first argument is the context data. The second is the pre-hash flag: if true it will enable pre-hashing mode.

=item * C<'aes-key-wrap'>

=item * C<'aes-key-wrap-pad'>

=item * C<'aes-key-wrap-pkcs7'>

=item * C<'aes-key-wrap-kwp'>

These take an optional byte string that is the array of bytes to be used as the initial value.

=item * C<'rsa-aes-key-wrap'>

This takes two mandatory and two optional arguments. The first argument is the length of the AES key in bits (C<128>, C<192> or C<256>), the other arguments are the same as C<'rsa-pkcs-oaep'>.

=item * C<'ml-dsa'>

=item * C<'hash-ml-dsa-sha224'>

=item * C<'hash-ml-dsa-sha256'>

=item * C<'hash-ml-dsa-sha384'>

=item * C<'hash-ml-dsa-sha512'>

=item * C<'hash-ml-dsa-sha3-224'>

=item * C<'hash-ml-dsa-sha3-256'>

=item * C<'hash-ml-dsa-sha3-384'>

=item * C<'hash-ml-dsa-sha3-512'>

=item * C<'hash-ml-dsa-shake128'>

=item * C<'hash-ml-dsa-shake256'>

=item * C<'slh-dsa'>

=item * C<'hash-slh-dsa-sha224'>

=item * C<'hash-slh-dsa-sha256'>

=item * C<'hash-slh-dsa-sha384'>

=item * C<'hash-slh-dsa-sha512'>

=item * C<'hash-slh-dsa-sha3-224'>

=item * C<'hash-slh-dsa-sha3-256'>

=item * C<'hash-slh-dsa-sha3-384'>

=item * C<'hash-slh-dsa-sha3-512'>

=item * C<'hash-slh-dsa-shake128'>

=item * C<'hash-slh-dsa-shake256'>

These takes two optional arguments: a context string, and a hedge type (C<'hedge-preferred'>, C<'hedge-required'> or C<'deterministic-required'>)

=item * C<'hash-ml-dsa'>

=item * C<'hash-slh-dsa'>

These take one mandatory argument, a hash mechanism, and two optional arguments: a context string, and a hedge type (C<'hedge-preferred'>, C<'hedge-required'> or C<'deterministic-required'>).

=back

=for Pod::Coverage min_key_size
max_key_size
has_flags
flags

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
