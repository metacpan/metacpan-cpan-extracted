=head1 NAME

Authen::Passphrase::MD5Crypt - passphrases using the MD5-based Unix
crypt()

=head1 SYNOPSIS

	use Authen::Passphrase::MD5Crypt;

	$ppr = Authen::Passphrase::MD5Crypt->new(
			salt => "Vd3f8aG6",
			hash_base64 => "GcsdF4YCXb0PM2UmXjIoI1");

	$ppr = Authen::Passphrase::MD5Crypt->new(
			salt_random => 1,
			passphrase => "passphrase");

	$ppr = Authen::Passphrase::MD5Crypt->from_crypt(
		'$1$Vd3f8aG6$GcsdF4YCXb0PM2UmXjIoI1');

	$ppr = Authen::Passphrase::MD5Crypt->from_rfc2307(
		'{CRYPT}$1$Vd3f8aG6$GcsdF4YCXb0PM2UmXjIoI1');

	$salt = $ppr->salt;
	$hash_base64 = $ppr->hash_base64;

	if($ppr->match($passphrase)) { ...

	$passwd = $ppr->as_crypt;
	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using
the MD5-based Unix crypt() hash function.  This is a subclass of
L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.

The crypt() function in a modern Unix actually supports several
different passphrase schemes.  This class is concerned only with one
particular scheme, an MD5-based algorithm designed by Poul-Henning Kamp
and originally implemented in FreeBSD.  To handle the whole range of
passphrase schemes supported by the modern crypt(), see the
L<from_crypt|Authen::Passphrase/from_crypt> constructor and the
L<as_crypt|Authen::Passphrase/as_crypt> method in L<Authen::Passphrase>.

The MD5-based crypt() scheme uses the whole passphrase, a salt which
can in principle be an arbitrary byte string, and the MD5 message
digest algorithm.  First the passphrase and salt are hashed together,
yielding an MD5 message digest.  Then a new digest is constructed,
hashing together the passphrase, the salt, and the first digest, all in
a rather complex form.  Then this digest is passed through a thousand
iterations of a function which rehashes it together with the passphrase
and salt in a manner that varies between rounds.  The output of the last
of these rounds is the resulting passphrase hash.

In the crypt() function the raw hash output is then represented in ASCII
as a 22-character string using a base 64 encoding.  The base 64 digits
are "B<.>", "B</>", "B<0>" to "B<9>", "B<A>" to "B<Z>", "B<a>" to "B<z>"
(in ASCII order).  Because the base 64 encoding can represent 132 bits
in 22 digits, more than the 128 required, the last digit can only take
four of the base 64 digit values.  An additional complication is that
the bytes of the raw algorithm output are permuted in a bizarre order
before being represented in base 64.

There is no tradition of handling these passphrase hashes in raw
binary form.  The textual encoding described above, including the final
permutation, is used universally, so this class does not support any
binary format.

The complex algorithm was designed to be slow to compute, in order
to resist brute force attacks.  However, the complexity is fixed,
and the operation of Moore's Law has rendered it far less expensive
than intended.  If efficiency of a brute force attack is a concern,
see L<Authen::Passphrase::BlowfishCrypt>.

=cut

package Authen::Passphrase::MD5Crypt;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);
use Crypt::PasswdMD5 1.0 qw(unix_md5_crypt);
use Data::Entropy::Algorithms 0.000 qw(rand_int);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase::MD5Crypt->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the MD5-based crypt()
algorithm.  The following attributes may be given:

=over

=item B<salt>

The salt, as a raw string.  It may be any byte string, but in crypt()
usage it is conventionally limited to zero to eight base 64 digits.

=item B<salt_random>

Causes salt to be generated randomly.  The value given for this
attribute is ignored.  The salt will be a string of eight base 64 digits.
The source of randomness may be controlled by the facility described
in L<Data::Entropy>.

=item B<hash_base64>

The hash, as a string of 22 base 64 digits.  This is the final part of
what crypt() outputs.

=item B<passphrase>

A passphrase that will be accepted.

=back

The salt must be given, and either the hash or the passphrase.

=cut

