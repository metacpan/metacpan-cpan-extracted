package Blockchain::Contract::Solidity::ABI::Decoder;

use v5.26;
use strict;
use warnings;
no indirect;

use Carp;

use Blockchain::Contract::Solidity::ABI::Type;
use Blockchain::Contract::Solidity::ABI::Type::Tuple;

sub new {
    my ($class, %params) = @_;

    my $self = {};
    bless $self, $class;
    return $self;
}

sub _instances {
    my $self = shift;
    return $self->{instances} //= [];
}

sub append {
    my ($self, $param) = @_;

    push $self->_instances->@*, Blockchain::Contract::Solidity::ABI::Type::new_type(signature => $param);
    return $self;
}

sub decode {
    my ($self, $hex_data) = @_;

    croak 'Invalid hexadecimal value ' . $hex_data // 'undef'
        unless $hex_data =~ /^(?:0x|0X)?([a-fA-F0-9]+)$/;

    my $hex  = $1;
    my @data = unpack("(A64)*", $hex);

    my $tuple = Blockchain::Contract::Solidity::ABI::Type::Tuple->new;
    $tuple->{instances} = $self->_instances;
    $tuple->{data}      = \@data;
    my $data = $tuple->decode;

    $self->_clean;
    return $data;
}

sub _clean {
    my $self = shift;
    delete $self->{instances};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Contract::Solidity::ABI::Decoder - Contract ABI response decoder

=head1 SYNOPSIS

Allows you to decode contract ABI response

    my $decoder = Blockchain::Contract::Solidity::ABI::Decoder->new();
    $decoder
        ->append('uint256')
        ->append('bytes[]')
        ->decode('0x...');
    ...

=head1 METHODS

=head2 append

Appends type signature to the decoder.

Usage:

    append(signature) -> L<Blockchain::Contract::Solidity::ABI::Encoder>

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

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ABI>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Blockchain::Contract::Solidity::ABI::Encoder

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT License

=cut

