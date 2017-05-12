=head1 NAME

Authen::Passphrase::VMSPurdy - passphrases with the VMS Purdy polynomial
system

=head1 SYNOPSIS

	use Authen::Passphrase::VMSPurdy;

	$ppr = Authen::Passphrase::VMSPurdy->new(
			username => "jrandom", salt => 25362,
			hash_hex => "832a0c270179584a");

	$ppr = Authen::Passphrase::VMSPurdy->new(
			username => "jrandom", salt_random => 1,
			passphrase => "passphrase");

	$ppr = Authen::Passphrase::VMSPurdy->from_crypt(
		'$VMS3$1263832A0C270179584AJRANDOM');

	$ppr = Authen::Passphrase::VMSPurdy->from_rfc2307(
		'{CRYPT}$VMS3$1263832A0C270179584AJRANDOM');

	$algorithm = $ppr->algorithm;
	$username = $ppr->username;
	$salt = $ppr->salt;
	$hash = $ppr->hash;
	$hash_hex = $ppr->hash_hex;

	if($ppr->match($passphrase)) { ...

	$passwd = $ppr->as_crypt;
	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using one of
the Purdy polynomial hash functions used in VMS.  This is a subclass
of L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.

The core of the Purdy polynomial hashing algorithm transforms
one 64-bit number into another 64-bit number.  It was
developed by George B. Purdy, and described in the paper
"A High Security Log-in Procedure" which can be found at
L<http://portal.acm.org/citation.cfm?id=361089&dl=GUIDE&coll=ACM&CFID=15151515&CFTOKEN=6184618>.

For practical use in passphrase hashing, the Purdy polynomial must
be augmented by a procedure to turn a variable-length passphrase
into the initial 64-bit number to be hashed.  In VMS this pre-hashing
phase also incorporates the username of the account to which access is
being controlled, in order to prevent identical passphrases yielding
identical hashes.  This is a form of salting.  Another salt parameter,
a 16-bit integer, is also included, this one going under the name "salt".

There are three variants of the pre-hashing algorithm.  The original
version, known as "B<PURDY>" and used during field testing of VMS 2.0,
truncates or space-pads the username to a fixed length.  The second
version, known as "B<PURDY_V>" and used from VMS 2.0 up to (but not
including) VMS 5.4, properly handles the variable-length nature of
the username.  The third version, known as "B<PURDY_S>" and used from
VMS 5.4 onwards, performs some extra bit rotations to avoid aliasing
problems when pre-hashing long strings.  All three versions are supported
by this module.

VMS heavily restricts the composition of both usernames and passphrases.
They may only contain alphanumerics, "B<$>", and "B<_>".  Case is
insignificant.  Usernames must be between 1 and 31 characters long,
and passphrases must be between 1 and 32 characters long.  This module
enforces these rules.  An invalid passphrase is never accepted as
matching.

=cut

package Authen::Passphrase::VMSPurdy;

{ use 5.006; }
use warnings;
use strict;

use Authen::DecHpwd 2.003 qw(lgi_hpwd UAI_C_PURDY UAI_C_PURDY_V UAI_C_PURDY_S);
use Authen::Passphrase 0.003;
use Carp qw(croak);
use Data::Entropy::Algorithms 0.000 qw(rand_int);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase::VMSPurdy->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the VMS Purdy
polynomial algorithm family.  The following attributes may be given:

=over

=item B<algorithm>

A string indicating which variant of the algorithm is to be used.
Valid values are "B<PURDY>" (the original), "B<PURDY_V>" (modified to
use full length of the username), and "B<PURDY_S>" (extra rotations to
avoid aliasing when processing long strings).  Default "B<PURDY_S>".

=item B<username>

A string to be used as the `username' salt parameter.  It is limited to
VMS username syntax.

=item B<salt>

The salt, as an integer in the range [0, 65536).

=item B<salt_hex>

The salt, as a string of four hexadecimal digits.  The first two
digits must give the least-significant byte and the last two give
the most-significant byte, with most-significant nybble first within
each byte.

=item B<salt_random>

Causes salt to be generated randomly.  The value given for this attribute
is ignored.  The source of randomness may be controlled by the facility
described in L<Data::Entropy>.

=item B<hash>

The hash, as a string of eight bytes.

=item B<hash_hex>

The hash, as a string of 16 hexadecimal digits.

=item B<passphrase>

A passphrase that will be accepted.  It is limited to VMS passphrase
syntax.

=back

The username and salt must be given, and either the hash or the
passphrase.

=cut

sub new {
	my $class = shift;
	my $self = bless({}, $class);
	my $passphrase;
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "algorithm") {
			croak "algorithm specified redundantly"
				if exists $self->{algorithm};
			$value =~ m#\APURDY(?:|_V|_S)\z#
				or croak "not a valid algorithm";
			$self->{algorithm} = "$value";
		} elsif($attr eq "username") {
			croak "username specified redundantly"
				if exists $self->{username};
			$value =~ m#\A[_\$0-9A-Za-z]{1,31}\z#
				or croak "not a valid VMS username";
			$self->{username} = uc("$value");
		} elsif($attr eq "salt") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$value == int($value) && $value >= 0 && $value < 65536
				or croak "not a valid salt";
			$self->{salt} = 0+$value;
		} elsif($attr eq "salt_hex") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$value =~ /\A([0-9a-fA-F]{2})([0-9a-fA-F]{2})\z/
				or croak "not a valid salt";
			$self->{salt} = hex($2.$1);
		} elsif($attr eq "salt_random") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$self->{salt} = rand_int(65536);
		} elsif($attr eq "hash") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[\x00-\xff]{8}\z#
				or croak "not a valid raw hash";
			$self->{hash} = "$value";
		} elsif($attr eq "hash_hex") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[0-9A-Fa-f]{16}\z#
				or croak "not a valid hexadecimal hash";
			$self->{hash} = pack("H*", $value);
		} elsif($attr eq "passphrase") {
			croak "passphrase specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$self->_passphrase_acceptable($value)
				or croak "can't accept that passphrase";
			$passphrase = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	$self->{algorithm} = "PURDY_S" unless exists $self->{algorithm};
	croak "username not specified" unless exists $self->{username};
	croak "salt not specified" unless exists $self->{salt};
	$self->{hash} = $self->_hash_of($passphrase)
		if defined $passphrase;
	croak "hash not specified" unless exists $self->{hash};
	return $self;
}

=item Authen::Passphrase::VMSPurdy->from_crypt(PASSWD)

Generates a new passphrase recogniser object using the VMS Purdy
polynomial algorithm family, from a crypt string.  The string must
consist of an algorithm identifier, the salt in hexadecimal, the hash
in hexadecimal, then the username.  The salt must be given as four
hexadecimal digits, the first two giving the least-significant byte and
the last two giving the most-significant byte, with most-significant
nybble first within each byte.  The algorithm identifier must be
"B<$VMS1$>" for "B<PURDY>", "B<$VMS2$>" for "B<PURDY_V>", or "B<$VMS3$>"
for "B<PURDY_S>".  The whole crypt string must be uppercase.

=cut

my %decode_crypt_alg_num = (
	"1" => "PURDY",
	"2" => "PURDY_V",
	"3" => "PURDY_S",
);

sub from_crypt {
	my($class, $passwd) = @_;
	if($passwd =~ /\A\$VMS([123])\$/) {
		my $alg = $1;
		$passwd =~ /\A\$VMS[123]\$([0-9A-F]{4})
			    ([0-9A-F]{16})([_\$0-9A-Z]{1,31})\z/x
			or croak "malformed \$VMS${alg}\$ data";
		my($salt, $hash, $un) = ($1, $2, $3);
		return $class->new(algorithm => $decode_crypt_alg_num{$alg},
			username => $un, salt_hex => $salt, hash_hex => $hash);
	}
	return $class->SUPER::from_crypt($passwd);
}

=item Authen::Passphrase::VMSPurdy->from_rfc2307(USERPASSWORD)

Generates a new passphrase recogniser object using the VMS Purdy
polynomial algorithm family, from an RFC 2307 string.  The string must
consist of "B<{CRYPT}>" (case insensitive) followed by an acceptable
crypt string.

=back

=head1 METHODS

=over

=item $ppr->algorithm

Returns the algorithm variant identifier string.  It may be "B<PURDY>"
(the original), "B<PURDY_V>" (modified to use full length of the
username), and "B<PURDY_S>" (extra rotations to avoid aliasing when
processing long strings).

=cut

sub algorithm {
	my($self) = @_;
	return $self->{algorithm};
}

=item $ppr->username

Returns the username string.  All alphabetic characters in it are
uppercase, which is the canonical form.

=cut

sub username {
	my($self) = @_;
	return $self->{username};
}

=item $ppr->salt

Returns the salt, as an integer.

=cut

sub salt {
	my($self) = @_;
	return $self->{salt};
}

=item $ppr->salt_hex

Returns the salt, as a string of four hexadecimal digits.  The first
two digits give the least-significant byte and the last two give the
most-significant byte, with most-significant nybble first within each
byte.

=cut

sub salt_hex {
	my($self) = @_;
	return sprintf("%02X%02X", $self->{salt} & 0xff, $self->{salt} >> 8);
}

=item $ppr->hash

Returns the hash value, as a string of eight bytes.

=cut

sub hash {
	my($self) = @_;
	return $self->{hash};
}

=item $ppr->hash_hex

Returns the hash value, as a string of 16 uppercase hexadecimal digits.

=cut

sub hash_hex {
	my($self) = @_;
	return uc(unpack("H*", $self->{hash}));
}

=item $ppr->match(PASSPHRASE)

=item $ppr->as_crypt

=item $ppr->as_rfc2307

These methods are part of the standard L<Authen::Passphrase> interface.

=cut

sub _passphrase_acceptable {
	my($self, $passphrase) = @_;
	return $passphrase =~ /\A[_\$0-9A-Za-z]{1,32}\z/;
}

my %hpwd_alg_num = (
	PURDY => UAI_C_PURDY,
	PURDY_V => UAI_C_PURDY_V,
	PURDY_S => UAI_C_PURDY_S,
);

sub _hash_of {
	my($self, $passphrase) = @_;
	return lgi_hpwd($self->{username}, uc($passphrase),
			$hpwd_alg_num{$self->{algorithm}}, $self->{salt});
}

sub match {
	my($self, $passphrase) = @_;
	return $self->_passphrase_acceptable($passphrase) &&
		$self->_hash_of($passphrase) eq $self->{hash};
}

my %crypt_alg_num = (
	PURDY => "1",
	PURDY_V => "2",
	PURDY_S => "3",
);

sub as_crypt {
	my($self) = @_;
	return "\$VMS".$crypt_alg_num{$self->{algorithm}}."\$".
		$self->salt_hex.$self->hash_hex.$self->{username};
}

=back

=head1 SEE ALSO

L<Authen::DecHpwd>,
L<Authen::Passphrase>

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
