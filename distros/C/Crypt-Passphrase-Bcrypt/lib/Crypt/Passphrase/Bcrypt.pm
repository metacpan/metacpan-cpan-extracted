package Crypt::Passphrase::Bcrypt;
$Crypt::Passphrase::Bcrypt::VERSION = '0.003';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';

use Carp 'croak';
use Crypt::Bcrypt qw/bcrypt bcrypt_check/;
use Digest::SHA 'hmac_sha256';
use MIME::Base64 'encode_base64';

sub new {
	my ($class, %args) = @_;
	my $subtype = $args{subtype} || '2b';
	croak "Unknown subtype $subtype" unless $subtype =~ / \A 2 [abxy] \z /x;
	croak 'Invalid hash' if exists $args{hash} && $args{hash} ne 'sha256';
	return bless {
		cost    => $args{cost} || 14,
		subtype => $subtype,
		hash    => $args{hash} || '',
	}, $class;
}

my $subtype = qr/2[abxy]/;
my $cost = qr/\d{2}/;
my $salt_qr = qr{ [./A-Za-z0-9]{22} }x;

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes(16);
	if ($self->{hash}) {
		(my $encoded_salt = encode_base64($salt, "")) =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}d;
		my $hashed_password = encode_base64(hmac_sha256($password, $encoded_salt), "");
		my $hash = bcrypt($hashed_password, $self->{subtype}, $self->{cost}, $salt);
		$hash =~ s{ ^ \$ ($subtype) \$ ($cost) \$ ($salt_qr) }{\$bcrypt-sha256\$v=2,t=$1,r=$2\$$3\$}x;
		return $hash;
	}
	else {
		return bcrypt($password, $self->{subtype}, $self->{cost}, $salt);
	}
}

sub needs_rehash {
	my ($self, $hash) = @_;
	if ($hash =~ / \A \$ ($subtype) \$ ($cost) \$ /x) {
		return 0 if $1 eq $self->{subtype} && $2 >= $self->{cost} && $self->{hash} eq '';
	}
	elsif ($hash =~ / ^ \$ bcrypt-sha256 \$ v=2,t=($subtype),r=($cost) \$ /x) {
		return 0 if $1 eq $self->{subtype} && $2 >= $self->{cost} && $self->{hash} eq 'sha256';
	}
	return 1;
}

sub crypt_subtypes {
	return qw/2a 2b 2x 2y bcrypt-sha256/;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	if ($hash =~ s/ ^ \$ bcrypt-sha256 \$ v=2,t=($subtype),r=($cost) \$ ($salt_qr) \$ /\$$1\$$2\$$3/x) {
		return bcrypt_check(encode_base64(hmac_sha256($password, $3), ""), $hash);
	}
	else {
		return bcrypt_check($password, $hash);
	}
}

1;

#ABSTRACT: A bcrypt encoder for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Bcrypt - A bcrypt encoder for Crypt::Passphrase

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This class implements a bcrypt encoder for Crypt::Passphrase. L<Crypt::Passphrase::Argon2|Crypt::Passphrase::Argon2> is recommended over this module as an encoder, as that provides memory-hardness and more easily allows for long passwords.

=head1 METHODS

=head2 new(%args)

=over 4

=item * cost

This is the cost factor that is used to hash passwords.

=item * subtype

=over 4

=item * C<2b>

This is the subtype the rest of the world has been using since 2014

=item * C<2y>

This type is considered equivalent to C<2b>.

=item * C<2a>

This is an old and subtly buggy version of bcrypt. This is mainly useful for Crypt::Eksblowfish compatibility.

=item * C<2x>

This is a very broken version that is only useful for compatibility with ancient php versions.

=back

This is C<2b> by default, and you're unlikely to want to change this.

=item * hash

Pre-hash the password using the specified hash. Currently only sha256 is supported. This is mainly useful to get around the 72 character limit. This uses a salt-keyed hash to prevent password shucking.

=back

=head2 hash_password($password)

This hashes the passwords with bcrypt according to the specified settings and a random salt (and will thus return a different result each time).

=head2 needs_rehash($hash)

This returns true if the hash uses a different cipher or subtype, if any of the cost is lower that desired by the encoder or if the prehashing doesn't match.

=head2 crypt_types()

This returns the above described subtypes, as well as C<bcrypt-sha256> for prehashed bcrypt.

=head2 verify_password($password, $hash)

This will check if a password matches a bcrypt hash.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
