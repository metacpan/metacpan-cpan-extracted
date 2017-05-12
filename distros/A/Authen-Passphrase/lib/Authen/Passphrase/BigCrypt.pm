=head1 NAME

Authen::Passphrase::BigCrypt - passphrases using bigcrypt algorithm

=head1 SYNOPSIS

	use Authen::Passphrase::BigCrypt;

	$ppr = Authen::Passphrase::BigCrypt->new(
		salt_base64 => "qi",
		hash_base64 => "yh4XPJGsOZ2MEAyLkfWqeQ");

	$ppr = Authen::Passphrase::BigCrypt->new(
		salt_random => 12,
		passphrase => "passphrase");

	$salt = $ppr->salt;
	$salt_base64 = $ppr->salt_base64_2;
	$hash = $ppr->hash;
	$hash_base64 = $ppr->hash_base64;

	$pprs = $ppr->sections;

	if($ppr->match($passphrase)) { ...

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using the
"bigcrypt" hash function found in HP-UX, Digital Unix, OSF/1, and some
other flavours of Unix.  Do not confuse this with the "crypt16" found
on Ultrix and Tru64 (for which see L<Authen::Passphrase::Crypt16>).
This is a subclass of L<Authen::Passphrase>, and this document assumes
that the reader is familiar with the documentation for that class.

This is a derivation of the original DES-based crypt function found on all
Unices (see L<Authen::Passphrase::DESCrypt>).  The first eight bytes of
the passphrase are used as a DES key to encrypt the all-bits-zero block
through 25 rounds of (12-bit) salted DES, just like the original crypt.
Then, if the passphrase is longer than eight bytes, the next eight bytes
are used as a DES key to encrypt the all-bits-zero block through 25
rounds of salted DES, using as salt the first 12 bits of the hash of the
first section.  Then, if the passphrase is longer than sixteen bytes,
the next eight bytes are used, with salt consisting of the first 12
bits of the hash of the second section.  This repeats until the entire
passphrase has been used.  The hashes of all the sections are concatenated
to form the final hash.

A password hash of this scheme is conventionally represented in ASCII
using the base 64 encoding of the underlying DES-based crypt function.
The first two characters give the salt for the first section, the next
eleven give the hash of the first section, the next eleven give the hash
of the second section, and so on.  A hash thus encoded is used as a crypt
string, on those systems where the bigcrypt algorithm is part of crypt(),
but the syntax clashes with that of crypt16.  This module does not treat
it as a crypt string syntax.

Because the sections of the passphrase are hashed separately, it is
possible to manipulate (e.g., crack) a section hash in isolation.
See L<Authen::Passphrase::DESCrypt> for handling of a single section.

I<Warning:> This is a fatally flawed design, often providing I<less>
security than the plain DES scheme alone.  Do not use seriously.

=cut

package Authen::Passphrase::BigCrypt;

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

=item Authen::Passphrase::BigCrypt->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the bigcrypt hash
algorithm.  The following attributes may be given:

=over

=item B<salt>

The salt for the first section, as an integer in the range [0, 4096).

=item B<salt_base64>

The salt for the first section, as a string of two base 64 digits.

=item B<salt_random>

Causes salt for the first section to be generated randomly.  The value
given for this attribute must be 12, indicating generation of 12 bits
of salt.  The source of randomness may be controlled by the facility
described in L<Data::Entropy>.

=item B<hash>

The hash, as a string of bytes.

=item B<hash_base64>

The hash, as a string of base 64 digits.

=item B<passphrase>

A passphrase that will be accepted.

=back

The salt for the first section must be given, and either the hash or
the passphrase.

=cut

sub new {
	my $class = shift;
	my $salt;
	my @hashes;
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
				if @hashes || defined($passphrase);
			$value =~ m#\A(?:[\x00-\xff]{8})+\z#
				or croak "not a valid bigcrypt hash";
			push @hashes, $1 while $value =~ /(.{8})/sg;
		} elsif($attr eq "hash_base64") {
			croak "hash specified redundantly"
				if @hashes || defined($passphrase);
			$value =~ m#\A(?:[./0-9A-Za-z]{10}[.26AEIMQUYcgkosw])
					+\z#x
				or croak "\"$value\" is not a valid ".
						"encoded hash";
			while($value =~ /(.{11})/sg) {
				my $b64 = $1;
				push @hashes, base64_to_block($b64);
			}
		} elsif($attr eq "passphrase") {
			croak "passphrase specified redundantly"
				if @hashes || defined($passphrase);
			$passphrase = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	croak "salt not specified" unless defined $salt;
	my @sections;
	if(defined $passphrase) {
		my $nsegs = $passphrase eq "" ? 1 :
				((length($passphrase) + 7) >> 3);
		for(my $i = 0; $i != $nsegs; $i++) {
			push @sections,
				Authen::Passphrase::DESCrypt
				->new(salt => $salt,
				      passphrase =>
					      substr($passphrase, $i << 3, 8));
			$salt = base64_to_int12(
				substr($sections[-1]->hash_base64, 0, 2));
		}
	} elsif(@hashes) {
		foreach my $hash (@hashes) {
			push @sections, Authen::Passphrase::DESCrypt
					->new(salt => $salt, hash => $hash);
			$salt = base64_to_int12(
				substr($sections[-1]->hash_base64, 0, 2));
		}
	} else {
		croak "hash not specified";
	}
	return bless(\@sections, $class);
}

=back

=head1 METHODS

=over

=item $ppr->salt

Returns the salt for the first section, as a Perl integer.

=cut

sub salt { $_[0]->[0]->salt }

=item $ppr->salt_base64_2

Returns the salt for the first section, as a string of two base 64 digits.

=cut

sub salt_base64_2 { $_[0]->[0]->salt_base64_2 }

=item $ppr->hash

Returns the hash value, as a string of bytes.

=cut

sub hash { join("", map { $_->hash } @{$_[0]}) }

=item $ppr->hash_base64

Returns the hash value, as a string of base 64 digits.  This is the
concatenation of the base 64 encodings of the section hashes, rather
than a base64 encoding of the combined hash.

=cut

sub hash_base64 { join("", map { $_->hash_base64 } @{$_[0]}) }

=item $ppr->sections

Returns a reference to an array of L<Authen::Passphrase::DESCrypt>
passphrase recognisers for the sections of the passphrase.

=cut

sub sections { [ @{$_[0]} ] }

=item $ppr->match(PASSPHRASE)

This method is part of the standard L<Authen::Passphrase> interface.

=cut

sub match {
	my Authen::Passphrase::BigCrypt $self = shift;
	my($passphrase) = @_;
	my $nsegs = $passphrase eq "" ? 1 : ((length($passphrase) + 7) >> 3);
	return 0 unless $nsegs == @$self;
	for(my $i = $nsegs; $i--; ) {
		return 0 unless $self->[$i]
				->match(substr($passphrase, $i << 3, 8));
	}
	return 1;
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
