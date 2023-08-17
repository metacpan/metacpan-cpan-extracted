use v5.26;
use Object::Pad;

package Blockchain::Ethereum::Keystore::Key 0.002;
class Blockchain::Ethereum::Keystore::Key;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::Keystore::Key - Private key abstraction

=head1 SYNOPSIS

Private key abstraction

If instantiated without a private key it generate a new random key, this module uses L<Crypt::PRNG> for the random key generation

    my $Blockchain::Ethereum::Keystore::Key->new(private_key => $private_key_bytes);

=cut

use Carp;
use Crypt::PK::ECC;
use Crypt::Perl::ECDSA::Parse;
use Crypt::Perl::ECDSA::Utils;
use Digest::Keccak qw(keccak_256);
use Crypt::PRNG    qw(random_bytes);

use Blockchain::Ethereum::Keystore::Key::PrivateKey;
use Blockchain::Ethereum::Keystore::Address;

field $private_key :reader :writer :param //= undef;
field $_ecc_handler :reader(_ecc_handler) :writer(set_ecc_handler);

ADJUST {
    # if the private key is not set, generate a new one
    $self->set_private_key(random_bytes(32)) unless defined $self->private_key;

    my $importer = Crypt::PK::ECC->new();
    $importer->import_key_raw($self->private_key, 'secp256k1');

    # Crypt::PK::ECC does not provide support for deterministic keys
    $self->set_ecc_handler(bless Crypt::Perl::ECDSA::Parse::private($importer->export_key_der('private')),
        'Blockchain::Ethereum::Keystore::Key::PrivateKey');
}

=head2 sign_transaction

Sign a L<Blockchain::Ethereum::Transaction> object

Usage:

    sign_transaction($transaction) -> $$transaction

=over 4

=item * C<$transaction> - L<Blockchain::Ethereum::Transaction> subclass

=back

self

=cut

method sign_transaction ($transaction) {

    require Blockchain::Ethereum::Transaction;

    croak "transaction must be a reference from Blockchain::Ethereum::Transaction"
        unless ref($transaction) =~ /^\QBlockchain::Ethereum::Transaction/;

    # _sign is overriden by Blockchain::ethereum::Keystore::Key::PrivateKey
    # to include the y_parity as part of the response
    my ($r, $s, $y_parity) = $self->_ecc_handler->_sign($transaction->hash);

    $transaction->set_r($r->as_hex);
    $transaction->set_s($s->as_hex);
    $transaction->generate_v($y_parity);

    return $transaction;
}

=head2 address

Export the L<Blockchain::Ethereum::Keystore::Address> from the imported/generated private key

Usage:

    address() -> L<Blockchain::Ethereum::Keystore::Address>

=over 4

=back

L<Blockchain::Ethereum::Keystore::Address>

=cut

method address {

    my ($x, $y) = Crypt::Perl::ECDSA::Utils::split_G_or_public($self->_ecc_handler->_decompress_public_point);

    # address is the hash of the concatenated value of x and y
    my $address     = substr(keccak_256($x . $y), -20);
    my $hex_address = unpack("H*", $address);

    return Blockchain::Ethereum::Keystore::Address->new(address => "0x$hex_address");
}

=head2 export

Export the private key bytes

Usage:

    export() -> private key bytes

=over 4

=back

Private key bytes

=cut

method export {

    return $self->private_key;
}

1;

__END__

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ethereum-keystore>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
