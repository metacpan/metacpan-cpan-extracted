=head1 NAME

Authen::Passphrase::SaltedDigest - passphrases using the generic salted
digest algorithm

=head1 SYNOPSIS

	use Authen::Passphrase::SaltedDigest;

	$ppr = Authen::Passphrase::SaltedDigest->new(
		algorithm => "SHA-1",
		salt_hex => "a9f524b1e819e96d8cc7".
			    "a04d5471e8b10c84e596",
		hash_hex => "8270d9d1a345d3806ab2".
			    "3b0385702e10f1acc943");

	$ppr = Authen::Passphrase::SaltedDigest->new(
		algorithm => "SHA-1", salt_random => 20,
		passphrase => "passphrase");

	$ppr = Authen::Passphrase::SaltedDigest->from_rfc2307(
		"{SSHA}gnDZ0aNF04BqsjsDhXAuEPGsy".
		"UOp9SSx6BnpbYzHoE1UceixDITllg==");

	$algorithm = $ppr->algorithm;
	$salt = $ppr->salt;
	$salt_hex = $ppr->salt_hex;
	$hash = $ppr->hash;
	$hash_hex = $ppr->hash_hex;

	if($ppr->match($passphrase)) { ...

	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

An object of this class encapsulates a passphrase hashed using
a generic digest-algorithm-based scheme.  This is a subclass of
L<Authen::Passphrase>, and this document assumes that the reader is
familiar with the documentation for that class.

The salt is an arbitrary string of bytes.  It is appended to passphrase,
and the combined string is passed through a specified message digest
algorithm.  The output of the message digest algorithm is the passphrase
hash.

The strength depends entirely on the choice of digest algorithm, so
choose according to the level of security required.  SHA-1 is suitable for
most applications, but recent work has revealed weaknesses in the basic
structure of MD5, SHA-1, SHA-256, and all similar digest algorithms.
A new generation of digest algorithms emerged in 2008, centred around
NIST's competition to design SHA-3.  Once these algorithms have been
subjected to sufficient cryptanalysis, the survivors will be preferred
over SHA-1 and its generation.

Digest algorithms are generally designed to be as efficient to compute
as possible for their level of cryptographic strength.  An unbroken
digest algorithm makes brute force the most efficient way to attack it,
but makes no effort to resist a brute force attack.  This is a concern
in some passphrase-using applications.

The use of this kind of passphrase scheme is generally recommended for
new systems.  Choice of digest algorithm is important: SHA-1 is suitable
for most applications.  If efficiency of brute force attack is a concern,
see L<Authen::Passphrase::BlowfishCrypt> for an algorithm designed to
be expensive to compute.

=cut

package Authen::Passphrase::SaltedDigest;

{ use 5.006; }
use warnings;
use strict;

use Authen::Passphrase 0.003;
use Carp qw(croak);
use Data::Entropy::Algorithms 0.000 qw(rand_bits);
use Digest 1.00;
use MIME::Base64 2.21 qw(encode_base64 decode_base64);
use Module::Runtime 0.011 qw(is_valid_module_name use_module);
use Params::Classify 0.000 qw(is_string is_blessed);

our $VERSION = "0.008";

use parent "Authen::Passphrase";

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase::SaltedDigest->new(ATTR => VALUE, ...)

Generates a new passphrase recogniser object using the generic salted
digest algorithm.  The following attributes may be given:

=over

=item B<algorithm>

Specifies the algorithm to use.  If it is a reference to a blessed object,
it must be possible to call the L</new> method on that object to generate
a digest context object.

If it is a string containing the subsequence "::" then it specifies
a module to use.  A plain package name in bareword syntax, optionally
preceded by "::" (so that top-level packages can be recognised as such),
is taken as a class name, on which the L</new> method will be called to
generate a digest context object.  The package name may optionally be
followed by "-" to cause automatic loading of the module, and the "-"
(if present) may optionally be followed by a version number that will
be checked against.  For example, "Digest::MD5-1.99_53" would load the
L<Digest::MD5> module and check that it is at least version 1.99_53
(which is the first version that can be used by this module).

A string not containing "::" and which is understood by
L<< Digest->new|Digest/"OO INTERFACE" >> will be passed to that function
to generate a digest context object.

Any other type of algorithm specifier has undefined behaviour.

The digest context objects must support at least the standard C<add>
and C<digest> methods.

=item B<salt>

The salt, as a raw string of bytes.  Defaults to the empty string,
yielding an unsalted scheme.

=item B<salt_hex>

The salt, as a string of hexadecimal digits.  Defaults to the empty
string, yielding an unsalted scheme.

=item B<salt_random>

Causes salt to be generated randomly.  The value given for this
attribute must be a non-negative integer, giving the number of bytes
of salt to generate.  (The same length as the hash is recommended.)
The source of randomness may be controlled by the facility described
in L<Data::Entropy>.

=item B<hash>

The hash, as a string of bytes.

=item B<hash_hex>

The hash, as a string of hexadecimal digits.

=item B<passphrase>

A passphrase that will be accepted.

=back

The digest algorithm must be given, and either the hash or the passphrase.

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
			$self->{algorithm} = $value;
		} elsif($attr eq "salt") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$value =~ m#\A[\x00-\xff]*\z#
				or croak "\"$value\" is not a valid salt";
			$self->{salt} = "$value";
		} elsif($attr eq "salt_hex") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			$value =~ m#\A(?:[0-9A-Fa-f]{2})+\z#
				or croak "\"$value\" is not a valid salt";
			$self->{salt} = pack("H*", $value);
		} elsif($attr eq "salt_random") {
			croak "salt specified redundantly"
				if exists $self->{salt};
			croak "\"$value\" is not a valid salt length"
				unless $value == int($value) && $value >= 0;
			$self->{salt} = rand_bits($value * 8);
		} elsif($attr eq "hash") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A[\x00-\xff]*\z#
				or croak "\"$value\" is not a valid hash";
			$self->{hash} = "$value";
		} elsif($attr eq "hash_hex") {
			croak "hash specified redundantly"
				if exists($self->{hash}) ||
					defined($passphrase);
			$value =~ m#\A(?:[0-9A-Fa-f]{2})+\z#
				or croak "\"$value\" is not a valid hash";
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
	croak "algorithm not specified" unless exists $self->{algorithm};
	$self->{salt} = "" unless exists $self->{salt};
	if(defined $passphrase) {
		$self->{hash} = $self->_hash_of($passphrase);
	} elsif(exists $self->{hash}) {
		croak "not a valid ".$self->{algorithm}." hash"
			unless length($self->{hash}) ==
				length($self->_hash_of(""));
	} else {
		croak "hash not specified";
	}
	return $self;
}

