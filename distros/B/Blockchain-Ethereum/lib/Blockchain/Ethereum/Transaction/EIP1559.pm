package Blockchain::Ethereum::Transaction::EIP1559;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum Fee Market transaction abstraction
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use parent 'Blockchain::Ethereum::Transaction';

use constant TRANSACTION_PREFIX => pack("H*", '02');

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    foreach (qw( max_priority_fee_per_gas max_fee_per_gas access_list )) {
        $self->{$_} = $args{$_} if exists $args{$_};
    }

    bless $self, $class;
    return $self;

}

sub max_priority_fee_per_gas {
    return shift->{max_priority_fee_per_gas};
}

sub max_fee_per_gas {
    return shift->{max_fee_per_gas};
}

sub access_list {
    return shift->{access_list} // [];
}

sub serialize {
    my $self = shift;

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

sub generate_v {
    my ($self, $y_parity) = @_;

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

version 0.019

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

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
