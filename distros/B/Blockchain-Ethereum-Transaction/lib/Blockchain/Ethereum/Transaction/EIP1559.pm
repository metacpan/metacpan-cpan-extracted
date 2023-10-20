use v5.26;
use Object::Pad ':experimental(init_expr)';
# ABSTRACT: Ethereum Fee Market transaction abstraction

package Blockchain::Ethereum::Transaction::EIP1559;
class Blockchain::Ethereum::Transaction::EIP1559
    :does(Blockchain::Ethereum::Transaction);

our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.009';          # VERSION

use constant TRANSACTION_PREFIX => pack("H*", '02');

field $max_priority_fee_per_gas :reader :writer :param;
field $max_fee_per_gas :reader :writer :param;
field $access_list :reader :writer :param = [];

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

    @params = $self->_equalize_params(\@params)->@*;

    push(@params, $self->v, $self->r, $self->s)
        if $self->v && $self->r && $self->s;

    # eip-1559 transactions must be prefixed by 2 that is the
    # transaction type
    return TRANSACTION_PREFIX . $self->rlp->encode(\@params);
}

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

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Transaction::EIP1559 - Ethereum Fee Market transaction abstraction

=head1 VERSION

version 0.009

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

=head1 METHODS

=head2 serialize

Encodes the given transaction parameters to RLP

=over 4

=back

Returns the RLP encoded transaction bytes

=head2 generate_v

Generate the transaction v field using the given y-parity

=over 4

=item * C<$y_parity> y-parity

=back

Returns the v hexadecimal value also sets the v fields from transaction

=head1 AUTHOR

Reginaldo Costa <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
