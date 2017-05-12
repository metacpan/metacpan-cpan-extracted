package Crypt::OpenSSH::ChachaPoly;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::OpenSSH::ChachaPoly ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Crypt::OpenSSH::ChachaPoly', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Crypt::OpenSSH::ChachaPoly - Wrapper for OpenSSH Chacha20 and Poly1305 crypto
functions

=head1 SYNOPSIS

  use Crypt::OpenSSH::ChachaPoly;
  my $c = Crypt::OpenSSH::ChachaPoly->new($key);
  # set up IV with 8 byte IV and little endian 8 byte counter
  $c->ivsetup($iv,$counter);
  my $enc = $c->encrypt($plaintext);
  # poly_key needs to be 32 bytes long
  # in openssh, poly key is derived from encrypting a 32 byte zero value
  # with chacha20 using the packet sequence number as IV and a NULL (undef) counter.
  my $tag = $c->poly1305($enc,$poly_key)

=head1 DESCRIPTION

This module provides and interface to the OpenSSH Chacha20 and Poly1305 functions.
It may not be very useful for anything other than its intended purpose of adding
Chacha20-Poly1305 functionality to Net::SSH::Perl.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Git Hub home for this module:
https://github.com/lkinley/Crypt-OpenSSH-ChachaPoly

=head1 AUTHOR

Lance Kinley, E<lkinley@loyaltymethods.comE>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Lance Kinley/Loyalty Methods, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
