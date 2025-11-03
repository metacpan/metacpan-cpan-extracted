package Data::HexConverter;
use strict;
use warnings;
use XSLoader;
use Exporter qw(import);

our $VERSION = '0.61';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

our @ISA = qw(Exporter);
our @EXPORT = qw(
	hex_to_binary
	binary_to_hex
	hex_to_binary_impl
	binary_to_hex_impl
);

our @EXPORT_OK = ();

1;

__END__

=head1 NAME

Data::HexConverter - Fast hex to binary and binary to hex using SIMD aware C code

=head1 SYNOPSIS

    use Data::HexConverter;

    my $hex_ref = \"41424344";
    my $binary  = Data::HexConverter::hex_to_binary($hex_ref);

    my $hex     = Data::HexConverter::binary_to_hex(\$binary);

    my $himpl   = Data::HexConverter::hex_to_binary_impl();
    my $bimpl   = Data::HexConverter::binary_to_hex_impl();

=head1 DESCRIPTION

This module calls a C library that picks the best implementation for the current CPU at runtime.

On an AVX512 host it will use AVX512. 

On most other hosts AVX2 will be used. 

If the host is really old (unlikely) will use SSE2 or scalar (even more unlikely).

The Perl API takes references to scalars, because the strings can be large.

=head1 FUNCTIONS

=head2 hex_to_binary(\$hexstr)

Takes a reference to a hex string, returns the decoded binary string.

=head2 binary_to_hex(\$binstr)

Takes a reference to a binary string, returns the hex encoded string.

=head2 hex_to_binary_impl()

Returns a short string with the name of the impl used for hex to bin.

=head2 binary_to_hex_impl()

Returns a short string with the name of the impl used for bin to hex.

=head1 AUTHOR

Jared Still

=head1 LICENSE

MIT License.

