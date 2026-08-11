#
# Copyright (C) 1995, 1996 Systemics Ltd (http://www.systemics.com/)
# All rights reserved.
#
# Modifications are Copyright (c) 2000, W3Works, LLC
# All Rights Reserved.

package Crypt::DES;

require Exporter;
require DynaLoader;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default
@EXPORT =	qw();

# Other items we are prepared to export if requested
@EXPORT_OK =	qw();

$VERSION = '2.09';
bootstrap Crypt::DES $VERSION;

use strict;
use Carp;

sub usage
{
	my ($package, $filename, $line, $subr) = caller(1);
	$Carp::CarpLevel = 2;
	croak "Usage: $subr(@_)";
}


sub blocksize { 8; }
sub keysize   { 8; }

sub new
{
	usage("new DES key") unless @_ == 2;

	my $type = shift;
	my $self = {};
	bless $self, $type;

	$self->{'ks'} = Crypt::DES::expand_key(shift);

	return $self;
}

sub encrypt
{
	usage("encrypt data[8 bytes]") unless @_ == 2;

	my ($self,$data) = @_;
	return Crypt::DES::crypt($data, $data, $self->{'ks'}, 1);
}

sub decrypt
{
	usage("decrypt data[8 bytes]") unless @_ == 2;

	my ($self,$data) = @_;
	return Crypt::DES::crypt($data, $data, $self->{'ks'}, 0);
}

1;

__END__

=head1 NAME

Crypt::DES - Perl DES encryption module

=head1 SYNOPSIS

	use Crypt::DES;
	my $key = pack("H16", "0123456789ABCDEF");
	my $cipher = Crypt::DES->new($key);
	my $ciphertext = $cipher->encrypt($plaintext);
	my $plaintext = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

The module implements the Crypt::CBC interface,
which has the following methods

=over 4

=item blocksize

=item keysize

=item encrypt

=item decrypt

=back

=head1 FUNCTIONS

=over 4

=item blocksize

Returns the size (in bytes) of the block cipher.

=item keysize

Returns the size (in bytes) of the key. Optimal size is 8 bytes.

=item new

	my $cipher = Crypt::DES->new($key);

This creates a new Crypt::DES BlockCipher object, using $key,
where $key is a key of C<keysize()> bytes.

=item encrypt

	my $cipher = Crypt::DES->new($key);
	my $ciphertext = $cipher->encrypt($plaintext);

This function encrypts $plaintext and returns the $ciphertext
where $plaintext and $ciphertext should be of C<blocksize()> bytes.

=item decrypt

	my $cipher = Crypt::DES->new($key);
	my $plaintext = $cipher->decrypt($ciphertext);

This function decrypts $ciphertext and returns the $plaintext
where $plaintext and $ciphertext should be of C<blocksize()> bytes.

=back

=head1 Security Considerations

This module is not deprecated as there may still be a reason to
encrypt and decrypt using DES. However, DES is known to be weak.
In 2026 a standard laptop can brute-force a DES key in a few
days. B<DO NOT use DES (or this module) with any expectation of
security>.

=head1 EXAMPLE

	my $key = pack("H16", "0123456789ABCDEF");
	my $cipher = Crypt::DES->new($key);
	my $ciphertext = $cipher->encrypt("plaintex");	# NB - 8 bytes
	print unpack("H16", $ciphertext), "\n";
	my $plaintext = $cipher->decrypt($ciphertext);
	print $plaintext, "\n";

=head1 NOTES

Do note that DES only uses 8 byte keys and only works on 8 byte data
blocks.  If you're intending to encrypt larger blocks or entire files, 
please use Crypt::CBC in conjunction with this module.  See the
Crypt::CBC documentation for proper syntax and use.

Also note that the DES algorithm is, by today's standard, weak 
encryption.  CryptX (Crypt::Cipher::AES) is recommended if you
want to replace Crypt::DES in a Crypt::CBC use case.  Otherwise,
replacing it with something like Crypt::AuthEnc::GCM would be
recommended.

=head1 SEE ALSO

Crypt::AuthEnc::GCM
Crypt::Blowfish
Crypt::IDEA

Bruce Schneier, I<Applied Cryptography>, 1995, Second Edition,
published by John Wiley & Sons, Inc.

=head1 COPYRIGHT

The implementation of the DES algorithm was developed by,
and is copyright of, Eric Young (eay@mincom.oz.au).
Other parts of the perl extension and module are
copyright of Systemics Ltd ( http://www.systemics.com/ ).
Cross-platform work and packaging for single algorithm 
distribution is copyright of W3Works, LLC.

=head1 MAINTAINER

This single-algorithm package and cross-platform code is 
maintained by Dave Paris <amused@pobox.com>.

Timothy Legge <timlegge@gmail.com> started maintaining
this module as of version 2.08.

=cut
