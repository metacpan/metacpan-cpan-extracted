=head1 NAME

Authen::Passphrase::PHPass - passphrases using the phpass algorithm

=head1 SYNOPSIS

	use Authen::Passphrase::PHPass;

	$ppr = Authen::Passphrase::PHPass->new(
		cost => 10, salt => "NaClNaCl",
		hash_base64 => "ObRxTm/.EiiYN02xUeAQs/");

	$ppr = Authen::Passphrase::PHPass->new(
		cost => 10, salt_random => 1,
		passphrase => "passphrase");

	$ppr = Authen::Passphrase::PHPass->from_crypt(
		'$P$8NaClNaClObRxTm/.EiiYN02xUeAQs/');

	$ppr = Authen::Passphrase::PHPass->from_rfc2307(
		'{CRYPT}$P$8NaClNaClObRxTm/.EiiYN02xUeAQs/');

	$cost = $ppr->cost;
	$cost_base64 = $ppr->cost_base64;
	$cost = $ppr->nrounds_log2;
	$cost_base64 = $ppr->nrounds_log2_base64;
	$salt = $ppr->salt;
	$hash = $ppr->hash;
	$hash_base64 = $ppr->hash_base64;

	if($ppr->match($passphrase)) { ...

	$passwd = $ppr->as_crypt;
	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using
the phpass algorithm invented by Solar Designer and described
at L<http://www.openwall.com/phpass/>.  This is a subclass of
L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.

The phpass algorithm is based on the MD5 message digest algorithm.
There is an eight-byte salt, which is conventionally restricted to
consist of base 64 digits.  There is also a cost parameter that controls
the expense of hashing.  First the salt and passphrase are concatenated
and hashed by MD5.  Then, 2^cost times, the hash from the previous stage
is concatenated with the passphrase and hashed by MD5.  The passphrase
hash is the output from the final iteration.

The passphrase hash is represented in ASCII using the crypt format with
prefix "B<$P$>".  The first character after the format prefix is a base 64
digit giving the cost parameter.  The next eight characters are the salt.
The salt is followed by 22 base 64 digits giving the hash.  The base 64
digits are "B<.>", "B</>", "B<0>" to "B<9>", "B<A>" to "B<Z>", "B<a>"
to "B<z>" (in ASCII order).

=cut

package Authen::Passphrase::PHPass;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);
use Data::Entropy::Algorithms 0.000 qw(rand_bits);
use Digest::MD5 1.99_53 ();

our $VERSION = "0.008";

use parent "Authen::Passphrase";

my $base64_digits = "./0123456789ABCDEFGHIJKLMNOPQRST".
		    "UVWXYZabcdefghijklmnopqrstuvwxyz";

sub _en_base64($) {
	my($bytes) = @_;
	my $nbytes = length($bytes);
	my $npadbytes = 2 - ($nbytes + 2) % 3;
	$bytes .= "\0" x $npadbytes;
	my $digits = "";
	for(my $i = 0; $i < $nbytes; $i += 3) {
		my $v = ord(substr($bytes, $i, 1)) |
			(ord(substr($bytes, $i+1, 1)) << 8) |
			(ord(substr($bytes, $i+2, 1)) << 16);
		$digits .= substr($base64_digits, $v & 0x3f, 1) .
			substr($base64_digits, ($v >> 6) & 0x3f, 1) .
			substr($base64_digits, ($v >> 12) & 0x3f, 1) .
			substr($base64_digits, ($v >> 18) & 0x3f, 1);
	}
	substr $digits, -$npadbytes, $npadbytes, "";
	return $digits;
}

sub _de_base64($) {
	my($digits) = @_;
	my $ndigits = length($digits);
	my $npadbytes = 3 - ($ndigits + 3) % 4;
	$digits .= "." x $npadbytes;
	my $bytes = "";
	for(my $i = 0; $i < $ndigits; $i += 4) {
		my $v = index($base64_digits, substr($digits,$i,1)) |
			(index($base64_digits, substr($digits,$i+1,1)) << 6) |
			(index($base64_digits, substr($digits,$i+2,1)) << 12) |
			(index($base64_digits, substr($digits,$i+3,1)) << 18);
		$bytes .= chr($v & 0xff) .
			chr(($v >> 8) & 0xff) .
			chr(($v >> 16) & 0xff);
	}
	substr $bytes, -$npadbytes, $npadbytes, "";
	return $bytes;
}

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase::PHPass->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the phpass algorithm.
The following attributes may be given:

=over

=item B<cost>

Base-two logarithm of the number of hashing rounds to perform.

=item B<cost_base64>

Base-two logarithm of the number of hashing rounds to perform, expressed
as a single base 64 digit.

=item B<nrounds_log2>

Synonym for B<cost>.

=item B<nrounds_log2_base64>

Synonym for B<cost_base64>.

=item B<salt>

The salt, as an eight-byte string.

=item B<salt_random>

Causes salt to be generated randomly.  The value given for this
attribute is ignored.  The salt will be a string of eight base 64 digits.
The source of randomness may be controlled by the facility described
in L<Data::Entropy>.

=item B<hash>

The hash, as a 16-byte string.

=item B<hash_base64>

The hash, as a string of 22 base 64 digits.

=item B<passphrase>

A passphrase that will be accepted.

