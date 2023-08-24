use v5.26;
use Object::Pad ':experimental(init_expr)';

package Blockchain::Ethereum::ABI::Decoder 0.012;
class Blockchain::Ethereum::ABI::Decoder;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::ABI::Decoder - Contract ABI response decoder

=head1 SYNOPSIS

Allows you to decode contract ABI response

    my $decoder = Blockchain::Ethereum::ABI::Decoder->new();
    $decoder
        ->append('uint256')
        ->append('bytes[]')
        ->decode('0x...');

=cut

use Carp;

use Blockchain::Ethereum::ABI::Type;
use Blockchain::Ethereum::ABI::Type::Tuple;

field $_instances :reader(_instances) :writer(set_instances) = [];

=head2 append

Appends type signature to the decoder.

Usage:

    append(signature) -> L<Blockchain::Ethereum::ABI::Encoder>

=over 4

=item * C<$param> type signature e.g. uint256

=back

Returns C<$self>

=cut

method append ($param) {

    push $self->_instances->@*, Blockchain::Ethereum::ABI::Type->new(signature => $param);
    return $self;
}

=head2 decode

Decodes appended signatures

Usage:

    decode() -> []

=over 4

=back

Returns an array reference containing all decoded values

=cut

method decode ($hex_data) {

    croak 'Invalid hexadecimal value ' . $hex_data // 'undef'
        unless $hex_data =~ /^(?:0x|0X)?([a-fA-F0-9]+)$/;

    my $hex  = $1;
    my @data = unpack("(A64)*", $hex);

    my $tuple = Blockchain::Ethereum::ABI::Type::Tuple->new;
    $tuple->set_instances($self->_instances);
    $tuple->set_data(\@data);
    my $data = $tuple->decode;

    $self->_clean;
    return $data;
}

method _clean {

    $self->set_instances([]);
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
