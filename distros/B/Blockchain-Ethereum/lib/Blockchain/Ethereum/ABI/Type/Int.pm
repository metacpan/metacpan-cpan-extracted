package Blockchain::Ethereum::ABI::Type::Int;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Solidity uint/int/bool type interface
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use parent 'Blockchain::Ethereum::ABI::Type';

use Carp;
use Math::BigInt try => 'GMP';
use Scalar::Util qw(looks_like_number);

use constant {
    DEFAULT_INT_SIZE => 256,
    HFF              => '0x' . 'F' x 64,
    HMAX             => '0x8' . '0' x 63
};

sub _configure { return }

sub encode {
    my $self = shift;

    return $self->_encoded if $self->_encoded;

    croak "Invalid numeric data @{[$self->{data}]}" unless looks_like_number($self->{data});

    my $bdata = Math::BigInt->new($self->{data});

    croak "Invalid numeric data @{[$self->{data}]}" if $bdata->is_nan;

    croak "Invalid data length, signature: @{[$self->fixed_length]}, data length: @{[$bdata->length]}"
        if $self->fixed_length && $bdata->length > $self->fixed_length;

    croak "Invalid negative numeric data @{[$self->{data}]}"
        if $bdata->is_neg && $self->{signature} =~ /^uint|bool/;

    croak "Invalid bool data it must be 1 or 0 but given @{[$self->{data}]}"
        if !$bdata->is_zero && !$bdata->is_one && $self->{signature} =~ /^bool/;

    $bdata->bneg->bxor(HFF)->binc if $bdata->is_neg;

    $self->_push_static($self->pad_left($bdata->to_hex));

    return $self->_encoded;
}

sub decode {
    my $self = shift;

    my $bdata = Math::BigInt->from_hex(ref $self->{data} eq 'ARRAY' ? $self->{data}->[0] : $self->{data});

    $bdata->bxor(HFF)->binc->bneg if $bdata->copy->band(HMAX);

    return $bdata;
}

sub fixed_length {
    my $self = shift;

    if ($self->{signature} =~ /[a-z](\d+)/) {
        return $1;
    }
    return DEFAULT_INT_SIZE;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI::Type::Int - Solidity uint/int/bool type interface

=head1 VERSION

version 0.019

=head1 SYNOPSIS

Allows you to define and instantiate a solidity address type:

    my $type = Blockchain::Ethereum::ABI::Int->new(
        signature => $signature,
        data      => $value
    );

    $type->encode();

In most cases you don't want to use this directly, use instead:

=over 4

=item * B<Encoder>: L<Blockchain::Ethereum::ABI::Encoder>

=item * B<Decoder>: L<Blockchain::Ethereum::ABI::Decoder>

=back

=head1 METHODS

=head2 encode

Encodes the given data to the type of the signature

=over 4

=back

ABI encoded hex string

=head2 decode

Decodes the given data to the type of the signature

=over 4

=back

L<Math::BigInt>

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
