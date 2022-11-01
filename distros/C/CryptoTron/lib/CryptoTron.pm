package CryptoTron;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw();

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.10';

1;

__END__

=head1 NAME

CryptoTron - Perl extension for use with the crypto coin Tron blockchain

=head1 SYNOPSIS

  use CryptoTron::SignTx
  use CryptoTron::ClaimReward
  use CryptoTron::AddressConvert
  use CryptoTron::AddressCheck
  use CryptoTron::AddrTools
  use CryptoTron::CreateAccount

=head1 DESCRIPTION

The module provides methods to query the blockchain of the crypto coin Tron. 

=head1 SEE ALSO

CryptoTron modules:

  CryptoTron::SignTx
  CryptoTron::AddrTools
  CryptoTron::AddressConvert
  CryptoTron::AddressCheck
  CryptoTron::ClaimReward
  CryptoTron::CreateAccount

CPAN modules:

  URI
  LWP::UserAgent
  JSON::PP
  Try::Catch
  Inline::Python
  Bitcoin::Crypto::Base58

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