=item Authen::Passphrase::SaltedDigest->from_rfc2307(USERPASSWORD)

Generates a salted-digest passphrase recogniser from the supplied
RFC2307 encoding.  The scheme identifier gives the digest algorithm and
controls whether salt is permitted.  It is followed by a base 64 string,
using standard MIME base 64, which encodes the concatenation of the hash
and salt.

The scheme identifiers accepted are "B<{MD4}>" (unsalted MD4), "B<{MD5}>"
(unsalted MD5), "B<{RMD160}>" (unsalted RIPEMD-160), "B<{SHA}>" (unsalted
SHA-1), "B<{SMD5}>" (salted MD5), and "B<{SSHA}>" (salted SHA-1).
All scheme identifiers are recognised case-insensitively.

=cut

my %rfc2307_scheme_meaning = (
	"MD4" => ["MD4", 16, 0],
	"MD5" => ["MD5", 16, 0],
	"RMD160" => ["Crypt::RIPEMD160-", 20, 0],
	"SHA" => ["SHA-1", 20, 0],
	"SMD5" => ["MD5", 16, 1],
	"SSHA" => ["SHA-1", 20, 1],
);

sub from_rfc2307 {
	my($class, $userpassword) = @_;
	return $class->SUPER::from_rfc2307($userpassword)
		unless $userpassword =~ /\A\{([-0-9A-Za-z]+)\}/;
	my $scheme = uc($1);
	my $meaning = $rfc2307_scheme_meaning{$scheme};
	return $class->SUPER::from_rfc2307($userpassword)
		unless defined $meaning;
	croak "malformed {$scheme} data"
		unless $userpassword =~
			m#\A\{.*?\}
			  ((?>(?:[A-Za-z0-9+/]{4})*)
			   (?:|[A-Za-z0-9+/]{2}[AEIMQUYcgkosw048]=|
			       [A-Za-z0-9+/][AQgw]==))\z#x;
	my $b64 = $1;
	my $hash_and_salt = decode_base64($b64);
	my($algorithm, $hash_len, $salt_allowed) = @$meaning;
	croak "insufficient hash data for {$scheme}"
		if length($hash_and_salt) < $hash_len;
	croak "too much hash data for {$scheme}"
		if !$salt_allowed && length($hash_and_salt) > $hash_len;
	return $class->new(algorithm => $algorithm,
		salt => substr($hash_and_salt, $hash_len),
		hash => substr($hash_and_salt, 0, $hash_len));
}

