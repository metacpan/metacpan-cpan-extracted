=head1 NAME

Crypt::Eksblowfish::Bcrypt - Blowfish-based Unix crypt() password hash

=head1 SYNOPSIS

	use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash);

	$hash = bcrypt_hash({
			key_nul => 1,
			cost => 8,
			salt => $salt,
		}, $password);

	use Crypt::Eksblowfish::Bcrypt qw(en_base64 de_base64);

	$text = en_base64($octets);
	$octets = de_base64($text);

	use Crypt::Eksblowfish::Bcrypt qw(bcrypt);

	$hashed_password = bcrypt($password, $settings);

=head1 DESCRIPTION

This module implements the Blowfish-based Unix crypt() password hashing
algorithm, known as "bcrypt".  This hash uses a variant of Blowfish,
known as "Eksblowfish", modified to have particularly expensive key
scheduling.  Eksblowfish and bcrypt were devised by Niels Provos and
David Mazieres for OpenBSD.  The design is described in a paper at
L<http://www.usenix.org/events/usenix99/provos.html>.

=cut

package Crypt::Eksblowfish::Bcrypt;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Crypt::Eksblowfish 0.005;
use MIME::Base64 2.21 qw(encode_base64 decode_base64);

our $VERSION = "0.009";

use parent "Exporter";
our @EXPORT_OK = qw(bcrypt_hash en_base64 de_base64 bcrypt);

=head1 FUNCTIONS

=over

=item bcrypt_hash(SETTINGS, PASSWORD)

Hashes PASSWORD according to the supplied SETTINGS, and returns the
23-octet hash.  SETTINGS must be a reference to a hash, with these keys:

=over

=item B<key_nul>

Truth value: whether to append a NUL to the password before using it as a key.
The algorithm as originally devised does not do this, but it was later
modified to do it.  The version that does append NUL is to be preferred;
not doing so is supported only for backward compatibility.

=item B<cost>

Non-negative integer controlling the cost of the hash function.
The number of operations is proportional to 2^cost.

=item B<salt>

Exactly sixteen octets of salt.

=back

=cut

sub bcrypt_hash($$) {
	my($settings, $password) = @_;
	$password .= "\0" if $settings->{key_nul} || $password eq "";
	my $cipher = Crypt::Eksblowfish->new($settings->{cost},
			$settings->{salt}, substr($password, 0, 72));
	my $hash = join("", map {
				my $blk = $_;
				for(my $i = 64; $i--; ) {
					$blk = $cipher->encrypt($blk);
				}
				$blk;
			    } qw(OrpheanB eholderS cryDoubt));
	chop $hash;
	return $hash;
}

=item en_base64(BYTES)

Encodes the octet string textually using the form of base 64 that is
conventionally used with bcrypt.

=cut

sub en_base64($) {
	my($octets) = @_;
	my $text = encode_base64($octets, "");
	$text =~ tr#A-Za-z0-9+/=#./A-Za-z0-9#d;
	return $text;
}

=item de_base64(TEXT)

Decodes an octet string that was textually encoded using the form of
base 64 that is conventionally used with bcrypt.

=cut

sub de_base64($) {
	my($text) = @_;
	croak "bad base64 encoding"
		unless $text =~ m#\A(?>(?:[./A-Za-z0-9]{4})*)
				  (?:|[./A-Za-z0-9]{2}[.CGKOSWaeimquy26]|
				      [./A-Za-z0-9][.Oeu])\z#x;
	$text =~ tr#./A-Za-z0-9#A-Za-z0-9+/#;
	$text .= "=" x (3 - (length($text) + 3) % 4);
	return decode_base64($text);
}

=item bcrypt(PASSWORD, SETTINGS)

This is a version of C<crypt> (see L<perlfunc/crypt>) that implements the
bcrypt algorithm.  It does not implement any other hashing algorithms,
so if others are desired then it necessary to examine the algorithm
prefix in SETTINGS and dispatch between more than one version of C<crypt>.

SETTINGS must be a string which encodes the algorithm parameters,
including salt.  It must begin with "$2", optional "a", "$", two
digits, "$", and 22 base 64 digits.  The rest of the string is ignored.
The presence of the optional "a" means that a NUL is to be appended
to the password before it is used as a key.  The two digits set the
cost parameter.  The 22 base 64 digits encode the salt.  The function
will C<die> if SETTINGS does not have this format.

The PASSWORD is hashed according to the SETTINGS.  The value returned
is a string which encodes the algorithm parameters and the hash: the
parameters are in the same format required in SETTINGS, and the hash is
appended in the form of 31 base 64 digits.  This result is suitable to
be used as a SETTINGS string for input to this function: the hash part
of the string is ignored on input.

=cut

sub bcrypt($$) {
	my($password, $settings) = @_;
	croak "bad bcrypt settings"
		unless $settings =~ m#\A\$2(a?)\$([0-9]{2})\$
					([./A-Za-z0-9]{22})#x;
	my($key_nul, $cost, $salt_base64) = ($1, $2, $3);
	my $hash = bcrypt_hash({
			key_nul => $key_nul,
			cost => $cost,
			salt => de_base64($salt_base64),
		   }, $password);
	return "\$2${key_nul}\$${cost}\$${salt_base64}".en_base64($hash);
}

=back

=head1 SEE ALSO

L<Crypt::Eksblowfish>,
L<http://www.usenix.org/events/usenix99/provos.html>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
