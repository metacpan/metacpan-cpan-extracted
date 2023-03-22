package Crypt::Bcrypt;
$Crypt::Bcrypt::VERSION = '0.011';
use strict;
use warnings;

use XSLoader;
XSLoader::load('Crypt::Bcrypt');

use Exporter 5.57 'import';
our @EXPORT_OK = qw(bcrypt bcrypt_check bcrypt_prehashed bcrypt_check_prehashed bcrypt_hashed bcrypt_check_hashed bcrypt_needs_rehash bcrypt_supported_prehashes);

use Carp 'croak';
use Digest::SHA;
use MIME::Base64 2.21 qw(encode_base64);

sub bcrypt {
	my ($password, $subtype, $cost, $salt) = @_;
	croak "Unknown subtype $subtype" if $subtype !~ /^2[abxy]$/;
	croak "Invalid cost factor $cost" if $cost < 4 || $cost > 31;
	croak "Salt must be 16 bytes" if length $salt != 16;
	my $encoded_salt = encode_base64($salt, "");
	$encoded_salt =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}d;
	return _bcrypt_hashpw($password, sprintf '$%s$%02d$%s', $subtype, $cost, $encoded_salt);
}

my $subtype_qr = qr/2[abxy]/;
my $cost_qr = qr/\d{2}/;
my $salt_qr = qr{ [./A-Za-z0-9]{22} }x;
my $algo_qr = qr{ sha[0-9]+ }x;

my %hash_for = (
	sha256 => \&Digest::SHA::hmac_sha256,
	sha384 => \&Digest::SHA::hmac_sha384,
	sha512 => \&Digest::SHA::hmac_sha512,
);

sub bcrypt_prehashed {
	my ($password, $subtype, $cost, $salt, $algorithm) = @_;
	if (length $algorithm) {
		(my $encoded_salt = encode_base64($salt, "")) =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}d;
		my $hasher = $hash_for{$algorithm} || croak "No such hash $algorithm";
		my $hashed_password = encode_base64($hasher->($password, $encoded_salt), "");
		my $hash = bcrypt($hashed_password, $subtype, $cost, $salt);
		$hash =~ s{ ^ \$ ($subtype_qr) \$ ($cost_qr) \$ ($salt_qr) }{\$bcrypt-$algorithm\$v=2,t=$1,r=$2\$$3\$}x or croak $hash;
		return $hash;
	}
	else {
		bcrypt($password, $subtype, $cost, $salt);
	}
}

sub bcrypt_check_prehashed {
	my ($password, $hash) = @_;
	if ($hash =~ s/ ^ \$ bcrypt-(\w+) \$ v=2,t=($subtype_qr),r=($cost_qr) \$ ($salt_qr) \$ /\$$2\$$3\$$4/x) {
		my $hasher = $hash_for{$1} or return 0;
		return bcrypt_check(encode_base64($hasher->($password, $4), ""), $hash);
	}
	else {
		return bcrypt_check($password, $hash);
	}
}

#legacy names
*bcrypt_hashed = \&bcrypt_prehashed;
*bcrypt_check_hashed = \&bcrypt_check_prehashed;

sub _get_parameters {
	my ($hash) = @_;
	if ($hash =~ / \A \$ ($subtype_qr) \$ ($cost_qr) \$ /x) {
		return ($1, $2, '');
	}
	elsif ($hash =~ / ^ \$ bcrypt-($algo_qr) \$ v=2,t=($subtype_qr),r=($cost_qr) \$ /x) {
		return ($2, $3, $1);
	}
	return ('', 0, '');
}

sub bcrypt_needs_rehash {
	my ($hash, $wanted_subtype, $wanted_cost, $wanted_hash) = @_;
	my ($my_subtype, $my_cost, $my_hash) = _get_parameters($hash);
	return $my_subtype ne $wanted_subtype || $my_cost != $wanted_cost || $my_hash ne ($wanted_hash || '');
}

sub bcrypt_supported_prehashes {
	return sort keys %hash_for;
}

1;

# ABSTRACT: A modern bcrypt implementation

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bcrypt - A modern bcrypt implementation

=head1 VERSION

version 0.011

=head1 SYNOPSIS

 use Crypt::Bcrypt qw/bcrypt bcrypt_check/;

 my $hash = bcrypt($password, '2b', 12, $salt);

 if (bcrypt_check($password, $hash)) {
    ...
 }

=head1 DESCRIPTION

This module provides a modern and user-friendly implementation of the bcrypt password hash.

Note that in bcrypt passwords may only contain 72 characters and may not contain any null-byte. To work around this limitation this module supports prehashing the input in a way that prevents password shucking.

The password is always expected to come as a (utf8-encoded) byte-string.

=head1 FUNCTIONS

=head2 bcrypt($password, $subtype, $cost, $salt)

This computes the bcrypt hash for C<$password> in C<$subtype>, with C<$cost> and C<$salt>.

Valid subtypes are:

=over 4

=item * C<2b>

This is the subtype the rest of the world has been using since 2014, you should use this unless you have a very specific reason to use something else.

=item * C<2a>

This is an old and subtly buggy version of bcrypt. This is mainly useful for Crypt::Eksblowfish compatibility.

=item * C<2y>

This type is considered equivalent to C<2b>, and is only commonly used on php.

=item * C<2x>

This is a very broken version that is only useful for compatibility with ancient php versions.

=back

C<$cost> must be between 4 and 31 (inclusive). C<$salt> must be exactly 16 bytes.

=head2 bcrypt_check($password, $hash)

This checks if the C<$password> satisfies the C<$hash>, and does so in a timing-safe manner.

=head2 bcrypt_prehashed($password, $subtype, $cost, $salt, $hash_algorithm)

This works like the C<bcrypt> functions, but pre-hashes the password using the specified hash. This is mainly useful to get around the 72 character limit. Currently C<'sha256'>, C<'sha384'> and C<'sha512'> are supported (but note that sha512 doesn't actually fit in bcrypt's input limit so is a bit moot), this is keyed with the salt to prevent password shucking. If C<$hash_algorithm> is an empty string it will perform a normal C<bcrypt> operation.

=head2 bcrypt_check_prehashed($password, $hash)

This verifies pre-hashed passwords as generated by C<bcrypt_prehashed>.

=head2 bcrypt_needs_rehash($hash, $wanted_subtype, $wanted_cost, $wanted_hash = '')

This returns true if the bcrypt hash uses a different subtype, cost or hash algorithm than desired.

=head2 bcrypt_supported_prehashes()

This returns a list of supported prehashes. Current that's C<('sha256', 'sha384', 'sha512')> but in the future it may include more.

=head1 SEE OTHER

=over 4

=item * L<Crypt::Passphrase|Crypt::Passphrase>

This is usually a better approach to managing your passwords, it can use this module via L<Crypt::Passphrase::Bcrypt|Crypt::Passphrase::Bcrypt>. It facilitates upgrading the algorithm parameters or even the algorithm itself.

=item * L<Crypt::Eksblowfish::Bcrypt|Crypt::Eksblowfish::Bcrypt>

This also offers bcrypt, but only supports the C<2a> subtype.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
