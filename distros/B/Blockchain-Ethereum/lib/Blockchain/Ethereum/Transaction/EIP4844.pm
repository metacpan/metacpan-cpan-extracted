package Blockchain::Ethereum::Transaction::EIP4844;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum Blob transaction abstraction (EIP-4844)
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.021';          # VERSION

use parent 'Blockchain::Ethereum::Transaction';

use constant TRANSACTION_PREFIX => pack("H*", '03');

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);

    foreach (qw( max_priority_fee_per_gas max_fee_per_gas max_fee_per_blob_gas blob_versioned_hashes access_list )) {
        $self->{$_} = $args{$_} if exists $args{$_};
    }

    bless $self, $class;
    return $self;
}

sub max_fee_per_blob_gas {
    return shift->{max_fee_per_blob_gas};
}

sub max_priority_fee_per_gas {
    return shift->{max_priority_fee_per_gas};
}

sub max_fee_per_gas {
    return shift->{max_fee_per_gas};
}

sub blob_versioned_hashes {
    return shift->{blob_versioned_hashes} // [];
}

sub access_list {
    return shift->{access_list} // [];
}

sub serialize {
    my $self = shift;

    my @params = (
        $self->chain_id,            $self->nonce, $self->max_priority_fee_per_gas, $self->max_fee_per_gas,
        $self->gas_limit,           $self->to,    $self->value,                    $self->data,
        $self->_encode_access_list, $self->max_fee_per_blob_gas, $self->blob_versioned_hashes,
    );

    @params = $self->_normalize_params(\@params)->@*;

    push(@params, $self->v, $self->r, $self->s)
        if $self->v && $self->r && $self->s;

    return TRANSACTION_PREFIX . $self->rlp->encode(\@params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Transaction::EIP4844 - Ethereum Blob transaction abstraction (EIP-4844)

=head1 VERSION

version 0.021

=head1 SYNOPSIS

Transaction abstraction for EIP-4844 Blob transactions (Proto-danksharding)

    my $transaction = Blockchain::Ethereum::Transaction::EIP4844->new(
        nonce                    => '0x0',
        max_fee_per_gas          => '0x4A817C800',
        max_priority_fee_per_gas => '0x77359400',
        max_fee_per_blob_gas     => '0x3B9ACA00',
        gas_limit                => '0x186A0',
        to                       => '0x1234567890123456789012345678901234567890',
        value                    => parse_unit('0.1', ETH),
        data                     => '0xdeadbeef',
        chain_id                 => '0x1',
        access_list => [
            {
                address      => '0x1234567890123456789012345678901234567890',
                storage_keys => [
                    '0x0000000000000000000000000000000000000000000000000000000000000001'
                ]
            }
        ],
        blob_versioned_hashes => [
            '0x010657f37554c781402a22917dee2f75def7ab966d7b770905398eba3c444014',
            '0x01ac9710ba11d0d3cbea6d499ddc888c02f3374c2336331f3e11b33260054aeb'
        ]
    );

    my $key = Blockchain::Ethereum::Keystore::Key->new(
        private_key => pack "H*",
        '4646464646464646464646464646464646464646464646464646464646464646'
    );

    $key->sign_transaction($transaction);

    my $raw_transaction = $transaction->serialize;

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