=back

The cost and salt must be given, and either the hash or the passphrase.

=cut

sub new {
	my $class = shift;
	my $self = bless({}, $class);
	my $passphrase;
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "cost" || $attr eq "nrounds_log2") {
			croak "cost specified redundantly"
				if exists $self->{cost};
			croak "\"$value\" is not a valid cost parameter"
				unless $value == int($value) && $value >= 0 &&
					$value <= 30;
			$self->{cost} = 0+$value;
		} elsif($attr eq "cost_base64" ||
				$attr eq "nrounds_log2_base64") {
			croak "cost specified redundantly"
				if exists $self->{cost};
			croak "\"$value\" is not a valid cost parameter"
				unless $value =~ m#\A[./0-9A-S]\z#;
			$self->{cost} = index($base64_digits, $value);
		} elsif($attr eq "salt") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$value =~ m#\A[\x00-\xff]{8}\z#
				or croak "\"$value\" is not a valid salt";
			$self->{salt} = "$value";
		} elsif($attr eq "salt_random") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$self->{salt} = _en_base64(rand_bits(48));
		} elsif($attr eq "hash") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[\x00-\xff]{16}\z#
				or croak "not a valid raw hash";
			$self->{hash} = "$value";
		} elsif($attr eq "hash_base64") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[./0-9A-Za-z]{21}[./01]\z#
				or croak "\"$value\" is not a valid hash";
			$self->{hash} = _de_base64($value);
		} elsif($attr eq "passphrase") {
			croak "passphrase specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$passphrase = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	croak "cost not specified" unless exists $self->{cost};
	croak "salt not specified" unless exists $self->{salt};
	$self->{hash} = $self->_hash_of($passphrase) if defined $passphrase;
	croak "hash not specified" unless exists $self->{hash};
	return $self;
}

=item Authen::Passphrase::PHPass->from_crypt(PASSWD)

Generates a new phpass passphrase recogniser object from a crypt string.
The crypt string must consist of "B<$P$>", one base 64 character encoding
the cost, the salt, then 22 base 64 digits giving the hash.  The salt
must be exactly 8 characters long, and cannot contain any character that
cannot appear in a crypt string.

=cut

sub from_crypt {
	my($class, $passwd) = @_;
	if($passwd =~ /\A\$P\$/) {
		$passwd =~ m#\A\$P\$([./0-9A-Za-z])([!-9;-~]{8})
				([./0-9A-Za-z]{22})\z#x
			or croak "malformed \$P\$ data";
		my($cost, $salt, $hash) = ($1, $2, $3);
		return $class->new(cost_base64 => $cost, salt => $salt,
			hash_base64 => $hash);
	}
	return $class->SUPER::from_crypt($passwd);
}

=item Authen::Passphrase::PHPass->from_rfc2307(USERPASSWORD)

Generates a new phpass passphrase recogniser object from an RFC 2307
string.  The string must consist of "B<{CRYPT}>" (case insensitive)
followed by an acceptable crypt string.

=back

=head1 METHODS

=over

=item $ppr->cost

Returns the base-two logarithm of the number of hashing rounds that will
be performed.

=cut

sub cost {
	my($self) = @_;
	return $self->{cost};
}

=item $ppr->cost_base64

Returns the base-two logarithm of the number of hashing rounds that will
be performed, expressed as a single base 64 digit.

=cut

sub cost_base64 {
	my($self) = @_;
	return substr($base64_digits, $self->{cost}, 1);
}

=item $ppr->nrounds_log2

Synonym for L</cost>.

=cut

*nrounds_log2 = \&cost;

=item $ppr->nrounds_log2_base64

Synonym for L</cost_base64>.

=cut

*nrounds_log2_base64 = \&cost_base64;

=item $ppr->salt

Returns the salt, as a string of eight bytes.

=cut

sub salt {
	my($self) = @_;
	return $self->{salt};
}

=item $ppr->hash

Returns the hash value, as a string of 16 bytes.

=cut

sub hash {
	my($self) = @_;
	return $self->{hash};
}

=item $ppr->hash_base64

Returns the hash value, as a string of 22 base 64 digits.

=cut

sub hash_base64 {
	my($self) = @_;
	return _en_base64($self->{hash});
}

=item $ppr->match(PASSPHRASE)

=item $ppr->as_crypt

=item $ppr->as_rfc2307

These methods are part of the standard L<Authen::Passphrase> interface.

=cut

sub _hash_of {
	my($self, $passphrase) = @_;
	my $ctx = Digest::MD5->new;
	$ctx->add($self->{salt});
	$ctx->add($passphrase);
	my $hash = $ctx->digest;
	for(my $i = 1 << $self->{cost}; $i--; ) {
		$ctx = Digest::MD5->new;
		$ctx->add($hash);
		$ctx->add($passphrase);
		$hash = $ctx->digest;
	}
	return $hash;
}

sub match {
	my($self, $passphrase) = @_;
	return $self->_hash_of($passphrase) eq $self->{hash};
}

sub as_crypt {
	my($self) = @_;
	croak "can't put this salt into a crypt string"
		if $self->{salt} =~ /[^!-9;-~]/;
	return "\$P\$".$self->cost_base64.$self->{salt}.$self->hash_base64;
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Digest::MD5>

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
