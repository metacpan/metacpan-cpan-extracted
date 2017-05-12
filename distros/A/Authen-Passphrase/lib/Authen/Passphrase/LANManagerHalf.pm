=head1 NAME

Authen::Passphrase::LANManagerHalf - passphrases using half the LAN
Manager algorithm

=head1 SYNOPSIS

	use Authen::Passphrase::LANManagerHalf;

	$ppr = Authen::Passphrase::LANManagerHalf->new(
		hash_hex => "855c3697d9979e78");

	$ppr = Authen::Passphrase::LANManagerHalf->new(
		passphrase => "passphr");

	$ppr = Authen::Passphrase::LANManagerHalf->from_crypt(
		'$LM$855c3697d9979e78');

	$ppr = Authen::Passphrase::LANManagerHalf->from_rfc2307(
		'{CRYPT}$LM$855c3697d9979e78');

	$hash = $ppr->hash;
	$hash_hex = $ppr->hash_hex;

	if($ppr->match($passphrase)) { ...

	$passwd = $ppr->as_crypt;
	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

An object of this class encapsulates half of a passphrase hashed
using the Microsoft LAN Manager hash function.  This is a subclass of
L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.  For the complete LAN
Manager hash function, see L<Authen::Passphrase::LANManager>.

In a spectacularly bad design decision, the Microsoft LAN Manager hash
function splits the passphrase into two parts and hashes them separately.
It is therefore possible to separate the halves of a LAN Manager hash,
and do things with them (such as crack them) separately.  This class is
about using such a hash half on its own.

The half hash algorithm can be used on up to seven Latin-1 characters of
passphrase.  First the passphrase is folded to uppercase, and zero-padded
to seven bytes.  Then the seven bytes are used as a 56-bit DES key, to
encrypt the fixed plaintext block "KGS!@#$%".  The eight byte ciphertext
block is the half hash.  There is no salt.

I<Warning:> Don't even think about using this seriously.  It's an
exceptionally weak design, flawed in pretty much every respect.

=cut

package Authen::Passphrase::LANManagerHalf;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);
use Crypt::DES;

our $VERSION = "0.008";

use parent "Authen::Passphrase";

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase::LANManagerHalf->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the LAN Manager half
hash algorithm.  The following attributes may be given:

=over

=item B<hash>

The hash, as a string of 8 bytes.

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
			$value =~ m#\A[\x00-\xff]{8}\z#
				or croak "not a valid LAN Manager half hash";
			$self->{hash} = "$value";
		} elsif($attr eq "hash_hex") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[0-9A-Fa-f]{16}\z#
				or croak "\"$value\" is not a valid ".
						"hex LAN Manager half hash";
			$self->{hash} = pack("H*", $value);
		} elsif($attr eq "passphrase") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$self->_passphrase_acceptable($value)
				or croak "can't accept a passphrase exceeding".
						" seven bytes";
			$passphrase = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	$self->{hash} = $self->_hash_of($passphrase) if defined $passphrase;
	croak "hash not specified" unless exists $self->{hash};
	return $self;
}

=item Authen::Passphrase::LANManagerHalf->from_crypt(PASSWD)

Generates a new LAN Manager half passphrase recogniser object from a
crypt string.  The crypt string must consist of "B<$LM$>" followed by
the hash in lowercase hexadecimal.

=cut

sub from_crypt {
	my($class, $passwd) = @_;
	if($passwd =~ /\A\$LM\$/) {
		$passwd =~ m#\A\$LM\$([0-9a-f]{16})\z#
			or croak "malformed \$LM\$ data";
		my $hash = $1;
		return $class->new(hash_hex => $hash);
	}
	return $class->SUPER::from_crypt($passwd);
}

=item Authen::Passphrase::LANManagerHalf->from_rfc2307(USERPASSWORD)

Generates a new LAN Manager half passphrase recogniser object from an RFC
2307 string.  The string must consist of "B<{CRYPT}>" (case insensitive)
followed by an acceptable crypt string.

=back

=head1 METHODS

=over

=item $ppr->hash

Returns the hash value, as a string of 8 bytes.

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

=item $ppr->as_crypt

=item $ppr->as_rfc2307

These methods are part of the standard L<Authen::Passphrase> interface.

=cut

sub _passphrase_acceptable {
	my($self, $passphrase) = @_;
	return $passphrase =~ /\A[\x00-\xff]{0,7}\z/;
}

sub _hash_of {
	my($self, $passphrase) = @_;
	$passphrase = uc($passphrase);
	$passphrase = "\0".$passphrase."\0\0\0\0\0\0\0\0";
	my $key = "";
	for(my $i = 0; $i != 8; $i++) {
		my $a = ord(substr($passphrase, $i, 1));
		my $b = ord(substr($passphrase, $i+1, 1));
		$key .= chr((($b >> $i) | ($a << (8-$i))) & 0xfe);
	}
	return Crypt::DES->new($key)->encrypt("KGS!\@#\$%");
}

sub match {
	my($self, $passphrase) = @_;
	return $self->_passphrase_acceptable($passphrase) &&
		$self->_hash_of($passphrase) eq $self->{hash};
}

sub as_crypt {
	my($self) = @_;
	return "\$LM\$".$self->hash_hex;
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Authen::Passphrase::LANManager>,
L<Crypt::DES>

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
