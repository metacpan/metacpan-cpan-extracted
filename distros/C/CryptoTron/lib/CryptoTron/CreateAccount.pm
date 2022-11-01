package CryptoTron::CreateAccount;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw(CreateAccount
                 CreateMnemonic
);

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.02';

# Use Inline Python module to define a function.
use Inline Python => <<'END_OF_PYTHON_CODE';

# Import the third party Python module.
import base58
from bip_utils import Bip39WordsNum, Bip39MnemonicGenerator, Bip39SeedGenerator
from bip_utils import Bip44Coins, Bip44

# User defined function create_account()
def create_account():
    # Set the format string.
    fmt_str = "{0:18s}{1}"
    # Print message to screen.
    print("*** Create a new 12 word mnemonic using Bip39 and Bip44\n")
    # Generate a random mnemonic string of 12 words with default language (English)
    mnemonic = Bip39MnemonicGenerator().FromWordsNumber(Bip39WordsNum.WORDS_NUM_12)
    # Print the mnemonic to screen.
    print(fmt_str.format("Mnemonic:", mnemonic))
    # Print message to screen.
    print("\n*** Create private key, public key and Tron address using Bip39 and Bip44\n")
    # Generate seed with automatic language detection and empty passphrase.
    seed_bytes = Bip39SeedGenerator(mnemonic).Generate()
    # Create Bip44 Tron object.
    bip44_tron = Bip44.FromSeed(seed_bytes, Bip44Coins.TRON)
    # Create a private key in hex and upper case.
    private_key = bip44_tron.PrivateKey().Raw().ToHex().upper()
    # Create a public key in upper case.
    public_key = str(bip44_tron.PublicKey().RawUncompressed()).upper()
    # Create Base58 address.
    base58_addr = bip44_tron.PublicKey().ToAddress()
    # Create a Hex address in hex and upper case.
    hex_addr = base58.b58decode_check(base58_addr).hex().upper()
    # Print result to screen.
    print(fmt_str.format("Private Key:", private_key))
    print(fmt_str.format("Address (Base58):", base58_addr))
    print(fmt_str.format("Address (Hex): ", hex_addr))
    print(fmt_str.format("Public Key: ", public_key))

def mnemonic():
    # Generate a random mnemonic string of 12 words with default language (English)
    mnemonic = Bip39MnemonicGenerator().FromWordsNumber(Bip39WordsNum.WORDS_NUM_12)
    # Return 12 word mnemonic list.
    return mnemonic

END_OF_PYTHON_CODE

# --------------------------
# Subroutine CreateAccount()
# --------------------------
sub CreateAccount {
    # Call function create_account.
    create_account();
};

# ---------------------------
# Subroutine CreateMnemonic()
# ---------------------------
sub CreateMnemonic {
   # Return 12 word mnemonic.
   return mnemonic();
};

# Create 12 words mnemonic with Perl.
# use Bitcoin::BIP39 qw(gen_bip39_mnemonic);
# Create a hash reference.
# my $hash = gen_bip39_mnemonic();
# Access value by key.
# my $mnemonic = $hash->{'mnemonic'};
# print $mnemonic . "\n";

1;

__END__

=head1 NAME

CryptoTron::CreateAccount - Perl extension for use with crypto coin Tron blockchain

=head1 SYNOPSIS

  use CryptoTron::CreateAccount;

  # Create a new Tron account including mnemonics.
  CreateAccount();

=head1 DESCRIPTION

The module creates a new Tron account. The procedure starts with the creation
of a 12 word mnemonic. From seed from 12 word mnemonic private key as well as 
public key are generated. The the Base58 and Hex Tron address is determined. 

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
