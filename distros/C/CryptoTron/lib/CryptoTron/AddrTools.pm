package CryptoTron::AddrTools;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use Exporter;

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.06';

# Exporting the implemented subroutines.
our @EXPORT = qw(
    to_hex_addr
    to_base58_addr
    chk_hex_addr
    chk_base58_addr
);

# Load the required Perl modules.
use Try::Catch;
use Bitcoin::Crypto::Base58 qw(
        encode_base58
        decode_base58
        encode_base58check
        decode_base58check
);

# ======================
# Subroutine to_hex_addr
# ======================
sub to_hex_addr {
    # Assign the function argument to the local variable.
    my $base58_addr = $_[0];
    # Initialise the variable $hex_addr.
    my $hex_addr = undef;
    # Convert the base58 address to the hex address.
    $hex_addr = decode_base58check($base58_addr);
    $hex_addr = unpack("H*", $hex_addr);    
    $hex_addr = uc($hex_addr);
    # Return the hex address.
    return $hex_addr;
};

# =========================
# Subroutine to_base58_addr
# =========================
sub to_base58_addr {
    # Assign the function argument to the local variable.
    my $hex_addr = $_[0];
    # Initialise the variable $base58_addr.
    my $base58_addr = undef;
    # Convert the hex address to the base58 address.
    $base58_addr = pack("H*", $hex_addr);
    $base58_addr = encode_base58check($base58_addr);
    # Return the base58 address.
    return $base58_addr;
};

# ==========================
# Subroutine chk_base58_addr
# ==========================
sub chk_base58_addr {
    # Assign the function argument to the local variable.
    my $base58_addr = $_[0];
    # Initialise the variable $is_base58_addr to 1 (true). 
    my $is_base58_addr = 1;
    # Get the first char of the base58 address.
    my $chr_addr = substr($base58_addr, 0, 1);
    # Get the length of the base58 address.
    my $len_addr = length($base58_addr);
    # Check if the first char is T and the length of the address is 34.
    if (("$chr_addr" eq "T") and ($len_addr == 34)) {
        # Try to convert the address from base58 to hex.
        try {
            # Initialise the variable $hex_addr.
            my $hex_addr = undef;
            # Convert the base58 address to the hex address.
            $hex_addr = decode_base58check($base58_addr);
            $hex_addr = unpack("H*", $hex_addr);
        } catch {
            # Set variable to 0 (false).
            $is_base58_addr = 0;
        };
    } else {
        # Set variable to 0 (false).
        $is_base58_addr = 0;
    };
    # Return true or false on result of check.
    return $is_base58_addr;
};

# =======================
# Subroutine chk_hex_addr
# =======================
sub chk_hex_addr {
    # Assign the function argument to the local variable.
    my $hex_addr = $_[0];
    # Initialise the variable $is_hex_addr to 1 (true). 
    my $is_hex_addr = 1;
    # Get the first two chars of the hex address.
    my $chrs_addr = substr($hex_addr, 0, 2);
    # Get the length of the hex address.
    my $len_addr = length($hex_addr);
    # Check if the first chars are 41 and the length of the address is 42.
    if (("$chrs_addr" eq "41") and ($len_addr == 42)) {
        # Try to convert the address from hex to base58.
        try {
            # Initialise the variable $base58_addr.
            my $base58_addr = undef;
            # Convert the hex address to the base58 address.
            $base58_addr = pack("H*", $hex_addr);
            $base58_addr = encode_base58check($base58_addr);
        } catch {
            # Set variable to 0 (false).
            $is_hex_addr = 0;
        };
    } else {
        # Set variable to 0 (false).
        $is_hex_addr = 0;
    };
    # Return true or false on result of check.
    return $is_hex_addr;
};

1;
__END__
=head1 NAME

CryptoTron::AddrTools - Perl extension for use with crypto coin Tron addresses

=head1 SYNOPSIS

  use CryptoTron::AddrTools;

  # Declare the public keys.
  my $PublicKeyBase58 = 'TQHgMpVzWkhSsRB4BzZgmV8uW4cFL8eaBr';
  my $PublicKeyHex = '419D1015E669C2DF831003C5C54CEB48DA613D9979';

  # Convert the public keys.
  my $HexAddr = to_hex_addr($PublicKeyBase58);
  print $HexAddr . "\n";
  my $Base58Addr = to_base58_addr($PublicKeyHex);
  print $Base58Addr . "\n";

  # Check the public keys.
  my $chkBase58Addr = chk_base58_addr($PublicKeyBase58);
  print $chkBase58Addr . "\n";
  my $chkHexAddr = chk_hex_addr($PublicKeyHex);
  print $chkHexAddr . "\n";

=head1 DESCRIPTION

The package is intended to simplify the work with addresses of the crypto coin
Tron. There are two types of Tron addresse usable, one in Base58 and one in Hex
represenation.

Method to_hex_addr() converts a Base58 address to a Hex address. 

Method to_base58_addr() converts a Hex address to a Base58 address.

The methods chk_base58_addr() and chk_hex_addr return 0 (false) or
1 (true), depending on valid Base58 or Hex addresses. 

=head1 SEE ALSO

Bitcoin::Crypto::Base58 

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
