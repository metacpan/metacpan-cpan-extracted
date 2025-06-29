package Blockchain::Ethereum::ABI::Type::String;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Solidity string type interface
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use parent 'Blockchain::Ethereum::ABI::Type';

sub _configure { return }

sub encode {
    my $self = shift;

    return $self->_encoded if $self->_encoded;

    my $hex = unpack("H*", $self->{data});

    # for dynamic length basic types the length must be included
    $self->_push_dynamic($self->_encode_length(length(pack("H*", $hex))));
    $self->_push_dynamic($self->pad_right($hex));

    return $self->_encoded;
}

sub decode {
    my $self = shift;

    my @data = $self->{data}->@*;

    my $size          = hex shift @data;
    my $string_data   = join('', @data);
    my $packed_string = pack("H*", $string_data);
    return substr($packed_string, 0, $size);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI::Type::String - Solidity string type interface

=head1 VERSION

version 0.019

=head1 SYNOPSIS

Allows you to define and instantiate a solidity string type:

    my $type = Blockchain::Ethereum::ABI::String->new(
        signature => $signature,
        data      => $value
    );

    $type->encode();
    ...

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

String

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
