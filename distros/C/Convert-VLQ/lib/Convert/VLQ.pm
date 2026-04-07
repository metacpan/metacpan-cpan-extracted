# $Id: VLQ.pm 2774 2026-04-06 21:17:59Z fil $
package Convert::VLQ;

use 5.010001;
use strict;
use warnings;

use Carp qw( confess );

our $VERSION = '0.01';

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( int2vlqs vlqs2int encode_vlq decode_vlq );

sub VLQ_BASE_SHIFT { 5 }
sub VLQ_BASE_MASK { 0x1f }          # binary:  11111
sub VLQ_CONTINUATION_BIT { 0x20 }   # binary: 100000

my $B64chrs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
my @B64 = ("A" .. "Z", "a" .. "z", 0 .. 9, "+", "/" );
# my @B64 = ( split //, $B64chrs );
my %_B64;
@_B64{@B64} = (0..length $B64chrs);

sub int2vlqs
{
    my( $v ) = @_;
    $v = int $v;
    return( ((-$v) << 1 ) + 1 ) if $v < 0;
    return( ($v<<1) + 0 );
}

sub vlqs2int
{
    my( $v ) = @_;
    my $shifted = $v >> 1;
    return -$shifted if $v & 1;
    return $shifted;
}


sub encode_vlq
{
    my( $v ) = @_;
    if( ref $v ) {
        return join '', map { encode_vlq( $_ ) } @$v;
    }
    my $ret = '';
    my $vlq = int2vlqs( $v );
    do {
        my $digit = $vlq & VLQ_BASE_MASK;   # grab 5 bits
        $vlq >>= VLQ_BASE_SHIFT;            # remove those bits from input
        $digit |= VLQ_CONTINUATION_BIT if $vlq > 0; # should we continue?
        $ret .= $B64[$digit];               # convert to base64
    } while( $vlq > 0 );
    return $ret;
}


sub decode_vlq
{
    my( $v ) = @_;

    return unless defined $v;

    if( !wantarray ) {
        my @ret;
        my $n;
        while( length $v ) {
            ( $n, $v ) = decode_vlq( $v );
            push @ret, $n;
        }
        return \@ret;
    }

    my @v = split //, $v;

    my $ret = 0;
    my $shift = 0;
    my $cont = 1;
    while( @v and $cont ) {
        my $d = shift @v;
        confess "Invalid base64 digit: ", $d unless exists $_B64{$d};
        my $digit = $_B64{ $d }; 
        $cont = ($digit & VLQ_CONTINUATION_BIT); # 6th bit is continuation
        $digit &= VLQ_BASE_MASK;        # bottom 5 bits are what we want
        $ret += $digit << $shift;       # shift and add to answer
        $shift += VLQ_BASE_SHIFT;       # next time we shift even more
    } 
    return( vlqs2int( $ret ), join '', @v );    
}

1;

__END__

=head1 NAME

Convert::VLQ - Convert to and from VLQ base64 representation used in source maps

=head1 SYNOPSIS

    use Convert::VLQ qw( encode_vlq decode_vlq );

    my $encoded = encode_vlq( 15 );
    my $AAAA = encode_vlq( [0,0,0,0] );

    my( $int, $rest ) = decode_vlq( "A" );
    my $array = decode_vlq( "AAAA" );

=head1 DESCRIPTION

Functions to encode and decode base64 VLQ representations of line and column
numbers used in browser source maps.

=over 2

A variable-length quantity (VLQ) is a universal code that uses an arbitrary
number of binary octets (eight-bit bytes) to represent an arbitrarily large
integer.  A VLQ is essentially a base-128 representation of an unsigned
integer with the addition of the eighth bit to mark continuation of bytes. 

- L<https://en.wikipedia.org/wiki/Variable-length_quantity>

=back

=over 2

Base64 is a binary-to-text encoding that uses 64 printable characters to
represent each 6-bit segment of a sequence of byte values.

- L<https://en.wikipedia.org/wiki/Base64>

=back

=head1 FUNCTIONS

=head2 encode_vlq

    # 0 becomes "A"
    my $encoded = encode_vlq( $number );
    # [0,0,0,0] becomes "AAAA"
    my $mapping = encode_vlq( [$src_row, $src_col, $dest_row, $dest_col] );

Converts one or more numbers into a string.  

If passed a single number, returns the VLQ base64 representation of that number.

If passed an array ref, it returns a concatination of the VLQ base64
represtation of all the numbers in the array.

Will return C<undef> if you pass it C<undef>.


=head2 decode_vlq

    # "AAAA" becomes [0,0,0,0]
    my $map = encode_vlq( $mapping );
    my( $src_row, $src_col, $dest_row, $dest_col ) = @$map;

    # "AAAA" becomes (0,"AAA")
    my( $number, $remaining ) = encode_vlq( $mapping );

Converts the VLQ base64 representation back to an arrayref of integers.

If called in an array context, C<decode_vlq> returns the first integer and
the remaining string as an array.


=head2 int2vlqs

    use Convert::VLQ qw( int2vlqs );
    my $vlqs = int2vlqs( $int );

Converts an integer into a signed VLQ.


=head2 vlqs2int

    use Convert::VLQ qw( int2vlqs );
    my $int = vlqs2int( $vlqs );

Converts a signed VLQ into an integer.


=head1 NOTES

Javascript integers are limited to 32 bits.  We do not enforce this limit.


=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Variable-length_quantity>,
L<https://tc39.es/ecma426/#sec-base64-vlq>


=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
