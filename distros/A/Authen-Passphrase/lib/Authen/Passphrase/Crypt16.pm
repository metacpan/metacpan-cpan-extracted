=head1 NAME

Authen::Passphrase::Crypt16 - passphrases using Ultrix crypt16 algorithm

=head1 SYNOPSIS

	use Authen::Passphrase::Crypt16;

	$ppr = Authen::Passphrase::Crypt16->new(
		salt_base64 => "qi",
		hash_base64 => "8H8R7OM4xMUNMPuRAZxlY.");

	$ppr = Authen::Passphrase::Crypt16->new(
		salt_random => 12,
		passphrase => "passphrase");

	$salt = $ppr->salt;
	$salt_base64 = $ppr->salt_base64_2;
	$hash = $ppr->hash;
	$hash_base64 = $ppr->hash_base64;

	$ppr0 = $ppr->first_half;
	$ppr1 = $ppr->second_half;

	if($ppr->match($passphrase)) { ...

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using the
"crypt16" hash function found in Ultrix and Tru64.  Do not confuse
this with the "bigcrypt" found on HP-UX, Digital Unix, and OSF/1 (for
which see L<Authen::Passphrase::BigCrypt>).  This is a subclass of
L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.

This is a derivation of the original DES-based crypt function found on all
Unices (see L<Authen::Passphrase::DESCrypt>).  The first eight bytes of
the passphrase are used as a DES key to encrypt the all-bits-zero block
through 20 rounds of (12-bit) salted DES.  (The standard crypt function
does this, but with 25 encryption rounds instead of 20.)  Then the
next eight bytes, or the null string if the passphrase is eight bytes
or shorter, are used as a DES key to encrypt the all-bits-zero block
through 5 rounds of salted DES with the same salt.  The two eight-byte
ciphertexts are concatenated to form the sixteen-byte hash.

A password hash of this scheme is conventionally represented in ASCII as
a 24-character string using a base 64 encoding.  The first two characters
give the salt, the next eleven give the hash of the first half, and the
last eleven give the hash of the second half.  A hash thus encoded is
used as a crypt string, on those systems where the crypt16 algorithm
is part of crypt(), but the syntax clashes with that of bigcrypt.
This module does not treat it as a crypt string syntax.

Because the two halves of the passphrase are hashed separately, it
is possible to manipulate (e.g., crack) a half hash in isolation.
See L<Authen::Passphrase::DESCrypt> for handling of a single half.

I<Warning:> This is a fatally flawed design, often providing I<less>
security than the plain DES scheme alone.  Do not use seriously.

=cut

package Authen::Passphrase::Crypt16;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Authen::Passphrase::DESCrypt;
use Carp qw(croak);
use Crypt::UnixCrypt_XS 0.08 qw(base64_to_block base64_to_int12);
use Data::Entropy::Algorithms 0.000 qw(rand_int);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

=head1 CONSTRUCTOR

=over

=item Authen::Passphrase::Crypt16->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the crypt16 hash
algorithm.  The following attributes may be given:

=over

=item B<salt>

The salt, as an integer in the range [0, 4096).

=item B<salt_base64>

The salt, as a string of two base 64 digits.

=item B<salt_random>

Causes salt to be generated randomly.  The value given for this
attribute must be 12, indicating generation of 12 bits of salt.
The source of randomness may be controlled by the facility described
in L<Data::Entropy>.

=item B<hash>

The hash, as a string of 16 bytes.

=item B<hash_base64>

The hash, as a string of 22 base 64 digits.

=item B<passphrase>

A passphrase that will be accepted.

=back

The salt must be given, and either the hash or the passphrase.

=cut

sub new {
	my $class = shift;
	my $self = bless({}, $class);
	my $salt;
	my $hash;
	my $passphrase;
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "salt") {
			croak "salt specified redundantly"
				if defined $salt;
			croak "\"$value\" is not a valid salt"
				unless $value == int($value) &&
					$value >= 0 && $value < 4096;
			$salt = $value;
		} elsif($attr eq "salt_base64") {
			croak "salt specified redundantly"
				if defined $salt;
			$value =~ m#\A[./0-9A-Za-z]{2}\z#
				or croak "\"$value\" is not a valid salt";
			$salt = base64_to_int12($value);
		} elsif($attr eq "salt_random") {
			croak "salt specified redundantly"
				if defined $salt;
			croak "\"$value\" is not a valid salt size"
				unless $value == 12;
			$salt = rand_int(1 << $value);
		} elsif($attr eq "hash") {
			croak "hash specified redundantly"
				if defined($hash) || defined($passphrase);
			$value =~ m#\A[\x00-\xff]{16}\z#
				or croak "not a valid crypt16 hash";
			$hash = $value;
		} elsif($attr eq "hash_base64") {
			croak "hash specified redundantly"
				if defined($hash) || defined($passphrase);
			$value =~ m#\A(?:[./0-9A-Za-z]{10}[.26AEIMQUYcgkosw])
					{2}\z#x
				or croak "\"$value\" is not a valid ".
						"encoded hash";
			$hash = base64_to_block(substr($value, 0, 11)).
				base64_to_block(substr($value, 11));
		} elsif($attr eq "passphrase") {
			croak "passphrase specified redundantly"
				if defined($hash) || defined($passphrase);
			$passphrase = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	croak "salt not specified" unless defined $salt;
	if(defined $passphrase) {
		$self->{first_half} =
			Authen::Passphrase::DESCrypt
				->new(nrounds => 20, salt => $salt,
				      passphrase => substr($passphrase, 0, 8));
		$self->{second_half} =
			Authen::Passphrase::DESCrypt
				->new(nrounds => 5, salt => $salt,
				      passphrase =>
					length($passphrase) > 8 ?
						substr($passphrase, 8) : "");
	} elsif(defined $hash) {
		$self->{first_half} = Authen::Passphrase::DESCrypt
					->new(nrounds => 20, salt => $salt,
					      hash => substr($hash, 0, 8));
		$self->{second_half} = Authen::Passphrase::DESCrypt
					->new(nrounds => 5, salt => $salt,
					      hash => substr($hash, 8, 8));
	} else {
		croak "hash not specified";
	}
	return $self;
}

=back

=head1 METHODS

=over

=item $ppr->salt

Returns the salt, as a Perl integer.

=cut

sub salt {
	my($self) = @_;
	return $self->{first_half}->salt;
}

=item $ppr->salt_base64_2

Returns the salt, as a string of two base 64 digits.

=cut

sub salt_base64_2 {
	my($self) = @_;
	return $self->{first_half}->salt_base64_2;
}

=item $ppr->hash

Returns the hash value, as a string of 16 bytes.

=cut

sub hash {
	my($self) = @_;
	return $self->{first_half}->hash.$self->{second_half}->hash;
}

=item $ppr->hash_base64

Returns the hash value, as a string of 22 base 64 digits.  This is the
concatenation of the base 64 encodings of the two hashes, rather than
a base64 encoding of the combined hash.

=cut

sub hash_base64 {
	my($self) = @_;
	return $self->{first_half}->hash_base64.
		$self->{second_half}->hash_base64;
}

=item $ppr->first_half

Returns the hash of the first half of the passphrase, as an
L<Authen::Passphrase::DESCrypt> passphrase recogniser.

=cut

sub first_half {
	my($self) = @_;
	return $self->{first_half};
}

=item $ppr->second_half

Returns the hash of the second half of the passphrase, as an
L<Authen::Passphrase::DESCrypt> passphrase recogniser.

=cut

sub second_half {
	my($self) = @_;
	return $self->{second_half};
}

=item $ppr->match(PASSPHRASE)

This method is part of the standard L<Authen::Passphrase> interface.

=cut

sub match {
	my($self, $passphrase) = @_;
	return $self->{first_half}->match(substr($passphrase, 0, 8)) &&
		$self->{second_half}->match(
			length($passphrase) > 8 ? substr($passphrase, 8) : "");
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Authen::Passphrase::DESCrypt>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2010, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
