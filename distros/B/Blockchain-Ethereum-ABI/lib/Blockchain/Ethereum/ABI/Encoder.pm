use v5.26;

use strict;
use warnings;
no indirect;
use feature 'signatures';

use Object::Pad ':experimental(init_expr)';
# ABSTRACT: ABI utility for encoding ethereum contract arguments

package Blockchain::Ethereum::ABI::Encoder;
class Blockchain::Ethereum::ABI::Encoder;

our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.016';          # VERSION

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256_hex);

use Blockchain::Ethereum::ABI::Type;
use Blockchain::Ethereum::ABI::Type::Tuple;

field $_instances :reader(_instances) :writer(set_instances) = [];
field $_function_name :reader(_function_name) :writer(set_function_name);

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

method function ($function_name) {

    $self->set_function_name($function_name);
    return $self;
}

method generate_function_signature {

    croak "Missing function name e.g. ->function('name')" unless $self->_function_name;
    my $signature = $self->_function_name . '(';
    $signature .= sprintf("%s,", $_->signature) for $self->_instances->@*;
    chop $signature;
    return $signature . ')';
}

method encode_function_signature ($signature = undef) {

    return sprintf("0x%.8s", keccak256_hex($signature // $self->generate_function_signature));
}

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

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI::Encoder - ABI utility for encoding ethereum contract arguments

=head1 VERSION

version 0.016

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

=head1 METHODS

=head2 append

Appends type signature and the respective values to the encoder.

=over 4

=item * C<%param> key is the respective type signature followed by the value e.g. uint256 => 10

=back

Returns C<$self>

=head2 function

Appends the function name to the encoder, this is optional for when you want the
function signature added to the encoded string or only the function name encoded.

=over 4

=item * C<$function_name> solidity function name e.g. for `transfer(address,uint256)` will be `transfer`

=back

Returns C<$self>

=head2 generate_function_signature

Based on the given function name and type signatures create the complete function
signature.

=over 4

=back

Returns the function signature string

=head2 encode_function_signature

Encode function signature keccak_256/sha3

=over 4

=item * C<$signature> (Optional) function signature, if not given, will try to use the appended function name

=back

Returns the encoded string 0x prefixed

=head2 encode

Encodes appended signatures and the function name (when given)

Usage:

    encode() -> encoded string

=over 4

=back

Returns the encoded string, if function name was given will be 0x prefixed

=head1 AUTHOR

Reginaldo Costa <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
