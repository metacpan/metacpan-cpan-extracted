=head1 NAME

Authen::Passphrase::EggdropBlowfish - passphrases using Eggdrop's
blowfish.mod

=head1 SYNOPSIS

	use Authen::Passphrase::EggdropBlowfish;

	$ppr = Authen::Passphrase::EggdropBlowfish->new(
		hash_base64 => "9tpsG/61YqX/");

	$ppr = Authen::Passphrase::EggdropBlowfish->new(
		passphrase => "passphrase");

	$hash = $ppr->hash;
	$hash_base64 = $ppr->hash_base64;

	if($ppr->match($passphrase)) { ...

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using the
Blowfish-based algorithm used in Eggdrop's blowfish.mod.  This is a
subclass of L<Authen::Passphrase>, and this document assumes that the
reader is familiar with the documentation for that class.

This hash scheme uses no salt, and does not accept a zero-length
passphrase.  It uses the passphrase as a Blowfish key to encrypt a
standard plaintext block.  The hash is the ciphertext block.  The standard
Blowfish key schedule only accepts keys from 8 to 56 bytes long; this
algorithm relaxes that requirement and accepts any non-zero length.
Up to 72 bytes of passphrase/key are significant; any more are ignored.

In Eggdrop the hash is represented as a "B<+>" followed by twelve base
64 digits.  The first six digits encode the second half of the hash,
and the last six encode the first half.  Within each half the bytes
are encoded in reverse order.  The base 64 digits are "B<.>", "B</>",
"B<0>" to "B<9>", "B<a>" to "B<z>", "B<A>" to "B<Z>" (in that order).

I<Warning:> The hash is small by modern standards, and the lack of salt
is a weakness in this scheme.  For a scheme that makes better use of
Blowfish see L<Authen::Passphrase::BlowfishCrypt>.

=cut

package Authen::Passphrase::EggdropBlowfish;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);
use Crypt::Eksblowfish::Uklblowfish 0.008;

our $VERSION = "0.008";

use parent "Authen::Passphrase";

my $b64_digits =
	"./0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

sub _en_base64($) {
	my($bytes) = @_;
	my $digits = "";
	foreach my $word (reverse unpack("N*", $bytes)) {
		for(my $i = 6; $i--; $word >>= 6) {
			$digits .= substr($b64_digits, $word & 0x3f, 1);
		}
	}
	return $digits;
}

sub _de_base64($) {
	my($digits) = @_;
	my @words;
	while($digits =~ /(......)/sg) {
		my $wdig = $1;
		my $word = 0;
		for(my $i = 6; $i--; ) {
			$word <<= 6;
			$word |= index($b64_digits, substr($wdig, $i, 1));
		}
		push @words, $word;
	}
	return pack("N*", reverse @words);
}

=head1 CONSTRUCTOR

=over

=item Authen::Passphrase::EggdropBlowfish->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the Eggdrop
blowfish.mod algorithm.  The following attributes may be given:

=over

=item B<hash>

The hash, as a string of eight bytes.

=item B<hash_base64>

The hash, as a string of twelve base 64 digits.

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
			$value =~ m#\A[\x00-\xff]{8}\z#
				or croak "not a valid hash";
			$self->{hash} = "$value";
		} elsif($attr eq "hash_base64") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A(?:[./0-9a-zA-Z]{5}[./01]){2}\z#
				or croak "\"$value\" is not a valid ".
						"base 64 hash";
			$self->{hash} = _de_base64($value);
		} elsif($attr eq "passphrase") {
			croak "passphrase specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value ne "" or croak "can't accept null passphrase";
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

=item $ppr->hash_base64

Returns the hash value, as a string of twelve base 64 digits.

=cut

sub hash_base64 {
	my($self) = @_;
	return _en_base64($self->{hash});
}

=item $ppr->match(PASSPHRASE)

This method is part of the standard L<Authen::Passphrase> interface.

=cut

sub _hash_of {
	my($self, $passphrase) = @_;
	$passphrase = substr($passphrase, 0, 72);
	my $cipher = Crypt::Eksblowfish::Uklblowfish->new($passphrase);
	return $cipher->encrypt("\xde\xad\xd0\x61\x23\xf6\xb0\x95");
}

sub match {
	my($self, $passphrase) = @_;
	return $passphrase ne "" &&
		$self->_hash_of($passphrase) eq $self->{hash};
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Crypt::Eksblowfish::Uklblowfish>

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
