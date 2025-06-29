package Blockchain::Ethereum::Keystore;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum wallet management utilities
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Keystore - Ethereum wallet management utilities

=head1 VERSION

version 0.019

=head1 SYNOPSIS

Generating a new address and writing it to a keyfile:

    my $key = Blockchain::Ethereum::Keystore::Key->new;
    # checksummed address
    print $key->address;
    my $keyfile = Blockchain::ethereum::Keystore::Keyfile->new;

    $keyfile->import_key($key);
    $keyfile->write_to_file("...");
    ...

Generating a new seed and derivating new keys (BIP44):

    my $seed = Blockchain::Ethereum::Keystore::Seed->new;
    my $key = $seed->derive_key(0);
    print $key->address;
    ...

Importing a keyfile and changing the password:

    my $keyfile = Blockchain::Ethereum::Keystore::Keyfile->new;
    my $password = "old_password";
    $keyfile->import_file("...", $password);
    $keyfile->change_password($password, "new_password");
    $keyfile->write_to_file("...");

Signing a transaction:

    my $transaction = Blockchain::Ethereum::Transaction::EIP1559->new(
        ...
    );

    my $keyfile = Blockchain::Ethereum::Keystore::Keyfile->new;
    $keyfile->import_file("...");
    $keyfile->private_key->sign_transaction($transaction);

Export private key:

    my $keyfile = Blockchain::Ethereum::Keystore::Keyfile->new;
    $keyfile->import_file("...");

    # private key bytes
    print $keyfile->private_key->export;

=head1 OVERVIEW

This module provides a collection of Ethereum wallet management utilities.

Core functionalities:

=over 4

=item * Manage Ethereum keyfiles, facilitating import, export, and password change.

=item * Sign L<Blockchain::Ethereum::Transaction> transactions.

=item * Private key and seed generation through L<Crypt::PRNG>

=item * Support for BIP44 for hierarchical deterministic wallets and key derivation.

=back

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
