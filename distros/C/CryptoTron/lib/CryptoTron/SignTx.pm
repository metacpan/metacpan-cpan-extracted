package CryptoTron::SignTx;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw(
    sign
);

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.02';

# Use Inline Python module to define a function.
use Inline Python => <<'END_OF_PYTHON_CODE';

# Import the Python modules.
import sys
from eth_account import Account

# Define the Python function sign().
def sign_txID(txID, privKey):
    txID = txID.decode()
    privKey = privKey.decode()
    sign_tx = Account.signHash(txID, privKey)
    sign_eth = sign_tx['signature']
    sign_hex = sign_eth.hex()[2:]
    return sign_hex

END_OF_PYTHON_CODE

sub sign {
    my ($txID, $privKey) = @_;
    my $signature = sign_txID($txID, $privKey);
    return $signature;
}; 

1;

__END__

=head1 NAME

CryptoTron::SignTransaction - Perl extension for use with crypto coin Tron blockchain

=head1 SYNOPSIS

  use CryptoTron::SignTx;

  # Set the transaction ID.
  my $txID = "2e5c65e8eda302cd991740ced24521aec624d3a4e24ed2e192d0606e0f1a8bcd";

  # Set the private key.
  my $privKey = "9439BDAA137488AEFA9244A6AE894B033CDFE333E1AEC6D0F4A9358FAABD128F";

  # Print the signature for private key and transaction ID.
  my $signature = sign($txID, $privKey);
  print $signature . "\n";

=head1 DESCRIPTION

The package signs a Tron transaction. The private key must be known from the
Tron account. The transaction ID is given from a transaction builder. The
package gives back the signature, which is used for broadcasting the transaction.  

=head1 SEE ALSO

Inline::Python

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
