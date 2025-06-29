package Blockchain::Ethereum::ABI;

use v5.26;
use strict;
use warnings;

# ABSTRACT: ABI utility for encoding/decoding ethereum contract arguments
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI - ABI utility for encoding/decoding ethereum contract arguments

=head1 VERSION

version 0.019

=head1 SYNOPSIS

The Contract Application Binary Interface (ABI) is the standard way to interact
with contracts (Ethereum), this module aims to be an utility to encode/decode the given
data according ABI type specification.

Supports:

=over 4

=item * B<address>

=item * B<bool>

=item * B<bytes(\d+)?>

=item * B<(u)?int(\d+)?>

=item * B<string>

=item * B<tuple>

=back

Also arrays C<((\[(\d+)?\])+)?> for the above mentioned types.

Encoding:

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
        ->append('((int256)[2])' => [[[1], [2]]])->encode;

Decoding

    my $decoder = Blockchain::Ethereum::ABI::Decoder->new();
    $decoder
        ->append('uint256')
        ->append('bytes[]')
        ->decode('0x...');

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
