use v5.26;
use Object::Pad;

package Blockchain::Ethereum::ABI::Type::Address 0.012;
class Blockchain::Ethereum::ABI::Type::Address
    :isa(Blockchain::Ethereum::ABI::Type)
    :does(Blockchain::Ethereum::ABI::TypeRole);

=encoding utf8

=head1 NAME

Blockchain::Ethereum::ABI::Address - Interface for solidity address type

=head1 SYNOPSIS

Allows you to define and instantiate a solidity address type:

    my $type = Blockchain::Ethereum::ABI::Address->new(
        signature => $signature,
        data      => $value
    );

    $type->encode();

In most cases you don't want to use this directly, use instead:

=over 4

=item * B<Encoder>: L<Blockchain::Ethereum::ABI::Encoder>

=item * B<Decoder>: L<Blockchain::Ethereum::ABI::Decoder>

=back

=cut

method _configure { return }

=head2 encode

Encodes the given data to the type of the signature

Usage:

    encode() -> encoded string

=over 4

=back

ABI encoded hex string

=cut

method encode {

    return $self->_encoded if $self->_encoded;
    $self->_push_static($self->pad_left(substr($self->data, 2)));

    return $self->_encoded;
}

=head2 decode

Decodes the given data to the type of the signature

Usage:

    decoded() -> address

=over 4

=back

String 0x prefixed address

=cut

method decode {

    return '0x' . substr $self->data->[0], -40;
}

1;

__END__

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ABI>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
