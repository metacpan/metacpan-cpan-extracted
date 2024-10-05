use v5.26;

use strict;
use warnings;
no indirect;
use feature 'signatures';

use Object::Pad;
# ABSTRACT: Solidity bytes type interface

package Blockchain::Ethereum::ABI::Type::Bytes;
class Blockchain::Ethereum::ABI::Type::Bytes
    :isa(Blockchain::Ethereum::ABI::Type)
    :does(Blockchain::Ethereum::ABI::TypeRole);

our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.016';          # VERSION

use Carp;

method _configure { return }

method encode {

    return $self->_encoded if $self->_encoded;
    # remove 0x and validates the hexadecimal value
    croak 'Invalid hexadecimal value ' . $self->data // 'undef'
        unless $self->data =~ /^(?:0x|0X)?([a-fA-F0-9]+)$/;
    my $hex = $1;

    my $data_length = length(pack("H*", $hex));
    unless ($self->fixed_length) {
        # for dynamic length basic types the length must be included
        $self->_push_dynamic($self->_encode_length($data_length));
        $self->_push_dynamic($self->pad_right($hex));
    } else {
        croak "Invalid data length, signature: @{[$self->fixed_length]}, data length: $data_length"
            if $self->fixed_length && $data_length != $self->fixed_length;
        $self->_push_static($self->pad_right($hex));
    }

    return $self->_encoded;
}

method decode {

    my @data = $self->data->@*;

    my $hex_data;
    my $size = $self->fixed_length;
    unless ($self->fixed_length) {
        $size = hex shift @data;

        $hex_data = join('', @data);
    } else {
        $hex_data = $data[0];
    }

    my $bytes = substr(pack("H*", $hex_data), 0, $size);
    return sprintf "0x%s", unpack("H*", $bytes);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI::Type::Bytes - Solidity bytes type interface

=head1 VERSION

version 0.016

=head1 SYNOPSIS

Allows you to define and instantiate a solidity bytes type:

    my $type = Blockchain::Ethereum::ABI::Bytes->new(
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

hexadecimal encoded bytes string

=head1 AUTHOR

Reginaldo Costa <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
