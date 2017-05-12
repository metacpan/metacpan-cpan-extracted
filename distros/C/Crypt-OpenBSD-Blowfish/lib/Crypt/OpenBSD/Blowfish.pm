package Crypt::OpenBSD::Blowfish;

use strict;
use warnings;
use Carp qw( croak );

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::OpenBSD::Blowfish ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Crypt::OpenBSD::Blowfish', $VERSION);

# Preloaded methods go here.

sub blocksize { 8 }
sub keysize { 0 }
sub minkeysize { 4 }
sub maxkeysize { 56 }

sub new {
	my $class = shift;
	my $key = shift;
        if ($key) {
		croak "Key must be at least " . $class->minkeysize . " octets"
			if length($key) < $class->minkeysize;
		$key = substr($key,0,$class->keymaxsize)
			if length($key) > $class->maxkeysize;
	}
	$key ? Crypt::OpenBSD::Blowfish::init_key($key) :
		Crypt::OpenBSD::Blowfish::init();
}

1;
__END__

=head1 NAME

Crypt::OpenBSD::Blowfish - Perl extension for the OpenBSD Blowfish cipher
implementation.

=head1 SYNOPSIS

  use Crypt::OpenBSD::Blowfish;
  my $bf = Crypt::OpenBSD::Blowfish->new($key);
  my $encrypted = $bf->encrypt$data);
  ...
  my $decrypted = $bf->decrypt($encrypted);

or to create key material:

  use Crypt::OpenBSD::Blowfish;
  my $bf = Crypt::OpenBSD::Blowfish->new();
  $bf->expandstate($salt,$pass);
  foreach (1..64) {
     $bf->expand0state($salt);
     $bf->expand0state($pass);
  }
  $key_material = $bf->encrypt_iterate($data,64);


=head1 DESCRIPTION

This module is a wrapper for the OpenBSD implementation of the Blowfish
cipher.  The C source is taken from the portable OpenSSH source code.

=head1 CLASS METHODS

=head2 Crypt::OpenBSD::Blowfish->blocksize

Returns 8, as the Blowfish block size is eight octets.

=head2 Crypt::OpenBSD::Blowfish->keysize

Returns 0, as the Blowfish key size is variable.

=head1 CONSTRUCTOR

=head2 $bf = Crypt::OpenBSD::Blowfish->new()

=head2 $bf = Crypt::OpenBSD::Blowfish->new($key)

Returns a Crypt::OpenBSD::Blowfish object.  Passing a key will transform
the S-boxes and subkeys with the key.

=head1 METHODS

=head2 $cipher->blocksize

Returns 8.  Blowfish uses an eight-octet block size.  May be called via
either a class method or object method.

=head2 $encrypted = $cipher->encrypt($data)

Encrypt $data, which must be in 8-byte chunks.

=head2 $decrypted = $cipher->decrypt($data)

Decrypt $data, which must be in 8-byte chunks.

=head2 $cipher->expandstate($data,$key)

Expand the subkeys using data (salt) and a key.

=head2 $cipher->expand0state($key)

Expand the subkeys using key.

=head2 $encrypted = $bf->encrypt_iterate($data,$rounds)

Iteratively encrypt $data for $rounds rounds.  Useful
for creating key material for a password function.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Git Hub home:
https://github.com/lkinley/Crypt-OpenBSD-Blowfish/

=head1 AUTHOR

Lance Kinley, E<lt>lkinley@loyaltymethods.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Lance Kinley/Loyalty Methods, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
