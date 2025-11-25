package Blockchain::Ethereum::Transaction;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum transaction abstraction
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.021';          # VERSION

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256);
use Scalar::Util             qw(blessed looks_like_number);
use Math::BigInt;

use Blockchain::Ethereum::RLP;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    foreach (qw(chain_id nonce gas_limit to value data v r s)) {
        $self->{$_} = $args{$_} if exists $args{$_};
    }

    return $self;
}

sub rlp {
    my $self = shift;

    return $self->{rlp} //= Blockchain::Ethereum::RLP->new;
}

sub chain_id {
    return shift->{chain_id};
}

sub nonce {
    return shift->{nonce};
}

sub gas_limit {
    return shift->{gas_limit};
}

sub to {
    return shift->{to} // '';
}

sub value {
    return shift->{value} // '0x0';
}

sub data {
    return shift->{data} // '';
}

sub v {
    return shift->{v};
}

sub set_v {
    my ($self, $v) = @_;
    $self->{v} = $v;
}

sub r {
    return shift->{r};
}

sub set_r {
    my ($self, $r) = @_;
    $self->{r} = $r;
}

sub s {
    my $self = shift;
    return $self->{s};
}

sub set_s {
    my ($self, $s) = @_;
    $self->{s} = $s;
}

sub serialize {
    croak "serialize method not implemented";
}

sub hash {
    my $self = shift;

    return keccak256($self->serialize);
}

# Hex conversion
sub _normalize_params {
    my ($self, $params) = @_;

    return [
        map {
            !defined $_
                ? $_                                                                                                   # undefined
                : blessed $_ && $_->isa('Math::BigInt') ? $_->as_hex                                                   # BigInt
                : /^0x/i                                ? $_                                                           # hex string
                : looks_like_number($_) && $_ == int($_)                            ? Math::BigInt->new($_)->as_hex    # integer/numeric string
                : blessed $_            && $_->isa('Blockchain::Ethereum::Address') ? $_->to_string                    # Ethereum Address object
                : $_                                                                                                   # anything else
        } @$params
    ];
}

sub _encode_access_list {
    my $self = shift;

    my $access_list = $self->access_list();

    # If no access list, return empty array
    return [] unless @$access_list;

    my @encoded_list;

    for my $entry (@$access_list) {
        my $address      = $entry->{address}      // '';
        my $storage_keys = $entry->{storage_keys} // [];

        push @encoded_list, [$address, $storage_keys];
    }

    return \@encoded_list;
}

sub generate_v {
    my ($self, $y_parity) = @_;

    # eip-1559 and eip-2930 uses y-parity directly as the v value
    my $v = sprintf("0x%x", $y_parity);
    $self->set_v($v);
    return $v;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Transaction - Ethereum transaction abstraction

=head1 VERSION

version 0.021

=head1 DESCRIPTION

Ethereum transaction abstraction for generating raw transactions

Supported transaction types:

=over 4

=item * L<Blockchain::Ethereum::Transaction::Legacy>  - Legacy Transaction

=item * L<Blockchain::Ethereum::Transaction::EIP1559> - Fee Market Transaction

=item * L<Blockchain::Ethereum::Transaction::EIP2930> - Optional Access Lists Transaction

=item * L<Blockchain::Ethereum::Transaction::EIP4844> - Blob Transaction

=back

=head1 METHODS

=head2 serialize

To be implemented by the child classes, encodes the given transaction parameters to RLP

=over 4

=back

Returns the RLP encoded transaction bytes

=head2 hash

SHA3 Hash the serialized transaction object

=over 4

=back

Returns the SHA3 transaction hash bytes

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
