package Convert::zBase32;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    encode_zbase32 decode_zbase32 encode_base32 decode_base32
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( encode_zbase32 decode_zbase32 );

our $VERSION = '0.0201';
$VERSION = eval $VERSION;

our @zBASE32 = qw( y b n d r f g 8 e j k m c p q x 
                   o t 1 u w i s z a 3 4 5 h 7 6 9 );
my $q=0;
our %zB2N = map { $_ => $q++ } @zBASE32;

our @BASE32 =  qw( a b c d e f g h i j k l m n o p 
                   q r s t u v w x y z 2 3 4 5 6 7 );
$q=0;
our %B2N = map { $_ => $q++ } @BASE32;

# masks to use if the begining of 5-bit is w/in this octet
# keyed on the position w/in the octet
my @masks = ( 0x1f, 0x3e, 0x7c, 0xf8,   # all 5 bits in the octet
              0xf0, 0xe0, 0xc0, 0x80    # into the next one
            );

# masks of up to 4 bits in the next octet
# keyed on the sub offset
my @more_masks = ( 0x1, 0x3, 0x7, 0xf );

##################################################################
sub encode_zbase32
{
    my( $string ) = @_;

    my $ret;
    foreach my $part ( _split_string( $string ) ) {
        die "There is no $part" unless $part < 32;
        $ret .= $zBASE32[ $part ];
    }
    return $ret;
}

##################################################################
sub decode_zbase32
{
    my( $string ) = @_;
    return _join_string( map { $zB2N{$_} } split '', lc $string );
}


##################################################################
sub encode_base32
{
    my( $string ) = @_;

    my $ret;
    foreach my $part ( _split_string( $string ) ) {
        die "There is no $part" unless $part < 32;
        $ret .= $BASE32[ $part ];
    }
    return $ret;
}

##################################################################
sub decode_base32
{
    my( $string ) = @_;
    return _join_string( map { $B2N{$_} } split '', lc $string );
}


##################################################################
sub _split_string
{
    my( $string ) = @_;
    my $len = 8 * length $string;
    my( @output, $chunk, $part, $offset, $suboffset );
    # we want to build an array of 5 bit numbers
    foreach( my $q=0; $q < $len ; $q+=5 ) {
        $offset = int $q / 8;
        $suboffset = $q % 8;
        # warn "$offset, $suboffset";
        # first part
        $part = ord substr $string, $offset, 1;
        # lower bits
        $chunk = ( $part & $masks[ $suboffset ] ) >> $suboffset;
        # is this all we need?
        $suboffset -= 4; 
        if( $suboffset >= 0 ) {
            # next part
            if( $q + 5 > $len ) {
                $part = 0;          # past the end
            }
            else { 
                $part = ord substr $string, $offset+1, 1;
            }
            $chunk |= ( $part & $more_masks[ $suboffset ] ) 
                                            << (4- $suboffset);
        }
        push @output, $chunk;
    }
    return @output;
}

##################################################################
sub _join_string
{
    my( @output ) = @_;
    my $len = 5 * @output;
    my @ret = (0) x int( $len / 8);

    my $n = 0;
    my( $offset, $suboffset, $part, $chunk );
    foreach( my $q=0; $q < $len ; $q+=5 ) {
        $offset = int $q / 8;
        $suboffset = $q % 8;

        # warn "$offset, $suboffset";
        # first part
        $part = $output[ $n ];
        # lower bits
        $chunk = ($part << $suboffset ) & $masks[ $suboffset ];
        $ret[ $offset ] |= $chunk;

        # is this all we needed?
        $suboffset -= 4; 
        if( $suboffset >= 0 ) {
            $ret[ $offset +1 ] |= 
                    ( $part >> (4-$suboffset) ) & $more_masks[ $suboffset ];
        }
        $n++;
    }
    my $ret = join '', map chr, @ret;
    # remove any padding...
    substr( $ret, -1, 1, '' ) if 0 == ord substr( $ret, -1 );
    return $ret;
}


##################################################################


1;
__END__

=head1 NAME

Convert::zBase32 - Convert human-oriented base-32 encoded strings

=head1 SYNOPSIS

    use Convert::zBase32;

    my $id = encode_zbase32 $string;
    my $back = decode_zbase32 $string;

=head1 DESCRIPTION

zBase32 is similar to Base64, except that the output alphabet and ordering
is chosen to be more familiar to humans.  It uses the following 7-bit safe
32 element alphabet:

    y b n d r f g 8 e j k m c p q x o t 1 u w i s z a 3 4 5 h 7 6 9


The alphabet was permuted to make the more commonly occuring characters also
be those that were thought to be easier to read, write, speak, and remember.
For example, encoding of I<hello> in zBase32 is em3ags7p, which almost looks
like one of those unitelligable SMSes your daughter sends you.

=head2 encode_zbase32

    $zb = encode_zbase32( $string );

Convert a string to zBase32.

=head2 decode_zbase32

    $string = decode_zbase32( $zb );

Convert a string from zBase32.

=head2 encode_base32

    $b = encode_base32( $string );

Convert a string to L</Base32>.

=head2 decode_base32

    $string = decode_base32( $b );

Convert a string from L</Base32>.

=head1 Base32

Base32 is similar to zBase32, but uses the following alphabet:

    a b c d e f g h i j k l m n o p 
    q r s t u v w x y z 2 3 4 5 6 7

=head1 SEE ALSO

L<http://zooko.com/repos/z-base-32/base32/DESIGN>

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn-at-cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
