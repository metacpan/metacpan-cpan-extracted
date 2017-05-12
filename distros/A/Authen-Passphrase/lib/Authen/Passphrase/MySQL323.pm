=head1 NAME

Authen::Passphrase::MySQL323 - passphrases using the MySQL v3.23 algorithm

=head1 SYNOPSIS

	use Authen::Passphrase::MySQL323;

	$ppr = Authen::Passphrase::MySQL323->new(
		hash_hex => "2af8a0a82c8f9086");

	$ppr = Authen::Passphrase::MySQL323->new(
		passphrase => "passphrase");

	$hash = $ppr->hash;
	$hash_hex = $ppr->hash_hex;

	if($ppr->match($passphrase)) { ...

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using the
algorithm used by MySQL from version 3.23.  This is a subclass of
L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.

The MySQL v3.23 hash scheme is composed entirely of linear operations.
It accepts an arbitrarily long passphrase, and ignores all space
and tab characters.  No salt is used.  62 bits of hash are generated.
Each character influences only a minority of the result bits, so similar
passphrases of the same length have noticeably similar hashes.

In MySQL the hash is represented as a string of sixteen lowercase
hexadecimal digits.

I<Warning:> This is not a serious cryptographic algorithm.  Do not use
for any security purpose.

=cut

package Authen::Passphrase::MySQL323;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);
use Crypt::MySQL 0.03 qw(password);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

=head1 CONSTRUCTOR

=over

=item Authen::Passphrase::MySQL323->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the MySQL v3.23
algorithm.  The following attributes may be given:

=over

=item B<hash>

The hash, as a string of eight bytes.  The first and fifth bytes must
have their top bit clear.

=item B<hash_hex>

The hash, as a string of 16 hexadecimal digits.

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
			$value =~ m#\A(?:[\x00-\x7f][\x00-\xff]{3}){2}\z#
				or croak "not a valid MySQL v3.23 hash";
			$self->{hash} = "$value";
		} elsif($attr eq "hash_hex") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A(?:[0-7][0-9A-Fa-f]{7}){2}\z#
				or croak "\"$value\" is not a valid ".
						"hex MySQL v3.23 hash";
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

Returns the hash value, as a string of eight bytes.

=cut

sub hash {
	my($self) = @_;
	return $self->{hash};
}

=item $ppr->hash_hex

Returns the hash value, as a string of 16 hexadecimal digits.

=cut

sub hash_hex {
	my($self) = @_;
	return unpack("H*", $self->{hash});
}

=item $ppr->match(PASSPHRASE)

This method is part of the standard L<Authen::Passphrase> interface.

=cut

sub _hash_of {
	my($self, $passphrase) = @_;
	return pack("H*", password($passphrase));
}

sub match {
	my($self, $passphrase) = @_;
	return $self->_hash_of($passphrase) eq $self->{hash};
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Crypt::MySQL>

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
