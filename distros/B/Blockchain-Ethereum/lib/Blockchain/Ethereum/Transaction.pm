package Blockchain::Ethereum::Transaction;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum transaction abstraction
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256);

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

sub generate_v {
    croak "generate_v method not implemented";
}

sub hash {
    my $self = shift;

    return keccak256($self->serialize);
}

# In case of Math::BigInt given for any params, get the hex value
sub _equalize_params {
    my ($self, $params) = @_;

    return [map { ref $_ eq 'Math::BigInt' ? $_->as_hex : $_ } $params->@*];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Transaction - Ethereum transaction abstraction

=head1 VERSION

version 0.019

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

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
