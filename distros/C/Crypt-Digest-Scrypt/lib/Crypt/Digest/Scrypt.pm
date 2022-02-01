package Crypt::Digest::Scrypt;
use strict;
use warnings;

our $VERSION = '0.02';

use Exporter qw(import);
our @EXPORT_OK = qw(scrypt_1024_1_1_256);

require XSLoader;
XSLoader::load('Crypt::Digest::Scrypt', $VERSION);

1;
__END__

=head1 NAME

Crypt::Digest::Scrypt - Scrypt key derivation function

=head1 SYNOPSIS

  use Crypt::Digest::Scrypt qw(scrypt_1024_1_1_256);

  # calculate digest from string/buffer
  $scrypt_raw = scrypt_1024_1_1_256('data string');

=head1 DESCRIPTION

  Provides an interface to the Scrypt digest algorithm compatible with Litecoin.

=head1 FUNCTIONS

=over

=item B<scrypt_1024_1_1_256>

=back

=cut