=back

=head1 METHODS

=over

=item $ppr->algorithm

Returns the digest algorithm, in the same form as supplied to the
constructor.

=cut

sub algorithm {
	my($self) = @_;
	return $self->{algorithm};
}

=item $ppr->salt

Returns the salt, in raw form.

=cut

sub salt {
	my($self) = @_;
	return $self->{salt};
}

=item $ppr->salt_hex

Returns the salt, as a string of hexadecimal digits.

=cut

sub salt_hex {
	my($self) = @_;
	return unpack("H*", $self->{salt});
}

=item $ppr->hash

Returns the hash value, in raw form.

=cut

sub hash {
	my($self) = @_;
	return $self->{hash};
}

=item $ppr->hash_hex

Returns the hash value, as a string of hexadecimal digits.

=cut

sub hash_hex {
	my($self) = @_;
	return unpack("H*", $self->{hash});
}

=item $ppr->match(PASSPHRASE)

=item $ppr->as_rfc2307

These methods are part of the standard L<Authen::Passphrase> interface.
Only passphrase recognisers using certain well-known digest algorithms
can be represented in RFC 2307 form.

=cut

sub _hash_of {
	my($self, $passphrase) = @_;
	my $alg = $self->{algorithm};
	my $ctx;
	if(is_string($alg)) {
		if($alg =~ /::/) {
			$alg =~ /\A(?:::)?([0-9a-zA-Z_:]+)
				   (-([0-9][0-9_]*(?:\._*[0-9][0-9_]*)?)?)?\z/x
				or croak "module spec `$alg' not understood";
			my($pkgname, $load_p, $modver) = ($1, $2, $3);
			croak "bad package name `$pkgname'"
				unless is_valid_module_name($pkgname);
			if($load_p) {
				if(defined $modver) {
					$modver =~ tr/_//d;
					use_module($pkgname, $modver);
				} else {
					use_module($pkgname);
				}
			}
			$ctx = $pkgname->new;
		} else {
			$ctx = Digest->new($alg);
		}
	} elsif(is_blessed($alg)) {
		$ctx = $alg->new;
	} else {
		croak "algorithm specifier `$alg' is of an unrecognised type";
	}
	$ctx->add($passphrase);
	$ctx->add($self->{salt});
	return $ctx->digest;
}

sub match {
	my($self, $passphrase) = @_;
	return $self->_hash_of($passphrase) eq $self->{hash};
}

my %rfc2307_scheme_for_digest_name = (
	"MD4" => "MD4",
	"MD5" => "MD5",
	"SHA-1" => "SHA",
	"SHA1" => "SHA",
);

my %rfc2307_scheme_for_package_name = (
	"Crypt::RIPEMD160" => "RMD160",
	"Digest::MD4" => "MD4",
	"Digest::MD5" => "MD5",
	"Digest::MD5::Perl" => "MD5",
	"Digest::Perl::MD4" => "MD4",
	"Digest::SHA" => "SHA",
	"Digest::SHA::PurePerl" => "SHA",
	"Digest::SHA1" => "SHA",
	"MD5" => "MD5",
	"RIPEMD160" => "RMD160",
);

sub as_rfc2307 {
	my($self) = @_;
	my $alg = $self->{algorithm};
	my $scheme;
	if(is_string($alg)) {
		if($alg =~ /::/) {
			$scheme = $rfc2307_scheme_for_package_name{$1}
				if $alg =~ /\A(?:::)?
					    ([0-9a-zA-Z_:]+)(?:-[0-9._]*)?\z/x;
		} else {
			$scheme = $rfc2307_scheme_for_digest_name{$alg};
		}
	}
	croak "don't know RFC 2307 scheme identifier for digest algorithm $alg"
		unless defined $scheme;
	return "{".($self->{salt} eq "" ? "" : "S").$scheme."}".
		encode_base64($self->{hash}.$self->{salt}, "");
}

=back

=head1 SEE ALSO

L<Authen::Passphrase>,
L<Crypt::SaltedHash>

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
