package Data::HexConverter;

use strict;
use warnings;
use Exporter qw(import);

our $VERSION = '0.03';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(hex_to_binary binary_to_hex);
our @EXPORT = ();

1;

__END__

=head1 NAME

Data::HexConverter - High performance hex string to binary converter

=head1 SYNOPSIS

    use Data::HexConverter;
    my $hex_ref = \"41424344";
    my $binary  = Data::HexConverter::hex_to_binary($hex_ref);
    # $binary now contains "ABCD"

	 my $hex = Data::HexConverter::binary_to_hex(\$binary);
	 # $hex now contains "41424344"

=head1 DESCRIPTION

This module provides two functions, C<hex_to_binary> and
C<binary_to_hex>.

C<hex_to_binary> accepts a reference to a scalar containing an ASCII
hexadecimal string and returns a binary string.  It uses SSSE3
intrinsics to convert blocks of 32 characters at a time for maximum
throughput.  Remaining characters are handled via a lookup table.  If
the input contains an odd number of characters or an invalid hex
digit, an exception is thrown.

C<binary_to_hex> performs the reverse operation: it accepts a
reference to a scalar containing arbitrary binary data and returns an
uppercase hexadecimal representation.  It uses SSSE3 vector
instructions to expand 16 bytes at a time but will fall back to a
scalar implementation and emit a warning if SSSE3 is not available.

=head1 VERSION

Version 0.03

=cut


=head1 FUNCTIONS

=head2 hex_to_binary

    my $binary = Data::HexConverter::hex_to_binary(\$hex_string);

Converts the hexadecimal string pointed at by the reference into its
binary form and returns it as a Perl scalar.  The input scalar must
only contain ASCII characters; if the scalar is flagged as UTF-8 it is
downgraded to bytes using C<sv_utf8_downgrade>[817665102442637-L378-L404].  An exception is thrown if the
string cannot be downgraded or if it contains invalid characters.

=head2 binary_to_hex

    my $hex = Data::HexConverter::binary_to_hex(\$binary_string);

Converts a binary string referenced by the argument into its uppercase
hexadecimal representation and returns it as a Perl scalar.  Each
input byte becomes two hex characters.  The input scalar is
downgraded from UTF-8 if necessary.  A warning is issued and a
scalar implementation is used if the CPU lacks SSSE3 support.  An
exception is thrown if the argument is not a reference to a scalar.

=head1 AUTHOR

Jared Still

Assisted by ChatGPT.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Jared Still.

This is free software, licensed under:

  MIT License

=cut

