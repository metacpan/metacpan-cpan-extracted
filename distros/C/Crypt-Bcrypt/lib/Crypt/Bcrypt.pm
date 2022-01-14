package Crypt::Bcrypt;
$Crypt::Bcrypt::VERSION = '0.005';
use strict;
use warnings;

use XSLoader;
XSLoader::load('Crypt::Bcrypt');

use Exporter 5.57 'import';
our @EXPORT_OK = qw(bcrypt bcrypt_check);

use MIME::Base64 2.21 qw(encode_base64);

sub bcrypt {
	my ($password, $subtype, $cost, $salt) = @_;
	die "Unknown subtype $subtype" if $subtype !~ /^2[abxy]$/;
	die "Invalid cost factor $cost" if $cost < 5 || $cost > 31;
	die "Salt must be 16 bytes" if length $salt != 16;
	my $encoded_salt = encode_base64($salt, "");
	$encoded_salt =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}d;
	return _bcrypt_hashpw($password, sprintf '$%s$%02d$%s', $subtype, $cost, $encoded_salt);
}

1;

# ABSTRACT: A modern bcrypt implementation

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Bcrypt - A modern bcrypt implementation

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Crypt::Bcrypt qw/bcrypt bcrypt_check/;

 my $hash = bcrypt($password, '2b', 12, $salt);

 if (bcrypt_check($password, $hash)) {
    ...
 }

=head1 DESCRIPTION

This module provides a modern and user-friendly implementation of the bcrypt password hash.

Note that in bcrypt passwords may only contain 72 characters. It may seem tempting to prehash the password before bcrypting it but that may make it vulnerable to password shucking, a salted solution (for example using a MAC) should be used instead if one wants to support large passwords.

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

C<$cost> must be between 5 and 31 (inclusive). C<$salt> must be exactly 16 bytes.

=head2 bcrypt_check($password, $hash)

This checks if the C<$password> satisfies the C<$hash>, and does so in a timing-safe manner.

=head1 SEE OTHER

=over 4

=item * L<Crypt::Passphrase|Crypt::Passphrase>

This is usually a better approach to managing your passwords, it can use this module via L<Crypt::Passphrase::Bcrypt|Crypt::Passphrase::Bcrypt>. It adds support for automatic pre-hashing, and facilitates upgrading the algorithm parameters or even the algorithm itself.

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