sub new {
	my $class = shift;
	my $self = bless({}, $class);
	my $passphrase;
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "salt") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$value =~ m#\A[\x00-\xff]*\z#
				or croak "not a valid salt";
			$self->{salt} = "$value";
		} elsif($attr eq "salt_random") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$self->{salt} = "";
			for(my $i = 8; $i--; ) {
				$self->{salt} .= chr(rand_int(64));
			}
			$self->{salt} =~ tr#\x00-\x3f#./0-9A-Za-z#;
		} elsif($attr eq "hash_base64") {
			croak "hash specified redundantly"
				if exists($self->{hash_base64}) ||
					defined($passphrase);
			$value =~ m#\A[./0-9A-Za-z]{21}[./01]\z#
				or croak "\"$value\" is not a valid ".
						"MD5-based crypt() hash";
			$self->{hash_base64} = "$value";
		} elsif($attr eq "passphrase") {
			croak "passphrase specified redundantly"
				if exists($self->{hash_base64}) ||
					defined($passphrase);
			$passphrase = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	croak "salt not specified" unless exists $self->{salt};
	$self->{hash_base64} = $self->_hash_base64_of($passphrase)
		if defined $passphrase;
	croak "hash not specified" unless exists $self->{hash_base64};
	return $self;
}

=item Authen::Passphrase::MD5Crypt->from_crypt(PASSWD)

Generates a new passphrase recogniser object using the MD5-based crypt()
algorithm, from a crypt string.  The crypt string must consist of
"B<$1$>", the salt, "B<$>", then 22 base 64 digits giving the hash.
The salt may be up to 8 characters long, and cannot contain "B<$>"
or any character that cannot appear in a crypt string.

=cut

sub from_crypt {
	my($class, $passwd) = @_;
	if($passwd =~ /\A\$1\$/) {
		$passwd =~ m:\A\$1\$([!-#%-9;-~]{0,8})\$([./0-9A-Za-z]{22})\z:
			or croak "malformed \$1\$ data";
		my($salt, $hash) = ($1, $2);
		return $class->new(salt => $salt, hash_base64 => $hash);
	}
	return $class->SUPER::from_crypt($passwd);
}

=item Authen::Passphrase::MD5Crypt->from_rfc2307(USERPASSWORD)

Generates a new passphrase recogniser object using the MD5-based
crypt() algorithm, from an RFC 2307 string.  The string must consist of
"B<{CRYPT}>" (case insensitive) followed by an acceptable crypt string.

=back

=head1 METHODS

=over

=item $ppr->salt

Returns the salt, in raw form.

=cut

sub salt {
	my($self) = @_;
	return $self->{salt};
}

=item $ppr->hash_base64

Returns the hash value, as a string of 22 base 64 digits.

=cut

sub hash_base64 {
	my($self) = @_;
	return $self->{hash_base64};
}

=item $ppr->match(PASSPHRASE)

=item $ppr->as_crypt

=item $ppr->as_rfc2307

These methods are part of the standard L<Authen::Passphrase> interface.
Not every passphrase recogniser of this type can be represented as a
crypt string: the crypt format only allows the salt to be up to eight
bytes, and it cannot contain any NUL or "B<$>" characters.

=cut

sub _hash_base64_of {
	my($self, $passphrase) = @_;
	die "can't use a crypt-incompatible salt yet ".
			"(need generalised Crypt::MD5Passwd)"
		if $self->{salt} =~ /[^\!-\#\%-9\;-\~]/ ||
			length($self->{salt}) > 8;
	my $hash = unix_md5_crypt($passphrase, $self->{salt});
	$hash =~ s/\A.*\$//;
	return $hash;
}

sub match {
	my($self, $passphrase) = @_;
	return $self->_hash_base64_of($passphrase) eq $self->{hash_base64};
}

sub as_crypt {
	my($self) = @_;
	croak "can't put this salt into a crypt string"
		if $self->{salt} =~ /[^\!-\#\%-9\;-\~]/ ||
			length($self->{salt}) > 8;
	return "\$1\$".$self->{salt}."\$".$self->{hash_base64};
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Crypt::PasswdMD5>

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
