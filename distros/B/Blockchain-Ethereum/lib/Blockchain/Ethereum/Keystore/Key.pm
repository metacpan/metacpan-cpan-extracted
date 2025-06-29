package Blockchain::Ethereum::Keystore::Key;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum key abstraction
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use Carp;
use Crypt::PK::ECC;
use Crypt::Perl::ECDSA::Parse;
use Crypt::Perl::ECDSA::Utils;
use Crypt::Digest::Keccak256 qw(keccak256);
use Crypt::PRNG              qw(random_bytes);

use Blockchain::Ethereum::Keystore::Key::PKUtil;
use Blockchain::Ethereum::Keystore::Address;

sub new {
    my ($class, %params) = @_;
    my $self = bless {}, $class;

    if (exists $params{private_key}) {
        $self->{private_key} = $params{private_key};
    } else {
        $self->{private_key} = random_bytes(32);
    }

    my $importer = Crypt::PK::ECC->new();
    $importer->import_key_raw($self->private_key, 'secp256k1');

    # Crypt::PK::ECC does not provide support for deterministic keys
    $self->{ecc_handler} = bless Crypt::Perl::ECDSA::Parse::private($importer->export_key_der('private')),
        'Blockchain::Ethereum::Keystore::Key::PKUtil';

    return $self;
}

sub private_key {
    return shift->{private_key};
}

sub _ecc_handler {
    return shift->{ecc_handler};
}

sub sign_transaction {
    my ($self, $transaction) = @_;

    croak "transaction must be a reference of Blockchain::Ethereum::Transaction"
        unless ref($transaction) =~ /^\QBlockchain::Ethereum::Transaction/;

    # _sign is overriden by Blockchain::ethereum::Keystore::Key::PKUtil
    # to include the y_parity as part of the response
    my ($r, $s, $y_parity) = $self->_ecc_handler->_sign($transaction->hash);

    $transaction->set_r($r->as_hex);
    $transaction->set_s($s->as_hex);
    $transaction->generate_v($y_parity);

    return $transaction;
}

sub address {
    my $self = shift;

    my ($x, $y) = Crypt::Perl::ECDSA::Utils::split_G_or_public($self->_ecc_handler->_decompress_public_point);

    # address is the hash of the concatenated value of x and y
    my $address     = substr(keccak256($x . $y), -20);
    my $hex_address = unpack("H*", $address);

    return Blockchain::Ethereum::Keystore::Address->new(address => "0x$hex_address");
}

sub export {
    return shift->private_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Keystore::Key - Ethereum key abstraction

=head1 VERSION

version 0.019

=head1 SYNOPSIS

Generate a new key:

    my $key = Blockchain::Ethereum::Key->new;
    $key->sign_transaction($transaction); # Blockchain::Ethereum::Transaction

Import existent key:

    my $key = Blockchain::Ethereum::Key->new(private_key => $private_key); # private key bytes
    $key->sign_transaction($transaction); # Blockchain::Ethereum::Transaction

=head1 OVERVIEW

This is a private key abstraction

If instantiated without a private key, this module uses L<Crypt::PRNG> for the random key generation

=head1 METHODS

=head2 export

Export the private key bytes (the auto generated if no private key given)

=over 4

=back

Private key bytes

=head2 sign_transaction

Sign a L<Blockchain::Ethereum::Transaction> object

=over 4

=item * C<$transaction> - L<Blockchain::Ethereum::Transaction> subclass

=back

self

=head2 address

Export the L<Blockchain::Ethereum::Keystore::Address> from the imported/generated private key

=over 4

=back

L<Blockchain::Ethereum::Keystore::Address>

=head2 export

Use `private_key` instead this method is deprecated and will be removed.

=over 4

=back

Private key bytes

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
