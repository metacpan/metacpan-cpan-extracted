use v5.26;
use Object::Pad;

package Blockchain::Ethereum::Keystore 0.005;
class Blockchain::Ethereum::Keystore;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Keystore - Ethereum keystorage utilities

=head1 SYNOPSIS

Collection of utilities for keystore management

Examples:

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
    $keyfile->change_password($password, "newpassword");
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

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ethereum-keystore>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
