use v5.26;
use Object::Pad ':experimental(init_expr)';

package Blockchain::Ethereum::ABI::Encoder 0.011;
class Blockchain::Ethereum::ABI::Encoder;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::ABI::Encoder - Contract ABI argument encoder

=head1 SYNOPSIS

Allows you to encode contract ABI arguments

    my $encoder = Blockchain::Ethereum::ABI::Encoder->new();
    $encoder->function('test')
        # string
        ->append(string => 'Hello, World!')
        # bytes
        ->append(bytes => unpack("H*", 'Hello, World!'))
        # tuple
        ->append('(uint256,address)' => [75000000000000, '0x0000000000000000000000000000000000000000'])
        # arrays
        ->append('bool[]', [1, 0, 1, 0])
        # multidimensional arrays
        ->append('uint256[][][2]', [[[1]], [[2]]])
        # tuples arrays and tuples inside tuples
        ->append('((int256)[2])' => [[[1], [2]]])->encode();

=cut

use Carp;
use Digest::Keccak qw(keccak_256_hex);

use Blockchain::Ethereum::ABI::Type;
use Blockchain::Ethereum::ABI::Type::Tuple;

field $_instances :reader(_instances) :writer(set_instances) = [];
field $_function_name :reader(_function_name) :writer(set_function_name);

=head2 append

Appends type signature and the respective values to the encoder.

Usage:

    append(signature => value) -> L<Blockchain::Ethereum::ABI::Encoder>

=over 4

=item * C<%param> key is the respective type signature followed by the value e.g. uint256 => 10

=back

Returns C<$self>

=cut

method append (%param) {

    for my $type_signature (keys %param) {
        push(
            $self->_instances->@*,
            Blockchain::Ethereum::ABI::Type->new(
                signature => $type_signature,
                data      => $param{$type_signature}));
    }

    return $self;
}

=head2 function

Appends the function name to the encoder, this is optional for when you want the
function signature added to the encoded string or only the function name encoded.

Usage:

    function(string) -> L<Blockchain::Ethereum::ABI::Encoder>

=over 4

=item * C<$function_name> solidity function name e.g. for `transfer(address,uint256)` will be `transfer`

=back

Returns C<$self>

=cut

method function ($function_name) {

    $self->set_function_name($function_name);
    return $self;
}

=head2 generate_function_signature

Based on the given function name and type signatures create the complete function
signature.

Usage:

    generate_function_signature() -> string

=over 4

=back

Returns the function signature string

=cut

method generate_function_signature {

    croak "Missing function name e.g. ->function('name')" unless $self->_function_name;
    my $signature = $self->_function_name . '(';
    $signature .= sprintf("%s,", $_->signature) for $self->_instances->@*;
    chop $signature;
    return $signature . ')';
}

=head2 encode_function_signature

Encode function signature keccak_256/sha3

Usage:

    encode_function_signature('transfer(address,uint)') -> encoded string

=over 4

=item * C<$signature> (Optional) function signature, if not given, will try to use the appended function name

=back

Returns the encoded string 0x prefixed

=cut

method encode_function_signature ($signature = undef) {

    return sprintf("0x%.8s", keccak_256_hex($signature // $self->generate_function_signature));
}

=head2 encode

Encodes appended signatures and the function name (when given)

Usage:

    encode() -> encoded string

=over 4

=back

Returns the encoded string, if function name was given will be 0x prefixed

=cut

method encode {

    my $tuple = Blockchain::Ethereum::ABI::Type::Tuple->new;
    $tuple->set_instances($self->_instances);
    my @data = $tuple->encode->@*;
    unshift @data, $self->encode_function_signature if $self->_function_name;

    $self->_clean;

    return join('', @data);
}

method _clean {

    $self->set_instances([]);
    $self->set_function_name(undef);
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
