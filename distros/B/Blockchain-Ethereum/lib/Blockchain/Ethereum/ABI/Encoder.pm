package Blockchain::Ethereum::ABI::Encoder;

use v5.26;
use strict;
use warnings;

# ABSTRACT: ABI utility for encoding ethereum contract arguments
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256_hex);

use Blockchain::Ethereum::ABI::Type;
use Blockchain::Ethereum::ABI::Type::Tuple;

sub new {
    my $class = shift;
    my $self  = {
        instances     => [],
        function_name => undef,
    };

    return bless $self, $class;
}

sub append {
    my ($self, %param) = @_;

    for my $type_signature (keys %param) {
        push(
            $self->{instances}->@*,
            Blockchain::Ethereum::ABI::Type->new(
                signature => $type_signature,
                data      => $param{$type_signature}));
    }

    return $self;
}

sub function {
    my ($self, $function_name) = @_;

    $self->{function_name} = $function_name;
    return $self;
}

sub generate_function_signature {
    my $self = shift;

    croak "Missing function name e.g. ->function('name')" unless $self->{function_name};

    my @instances = $self->{instances}->@*;

    my $signature = $self->{function_name} . '(';
    $signature .= sprintf("%s,", $_->{signature}) for @instances;
    chop $signature if scalar @instances;
    return $signature . ')';
}

sub encode_function_signature {
    my ($self, $signature) = @_;

    return sprintf("0x%.8s", keccak256_hex($signature // $self->generate_function_signature));
}

sub encode {
    my $self = shift;

    my $tuple = Blockchain::Ethereum::ABI::Type::Tuple->new;
    $tuple->{instances} = $self->{instances};

    my $encoded = $tuple->encode;
    my @data;
    push @data, $tuple->encode->@* if $encoded;
    unshift @data, $self->encode_function_signature if $self->{function_name};

    $self->_clean;

    return join('', @data);
}

sub _clean {
    my $self = shift;
    $self->{instances}     = [];
    $self->{function_name} = undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI::Encoder - ABI utility for encoding ethereum contract arguments

=head1 VERSION

version 0.019

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

=head2 clean

Clean up all the appended items and function name, this is called automatically after encode

Usage:

    clean() -> undef

=over 4

=back

undef

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
