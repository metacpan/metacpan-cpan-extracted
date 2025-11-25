package Blockchain::Ethereum::Key;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum key abstraction
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.021';          # VERSION

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256);
use Crypt::PRNG              qw(random_bytes);
use Scalar::Util             qw(blessed);
use Bitcoin::Secp256k1;

use Blockchain::Ethereum::Address;

sub new {
    my ($class, %params) = @_;
    my $self = bless {}, $class;

    if (exists $params{private_key}) {
        $self->{private_key} = $params{private_key};
    } else {
        $self->{private_key} = random_bytes(32);
    }

    return $self;
}

sub private_key {
    return shift->{private_key};
}

sub _ecc_handler {
    return shift->{ecc_handler} //= Bitcoin::Secp256k1->new;
}

sub sign_transaction {
    my ($self, $transaction) = @_;

    croak "transaction must be a reference of Blockchain::Ethereum::Transaction"
        unless blessed $transaction && $transaction->isa('Blockchain::Ethereum::Transaction');

    my $result = $self->_ecc_handler->sign_digest_recoverable($self->private_key, $transaction->hash);

    my $r           = substr($result->{signature}, 0,  32);
    my $s           = substr($result->{signature}, 32, 32);
    my $recovery_id = $result->{recovery_id};

    $transaction->set_r(unpack "H*", $r);
    $transaction->set_s(unpack "H*", $s);
    $transaction->generate_v($recovery_id);

    return $transaction;
}

sub address {
    my $self = shift;

    my $pubkey            = $self->_ecc_handler->create_public_key($self->private_key);
    my $compressed_pubkey = $self->_ecc_handler->compress_public_key($pubkey, 0);
    my $pubkey_64         = substr($compressed_pubkey,     1);    # remove 0x04 prefix
    my $address           = substr(keccak256($pubkey_64), -20);
    my $hex_address       = unpack("H*", $address);

    return Blockchain::Ethereum::Address->new(address => "0x$hex_address");
}

sub export {
    return shift->private_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Key - Ethereum key abstraction

=head1 VERSION

version 0.021

=head1 SYNOPSIS

Generate a new key:

    my $key = Blockchain::Ethereum::Key->new;
    my $address = $key->address; # Blockchain::Ethereum::Address
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

Export the L<Blockchain::Ethereum::Address> from the imported/generated private key

=over 4

=back

L<Blockchain::Ethereum::Address>

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
