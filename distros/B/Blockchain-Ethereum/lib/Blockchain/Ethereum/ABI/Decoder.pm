package Blockchain::Ethereum::ABI::Decoder;

use v5.26;
use strict;
use warnings;

# ABSTRACT: ABI utility for decoding ethereum contract arguments
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use Carp;

use Blockchain::Ethereum::ABI::Type;
use Blockchain::Ethereum::ABI::Type::Tuple;

sub new {
    my $class = shift;
    my $self  = {
        instances => [],
    };

    return bless $self, $class;
}

sub append {
    my ($self, $param) = @_;

    push $self->{instances}->@*, Blockchain::Ethereum::ABI::Type->new(signature => $param);
    return $self;
}

sub decode {
    my ($self, $hex_data) = @_;

    croak 'Invalid hexadecimal value ' . $hex_data // 'undef'
        unless $hex_data =~ /^(?:0x|0X)?([a-fA-F0-9]+)$/;

    my $hex  = $1;
    my @data = unpack("(A64)*", $hex);

    my $tuple = Blockchain::Ethereum::ABI::Type::Tuple->new;
    $tuple->{instances} = $self->{instances};
    $tuple->{data}      = \@data;
    my $data = $tuple->decode;

    $self->_clean;
    return $data;
}

sub _clean {
    my $self = shift;

    $self->{instances} = [];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI::Decoder - ABI utility for decoding ethereum contract arguments

=head1 VERSION

version 0.019

=head1 SYNOPSIS

Allows you to decode contract ABI response

    my $decoder = Blockchain::Ethereum::ABI::Decoder->new();
    $decoder
        ->append('uint256')
        ->append('bytes[]')
        ->decode('0x...');

=head1 METHODS

=head2 append

Appends type signature to the decoder.

Usage:

    append(signature) -> L<Blockchain::Ethereum::ABI::Encoder>

=over 4

=item * C<$param> type signature e.g. uint256

=back

Returns C<$self>

=head2 decode

Decodes appended signatures

Usage:

    decode() -> []

=over 4

=back

Returns an array reference containing all decoded values

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
