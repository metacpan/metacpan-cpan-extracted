=head1 NAME

Authen::Passphrase - hashed passwords/passphrases as objects

=head1 SYNOPSIS

	use Authen::Passphrase;

	$ppr = Authen::Passphrase->from_crypt($passwd);
	$ppr = Authen::Passphrase->from_rfc2307($userPassword);

	if($ppr->match($passphrase)) { ...

	$passphrase = $ppr->passphrase;

	$crypt = $ppr->as_crypt;
	$userPassword = $ppr->as_rfc2307;

=head1 DESCRIPTION

This is the base class for a system of objects that encapsulate
passphrases.  An object of this type is a passphrase recogniser: its
job is to recognise whether an offered passphrase is the right one.
For security, such passphrase recognisers usually do not themselves know
the passphrase they are looking for; they can merely recognise it when
they see it.  There are many schemes in use to achieve this effect,
and the intent of this class is to provide a consistent interface to
them all, hiding the details.

The CPAN package Authen-Passphrase contains implementations of several
specific passphrase schemes in addition to the base class.  See the
specific classes for notes on the security properties of each scheme.
In new systems, if there is a choice of which passphrase algorithm to
use, it is recommended to use L<Authen::Passphrase::SaltedDigest> or
L<Authen::Passphrase::BlowfishCrypt>.  Most other schemes are too weak
for new applications, and should be used only for backward compatibility.

=head2 Side-channel cryptanalysis

Both the Authen-Passphrase framework and most of the underlying
cryptographic algorithm implementations are vulnerable to side-channel
cryptanalytic attacks.  However, the impact of this is quite limited.

Unlike the case of symmetric encryption, where a side-channel attack can
extract the plaintext directly, the cryptographic operations involved in
passphrase recognition don't directly process the correct passphrase.
A sophisticated side-channel attack, applied when offering incorrect
passphrases for checking, could potentially extract salt (from the
operation of the hashing algorithm) and the target hash value (from
the comparison of hash values).  This would enable a cryptanalytic or
brute-force attack on the passphrase recogniser to be performed offline.
This is not a disaster; the very intent of storing only a hash of
the correct passphrase is that leakage of these stored values doesn't
compromise the passphrase.

In a typical usage scenario for this framework, the side-channel attacks
that can be mounted are very restricted.  If authenticating network
users, typically an attacker has no access at all to power consumption,
electromagnetic emanation, and other such side channels.  The only
side channel that is readily available is timing, and the precision of
timing measurements is significantly blunted by the normal processes of
network communication.  For example, it would not normally be feasible
to mount a timing attack against hash value comparison (to see how far
through the values the first mismatch was).

Perl as a whole has not been built as a platform for
side-channel-resistant cryptography, so hardening Authen-Passphrase and
its underlying algorithms is not feasible.  In any serious use of Perl
for cryptography, including for authentication using Authen-Passphrase,
an analysis should be made of the exposure to side-channel attacks,
and if necessary efforts made to further blunt the timing channel.

One timing attack that is very obviously feasible over the network is to
determine which of several passphrase hashing algorithms is being used.
This can potentially distinguish between classes of user accounts,
or distinguish between existing and non-existing user accounts when an
attacker is guessing usernames.  To obscure this information requires
an extreme restriction of the timing channel, most likely by explicitly
pausing to standardise the amount of time spent on authentication.
This defence also rules out essentially all other timing attacks.

=head1 PASSPHRASE ENCODINGS

Because hashed passphrases frequently need to be stored, various encodings
of them have been devised.  This class has constructors and methods to
support these.

=head2 crypt encoding

The Unix crypt() function, which performs passphrase hashing, returns
hashes in a textual format intended to be stored in a text file.
In particular, such hashes are stored in /etc/passwd (and now /etc/shadow)
to control access to Unix user accounts.  The same textual format has
been adopted and extended by other passphrase-handling software such as
password crackers.

For historical reasons, there are several different syntaxes used in this
format.  The original DES-based password scheme represents its hashes
simply as a string of thirteen base 64 digits.  An extended variant of
this scheme uses nineteen base 64 digits, preceded by an "B<_>" marker.
A more general syntax was developed later, which starts the string with
"B<$>", an alphanumeric scheme identifier, and another "B<$>".

In addition to actual passphrase hashes, the crypt format can also
represent a couple of special cases.  The empty string indicates that
there is no access control; it is possible to login without giving a
passphrase.  Finally, any string that is not a possible output of crypt()
may be used to prevent login completely; "B<*>" is the usual choice,
but other strings are used too.

crypt strings are intended to be used in text files that use colon and
newline characters as delimiters.  This module treats the crypt string
syntax as being limited to ASCII graphic characters excluding colon.

=head2 RFC 2307 encoding

RFC 2307 describes an encoding system for passphrase hashes, to be used
in the "B<userPassword>" attribute in LDAP databases.  It encodes hashes
as ASCII text, and supports several passphrase schemes in an extensible
way by starting the encoding with an alphanumeric scheme identifier
enclosed in braces.  There are several standard scheme identifiers.
The "B<{CRYPT}>" scheme allows the use of any crypt encoding.

This module treats the RFC 2307 string syntax as being limited to ASCII
graphic characters.

The RFC 2307 encoding is a good one, and is recommended for storage and
exchange of passphrase hashes.

=cut

package Authen::Passphrase;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use MIME::Base64 2.21 qw(decode_base64);
use Module::Runtime 0.011 qw(use_module);

our $VERSION = "0.008";

=head1 CONSTRUCTORS

=over

=item Authen::Passphrase->from_crypt(PASSWD)

Returns a passphrase recogniser object matching the supplied crypt
encoding.  This constructor may only be called on the base class, not
any subclass.

The specific passphrase recogniser class is loaded at runtime, so
successfully loading C<Authen::Passphrase> does not guarantee that
it will be possible to use a specific type of passphrase recogniser.
If necessary, check separately for presence and loadability of the
recogniser class.

Known scheme identifiers:

=over

=item B<$1$>

A baroque passphrase scheme based on MD5, designed by
Poul-Henning Kamp and originally implemented in FreeBSD.  See
L<Authen::Passphrase::MD5Crypt>.

=item B<$2$>

=item B<$2a$>

Two versions of a passphrase scheme based on Blowfish,
designed by Niels Provos and David Mazieres for OpenBSD.  See
L<Authen::Passphrase::BlowfishCrypt>.

=item B<$3$>

The NT-Hash scheme, which stores the MD4 hash of the passphrase expressed
in Unicode.  See L<Authen::Passphrase::NTHash>.

=item B<$IPB2$>

Invision Power Board 2.x salted MD5

=item B<$K4$>

Kerberos AFS DES

=item B<$LM$>

Half of the Microsoft LAN Manager hash scheme.  The two
halves of a LAN Manager hash can be separated and manipulated
independently; this represents such an isolated half.  See
L<Authen::Passphrase::LANManagerHalf>.

=item B<$NT$>

The NT-Hash scheme, which stores the MD4 hash of the passphrase expressed
in Unicode.  See L<Authen::Passphrase::NTHash>.

The B<$3$> identifier refers to the same hash algorithm, but has a
slightly different textual format (an extra "B<$>").

=item B<$P$>

Portable PHP password hash (phpass), based on MD5.  See
L<Authen::Passphrase::PHPass>.

=item B<$VMS1$>

=item B<$VMS2$>

=item B<$VMS3$>

Three variants of the Purdy polynomial system used in VMS.
See L<Authen::Passphrase::VMSPurdy>.

=item B<$af$>

Kerberos v4 TGT

=item B<$apr1$>

A variant of the B<$1$> scheme, used by Apache.

=item B<$krb5$>

Kerberos v5 TGT

=back

The historical formats supported are:

=over

=item "I<bbbbbbbbbbbbb>"

("I<b>" represents a base 64 digit.)  The original DES-based Unix password
hash scheme.  See L<Authen::Passphrase::DESCrypt>.

=item "B<_>I<bbbbbbbbbbbbbbbbbbb>"

("I<b>" represents a base 64 digit.)  Extended DES-based passphrase hash
scheme from BSDi.  See L<Authen::Passphrase::DESCrypt>.

=item ""

Accept any passphrase.  See L<Authen::Passphrase::AcceptAll>.

=item "B<*>"

To handle historical practice, anything non-empty but shorter than 13
characters and not starting with "B<$>" is treated as deliberately
rejecting all passphrases.  (See L<Authen::Passphrase::RejectAll>.)
Anything 13 characters or longer, or starting with "B<$>", that is not
recognised as a hash is treated as an error.

=back

There are also two different passphrase schemes that use a crypt string
consisting of 24 base 64 digits.  One is named "bigcrypt" and appears in
HP-UX, Digital Unix, and OSF/1 (see L<Authen::Passphrase::BigCrypt>).
The other is named "crypt16" and appears in Ultrix and Tru64 (see
L<Authen::Passphrase::Crypt16>).  These schemes conflict.  Neither of
them is accepted as a crypt string by this constructor; such strings
are regarded as invalid encodings.

=cut

my %crypt_scheme_handler = (
	"1"    => [ "Authen::Passphrase::MD5Crypt", 0.003 ],
	"2"    => [ "Authen::Passphrase::BlowfishCrypt", 0.007 ],
	"2a"   => [ "Authen::Passphrase::BlowfishCrypt", 0.007 ],
	"3"    => [ "Authen::Passphrase::NTHash", 0.003 ],
	"IPB2" => sub($) { croak '$IPB2$ is unimplemented' },
	"K4"   => sub($) { croak '$K4$ is unimplemented' },
	"LM"   => [ "Authen::Passphrase::LANManagerHalf", 0.003 ],
	"NT"   => [ "Authen::Passphrase::NTHash", 0.003 ],
	"P"    => [ "Authen::Passphrase::PHPass", 0.003 ],
	"VMS1" => [ "Authen::Passphrase::VMSPurdy", 0.006 ],
	"VMS2" => [ "Authen::Passphrase::VMSPurdy", 0.006 ],
	"VMS3" => [ "Authen::Passphrase::VMSPurdy", 0.006 ],
	"af"   => sub($) { croak '$af$ is unimplemented' },
	"apr1" => sub($) { croak '$apr1$ is unimplemented' },
	"krb5" => sub($) { croak '$krb5$ is unimplemented' },
);

sub from_crypt {
	my($class, $passwd) = @_;
	croak "crypt string \"$passwd\" not supported for $class"
		unless $class eq __PACKAGE__;
	my $handler;
	if($passwd =~ /\A\$([0-9A-Za-z]+)\$/) {
		my $scheme = $1;
		$handler = $crypt_scheme_handler{$scheme};
		croak "unrecognised crypt scheme \$$scheme\$"
			unless defined $handler;
	} elsif($passwd =~ m#\A(?:[^\$].{12}|_.{19})\z#s) {
		$handler = [ "Authen::Passphrase::DESCrypt", 0.006 ];
	} elsif($passwd eq "") {
		$handler = [ "Authen::Passphrase::AcceptAll", 0.003 ];
	} elsif($passwd =~ /\A[^\$].{0,11}\z/s) {
		$handler = [ "Authen::Passphrase::RejectAll", 0.003 ];
	} else {
		croak "bad crypt syntax in \"$passwd\"";
	}
	if(ref($handler) eq "CODE") {
		return $handler->($passwd);
	} else {
		my($modname, $modver) = @$handler;
		return use_module($modname, $modver)->from_crypt($passwd);
	}
}

=item Authen::Passphrase->from_rfc2307(USERPASSWORD)

Returns a passphrase recogniser object matching the supplied RFC 2307
encoding.  This constructor may only be called on the base class, not
any subclass.

The specific passphrase recogniser class is loaded at runtime.  See the
note about this for the L</from_crypt> constructor above.

Known scheme identifiers:

=over

=item B<{CLEARTEXT}>

Passphrase stored in cleartext.  See L<Authen::Passphrase::Clear>.

=item B<{CRYPT}>

The scheme identifier is followed by a crypt string.

=item B<{CRYPT16}>

Used ambiguously by Exim, to refer to either crypt16
(see L<Authen::Passphrase::Crypt16>) or bigcrypt (see
L<Authen::Passphrase::BigCrypt>) depending on compilation options.
This is a bug, resulting from a confusion between the two algorithms.
This module does not support any meaning for this scheme identifier.

=item B<{K5KEY}>

Not a real passphrase scheme, but a placeholder to indicate that a
Kerberos key stored separately should be checked against.  No data
follows the scheme identifier.

=item B<{KERBEROS}>

Not a real passphrase scheme, but a placeholder to indicate that
Kerberos should be invoked to check against a user's passphrase.
The scheme identifier is followed by the user's username, in the form
"I<name>B<@>I<realm>".

=item B<{LANM}>

Synonym for B<{LANMAN}>, used by CommuniGate Pro.

=item B<{LANMAN}>

The Microsoft LAN Manager hash scheme.  See
L<Authen::Passphrase::LANManager>.

=item B<{MD4}>

The MD4 digest of the passphrase is stored.  See
L<Authen::Passphrase::SaltedDigest>.

=item B<{MD5}>

The MD5 digest of the passphrase is stored.  See
L<Authen::Passphrase::SaltedDigest>.

=item B<{MSNT}>

The NT-Hash scheme, which stores the MD4 hash of the passphrase expressed
in Unicode.  See L<Authen::Passphrase::NTHash>.

=item B<{NS-MTA-MD5}>

An MD5-based scheme used by Netscape Mail Server.  See
L<Authen::Passphrase::NetscapeMail>.

=item B<{RMD160}>

The RIPEMD-160 digest of the passphrase is stored.  See
L<Authen::Passphrase::SaltedDigest>.

=item B<{SASL}>

Not a real passphrase scheme, but a placeholder to indicate that SASL
should be invoked to check against a user's passphrase.  The scheme
identifier is followed by the user's username.

=item B<{SHA}>

The SHA-1 digest of the passphrase is stored.  See
L<Authen::Passphrase::SaltedDigest>.

=item B<{SMD5}>

The MD5 digest of the passphrase plus a salt is stored.  See
L<Authen::Passphrase::SaltedDigest>.

=item B<{SSHA}>

The SHA-1 digest of the passphrase plus a salt is stored.
See L<Authen::Passphrase::SaltedDigest>.

=item B<{UNIX}>

Not a real passphrase scheme, but a placeholder to indicate that Unix
mechanisms should be used to check against a Unix user's login passphrase.
The scheme identifier is followed by the user's username.

=item B<{WM-CRY}>

Synonym for B<{CRYPT}>, used by CommuniGate Pro.

=back

=cut

my %rfc2307_scheme_handler = (
	"CLEARTEXT"  => [ "Authen::Passphrase::Clear", 0.003 ],
	# "CRYPT" is handled specially
	"CRYPT16"    => sub($) { croak "{CRYPT16} is ambiguous" },
	"K5KEY"      => sub($) { croak "{K5KEY} is a placeholder" },
	"KERBEROS"   => sub($) { croak "{KERBEROS} is a placeholder" },
	"LANM"       => [ "Authen::Passphrase::LANManager", 0.003 ],
	"LANMAN"     => [ "Authen::Passphrase::LANManager", 0.003 ],
	"MD4"        => [ "Authen::Passphrase::SaltedDigest", 0.008 ],
	"MD5"        => [ "Authen::Passphrase::SaltedDigest", 0.008 ],
	"MSNT"       => [ "Authen::Passphrase::NTHash", 0.003 ],
	"NS-MTA-MD5" => [ "Authen::Passphrase::NetscapeMail", 0.003 ],
	"RMD160"     => [ "Authen::Passphrase::SaltedDigest", 0.008 ],
	"SASL"       => sub($) { croak "{SASL} is a placeholder" },
	"SHA"        => [ "Authen::Passphrase::SaltedDigest", 0.008 ],
	"SMD5"       => [ "Authen::Passphrase::SaltedDigest", 0.008 ],
	"SSHA"       => [ "Authen::Passphrase::SaltedDigest", 0.008 ],
	"UNIX"       => sub($) { croak "{UNIX} is a placeholder" },
	# "WM-CRY" is handled specially
);

sub from_rfc2307 {
	my($class, $userpassword) = @_;
	if($userpassword =~ m#\A\{(?i:crypt|wm-cry)\}(.*)\z#s) {
		my $passwd = $1;
		return $class->from_crypt($passwd);
	}
	croak "RFC 2307 string \"$userpassword\" not supported for $class"
		unless $class eq __PACKAGE__;
	$userpassword =~ /\A\{([-0-9a-z]+)\}/i
		or croak "bad RFC 2307 syntax in \"$userpassword\"";
	my $scheme = uc($1);
	my $handler = $rfc2307_scheme_handler{$scheme};
	croak "unrecognised RFC 2307 scheme {$scheme}" unless defined $handler;
	if(ref($handler) eq "CODE") {
		return $handler->($userpassword);
	} else {
		my($modname, $modver) = @$handler;
		return use_module($modname, $modver)
			->from_rfc2307($userpassword);
	}
}

=back

=head1 METHODS

=over

=item $ppr->match(PASSPHRASE)

Checks whether the supplied passphrase is correct.  Returns a truth value.

=item $ppr->passphrase

If a matching passphrase can be easily determined by the passphrase
recogniser then this method will return it.  This is only feasible for
very weak passphrase schemes.  The method C<die>s if it is infeasible.

=item $ppr->as_crypt

Encodes the passphrase recogniser in crypt format and returns the encoded
result.  C<die>s if the passphrase recogniser cannot be represented in
this form.

=item $ppr->as_rfc2307

Encodes the passphrase recogniser in RFC 2307 format and returns
the encoded result.  C<die>s if the passphrase recogniser cannot be
represented in this form.

=cut

sub as_rfc2307 { "{CRYPT}".$_[0]->as_crypt }

=back

=head1 SUBCLASSING

This class is designed to be subclassed, and cannot be instantiated alone.
Any subclass must implement the L</match> method.  That is the minimum
required.

Subclasses should implement the L</as_crypt> and L</as_rfc2307> methods
and the L</from_crypt> and L</from_rfc2307> constructors wherever
appropriate, with the following exception.  If a passphrase scheme has
a crypt encoding but no native RFC 2307 encoding, so it can be RFC 2307
encoded only by using the "B<{CRYPT}>" scheme, then L</as_rfc2307> and
L</from_rfc2307> should I<not> be implemented by the class.  There is a
default implementation of the L</as_rfc2307> method that uses "B<{CRYPT}>"
and L</as_crypt>, and a default implementation of the L</from_rfc2307>
method that recognises "B<{CRYPT}>" and passes the embedded crypt string
to the L</from_crypt> constructor.

Implementation of the L</passphrase> method is entirely optional.
It should be attempted only for schemes that are so ludicrously weak as
to allow passphrases to be cracked reliably in a short time.  Dictionary
attacks are not appropriate implementations.

=head1 SEE ALSO

L<MooseX::Types::Authen::Passphrase>,
L<crypt(3)>,
RFC 2307

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
