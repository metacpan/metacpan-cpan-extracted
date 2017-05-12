=head1 NAME

Authen::Passphrase::NTHash - passphrases using the NT-Hash algorithm

=head1 SYNOPSIS

	use Authen::Passphrase::NTHash;

	$ppr = Authen::Passphrase::NTHash->new(
		hash_hex => "7f8fe03093cc84b267b109625f6bbf4b");

	$ppr = Authen::Passphrase::NTHash->new(
		passphrase => "passphrase");

	$ppr = Authen::Passphrase::NTHash->from_crypt(
		'$3$$7f8fe03093cc84b267b109625f6bbf4b');

	$ppr = Authen::Passphrase::NTHash->from_rfc2307(
		'{MSNT}7f8fe03093cc84b267b109625f6bbf4b');

	$hash = $ppr->hash;
	$hash_hex = $ppr->hash_hex;

	if($ppr->match($passphrase)) { ...

	$passwd = $ppr->as_crypt;
	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using the NT-Hash
function.  This is a subclass of L<Authen::Passphrase>, and this document
assumes that the reader is familiar with the documentation for that class.

The NT-Hash scheme is based on the MD4 digest algorithm.  Up to 128
characters of passphrase (characters beyond the 128th are ignored)
are represented in Unicode, and hashed using MD4.  No salt is used.

I<Warning:> MD4 is a weak hash algorithm by current standards, and the
lack of salt is a design flaw in this scheme.  Use this for compatibility
only, not by choice.

=cut

package Authen::Passphrase::NTHash;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);
use Digest::MD4 1.2 qw(md4);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase::NTHash->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the NT-Hash algorithm.
The following attributes may be given:

=over

=item B<hash>

The hash, as a string of 16 bytes.

=item B<hash_hex>

The hash, as a string of 32 hexadecimal digits.

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
			$value =~ m#\A[\x00-\xff]{16}\z#
				or croak "not a valid MD4 hash";
			$self->{hash} = "$value";
		} elsif($attr eq "hash_hex") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[0-9A-Fa-f]{32}\z#
				or croak "\"$value\" is not a valid ".
						"hex MD4 hash";
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

=item Authen::Passphrase::NTHash->from_crypt(PASSWD)

Generates a new NT-Hash passphrase recogniser object from a crypt string.
Two forms are accepted.  In the first form, the he crypt string must
consist of "B<$3$$>" (note the extra "B<$>") followed by the hash in
lowercase hexadecimal.  In the second form, the he crypt string must
consist of "B<$NT$>" followed by the hash in lowercase hexadecimal.

=cut

sub from_crypt {
	my($class, $passwd) = @_;
	if($passwd =~ /\A\$3\$/) {
		$passwd =~ m#\A\$3\$\$([0-9a-f]{32})\z#
			or croak "malformed \$3\$ data";
		my $hash = $1;
		return $class->new(hash_hex => $hash);
	} elsif($passwd =~ /\A\$NT\$/) {
		$passwd =~ m#\A\$NT\$([0-9a-f]{32})\z#
			or croak "malformed \$NT\$ data";
		my $hash = $1;
		return $class->new(hash_hex => $hash);
	}
	return $class->SUPER::from_crypt($passwd);
}

=item Authen::Passphrase::NTHash->from_rfc2307(USERPASSWORD)

Generates a new NT-Hash passphrase recogniser object from an RFC
2307 string.  Two forms are accepted.  In the first form, the string
must consist of "B<{MSNT}>" followed by the hash in hexadecimal; case
is ignored.  In the second form, the string must consist of "B<{CRYPT}>"
(case insensitive) followed by an acceptable crypt string.

=cut

sub from_rfc2307 {
	my($class, $userpassword) = @_;
	if($userpassword =~ /\A\{(?i:msnt)\}/) {
		$userpassword =~ /\A\{.*?\}([0-9a-fA-F]{32})\z/
			or croak "malformed {MSNT} data";
		my $hash = $1;
		return $class->new(hash_hex => $hash);
	}
	return $class->SUPER::from_rfc2307($userpassword);
}

=back

=head1 METHODS

=over

=item $ppr->hash

Returns the hash value, as a string of 16 bytes.

=cut

sub hash {
	my($self) = @_;
	return $self->{hash};
}

=item $ppr->hash_hex

Returns the hash value, as a string of 32 hexadecimal digits.

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

sub _hash_of {
	my($self, $passphrase) = @_;
	$passphrase = substr($passphrase, 0, 128);
	$passphrase =~ s/(.)/pack("v", ord($1))/eg;
	return md4($passphrase);
}

sub match {
	my($self, $passphrase) = @_;
	return $self->_hash_of($passphrase) eq $self->{hash};
}

sub as_crypt {
	my($self) = @_;
	return "\$3\$\$".$self->hash_hex;
}

sub as_rfc2307 {
	my($self) = @_;
	return "{MSNT}".$self->hash_hex;
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Digest::MD4>

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
