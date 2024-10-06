use v5.26;

use strict;
use warnings;
no indirect;
use feature 'signatures';

use Object::Pad ':experimental(init_expr)';
# ABSTRACT: Ethereum transaction abstraction

package Blockchain::Ethereum::Transaction;
role Blockchain::Ethereum::Transaction;

our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.010';          # VERSION

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256);

use Blockchain::Ethereum::RLP;

field $chain_id :reader :writer :param;
field $nonce :reader :writer :param;
field $gas_limit :reader :writer :param;
field $to :reader :writer :param    //= '';
field $value :reader :writer :param //= '0x0';
field $data :reader :writer :param  //= '';
field $v :reader :writer :param = undef;
field $r :reader :writer :param = undef;
field $s :reader :writer :param = undef;

field $rlp :reader = Blockchain::Ethereum::RLP->new();

method serialize;

method generate_v;

method hash {

    return keccak256($self->serialize);
}

# In case of Math::BigInt given for any params, get the hex value
method _equalize_params ($params) {

    return [map { ref $_ eq 'Math::BigInt' ? $_->as_hex : $_ } $params->@*];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Transaction - Ethereum transaction abstraction

=head1 VERSION

version 0.010

=head1 SYNOPSIS

Ethereum transaction abstraction for signing and generating raw transactions

    # parameters can be hexadecimal strings or Math::BigInt instances
    my $transaction = Blockchain::Ethereum::Transaction::EIP1559->new(
        nonce                    => '0x0',
        max_fee_per_gas          => '0x9',
        max_priority_fee_per_gas => '0x0',
        gas_limit                => '0x1DE2B9',
        to                       => '0x3535353535353535353535353535353535353535'
        value                    => Math::BigInt->new('1000000000000000000'),
        data                     => '0x',
        chain_id                 => '0x539'
    );

    # github.com/refeco/perl-ethereum-keystore
    my $key = Blockchain::Ethereum::Keystore::Key->new(
        private_key => pack "H*",
        '4646464646464646464646464646464646464646464646464646464646464646'
    );

    $key->sign_transaction($transaction);

    my $raw_transaction = $transaction->serialize;

    print unpack("H*", $raw_transaction);

Standalone version:

    ethereum-raw-tx --tx-type=legacy --chain-id=0x1 --nonce=0x9 --gas-price=0x4A817C800 --gas-limit=0x5208 --to=0x3535353535353535353535353535353535353535 --value=0xDE0B6B3A7640000 --pk=0x4646464646464646464646464646464646464646464646464646464646464646

Supported transaction types:

=over 4

=item * B<Legacy>

=item * B<EIP1559 Fee Market>

=back

=head1 METHODS

=head2 serialize

To be implemented by the child classes, encodes the given transaction parameters to RLP

=over 4

=back

Returns the RLP encoded transaction bytes

=head2 generate_v

Generate the transaction v field using the given y-parity

=over 4

=item * C<$y_parity> y-parity

=back

Returns the v hexadecimal value also sets the v fields from transaction

=head2 hash

SHA3 Hash the serialized transaction object

=over 4

=back

Returns the SHA3 transaction hash bytes

=head1 AUTHOR

Reginaldo Costa <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
