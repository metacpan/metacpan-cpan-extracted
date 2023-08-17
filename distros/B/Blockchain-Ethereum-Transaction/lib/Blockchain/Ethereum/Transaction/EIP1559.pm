use v5.26;
use Object::Pad ':experimental(init_expr)';

package Blockchain::Ethereum::Transaction::EIP1559 0.005;
class Blockchain::Ethereum::Transaction::EIP1559
    :does(Blockchain::Ethereum::Transaction);

=encoding utf8

=head1 NAME

Blockchain::Ethereum::Transaction::EIP1559 - Ethereum Fee Market transaction abstraction

=head1 SYNOPSIS

Transaction abstraction for EIP1559 Fee Market transactions

    my $transaction = Blockchain::Ethereum::Transaction::EIP1559->new(
        nonce                    => '0x0',
        max_fee_per_gas          => '0x9',
        max_priority_fee_per_gas => '0x0',
        gas_limit                => '0x1DE2B9',
        to                       => '0x3535353535353535353535353535353535353535'
        value                    => '0xDE0B6B3A7640000',
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

=cut

use constant TRANSACTION_PREFIX => pack("H*", '02');

field $max_priority_fee_per_gas :reader :writer :param;
field $max_fee_per_gas :reader :writer :param;
field $access_list :reader :writer :param = [];

=head2 serialize

Encodes the given transaction parameters to RLP

Usage:

    serialize() -> RLP encoded transaction bytes

=over 4

=back

Returns the RLP encoded transaction bytes

=cut

method serialize() {

    my @params = (
        $self->chain_id,    #
        $self->nonce,
        $self->max_priority_fee_per_gas,
        $self->max_fee_per_gas,
        $self->gas_limit,
        $self->to,
        $self->value,
        $self->data,
        $self->access_list,
    );

    push(@params, $self->v, $self->r, $self->s)
        if $self->v && $self->r && $self->s;

    # eip-1559 transactions must be prefixed by 2 that is the
    # transaction type
    return TRANSACTION_PREFIX . $self->rlp->encode(\@params);
}

=head2 generate_v

Generate the transaction v field using the given y-parity

Usage:

    generate_v($y_parity) -> hexadecimal v

=over 4

=item * C<$y_parity> y-parity

=back

Returns the v hexadecimal value also sets the v fields from transaction

=cut

method generate_v ($y_parity) {

    # eip-1559 uses y directly as the v point
    # instead of using recovery id as the legacy
    # transactions
    my $v = sprintf("0x%x", $y_parity);
    $self->set_v($v);
    return $v;
}

1;

__END__

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ethereum-transaction>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
