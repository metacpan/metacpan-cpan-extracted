=head1 NAME

Authen::Passphrase::MySQL41 - passphrases using the MySQL v4.1 algorithm

=head1 SYNOPSIS

	use Authen::Passphrase::MySQL41;

	$ppr = Authen::Passphrase::MySQL41->new(
		hash_hex => "9CD12C48C4C5DD62914B".
			    "3FABB93131746E9E9115");

	$ppr = Authen::Passphrase::MySQL41->new(
		passphrase => "passphrase");

	$hash = $ppr->hash;
	$hash_hex = $ppr->hash_hex;

	if($ppr->match($passphrase)) { ...

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using the
algorithm used by MySQL from version 4.1.  This is a subclass of
L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.

The MySQL v4.1 hash scheme is based on the SHA-1 digest algorithm.
The passphrase is first hashed using SHA-1, then the output of that
stage is hashed using SHA-1 again.  The final hash is the output of the
second SHA-1.  No salt is used.

In MySQL the hash is represented as a "B<*>" followed by 40 uppercase
hexadecimal digits.

The lack of salt is a weakness in this scheme.  Salted SHA-1 is a better
scheme; see L<Authen::Passphrase::SaltedDigest>.

=cut

package Authen::Passphrase::MySQL41;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);
use Digest::SHA qw(sha1);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

=head1 CONSTRUCTOR

=over

=item Authen::Passphrase::MySQL41->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the MySQL v4.1
algorithm.  The following attributes may be given:

=over

=item B<hash>

The hash, as a string of 20 bytes.

=item B<hash_hex>

The hash, as a string of 40 hexadecimal digits.

=item B<passphrase>

A passphrase that will be accepted.

=back

Either the hash or the passphrase must be given.

=cut

sub new {
	my $class = shift;
	my $self = bless({}, $class);
	my $passphrase;
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "hash") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[\x00-\xff]{20}\z#
				or croak "not a valid MySQL v4.1 hash";
			$self->{hash} = "$value";
		} elsif($attr eq "hash_hex") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[0-9A-Fa-f]{40}\z#
				or croak "\"$value\" is not a valid ".
						"hex MySQL v4.1 hash";
			$self->{hash} = pack("H*", $value);
		} elsif($attr eq "passphrase") {
			croak "passphrase specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$passphrase = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	$self->{hash} = $self->_hash_of($passphrase) if defined $passphrase;
	croak "hash not specified" unless exists $self->{hash};
	return $self;
}

=back

=head1 METHODS

=over

=item $ppr->hash

Returns the hash value, as a string of 20 bytes.

=cut

sub hash {
	my($self) = @_;
	return $self->{hash};
}

=item $ppr->hash_hex

Returns the hash value, as a string of 40 uppercase hexadecimal digits.

=cut

sub hash_hex {
	my($self) = @_;
	return uc(unpack("H*", $self->{hash}));
}

=item $ppr->match(PASSPHRASE)

This method is part of the standard L<Authen::Passphrase> interface.

=cut

sub _hash_of {
	my($self, $passphrase) = @_;
	return sha1(sha1($passphrase));
}

sub match {
	my($self, $passphrase) = @_;
	return $self->_hash_of($passphrase) eq $self->{hash};
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Digest::SHA>

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
