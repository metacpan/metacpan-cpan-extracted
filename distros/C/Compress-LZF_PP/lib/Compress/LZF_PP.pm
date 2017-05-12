package Compress::LZF_PP;
use strict;
use warnings;
our $VERSION = '0.33';
our @ISA     = qw(Exporter);
our @EXPORT  = qw(decompress);

my $DEBUG = 0;

sub decompress {
    my $in_data  = shift;
    my $in_len   = length($in_data);
    my $out_data = '';
    my $out_len  = 0;

    my $iidx = 0;
    my $oidx = 0;

    my $length0 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
    if ( $length0 == 0 ) {
        return substr( $in_data, 1, $in_len - 1 );
    } elsif ( !( $length0 & 0x80 ) ) {
        $out_len = $length0 & 0xff;
    } elsif ( !( $length0 & 0x20 ) ) {
        my $length1 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        $out_len = ( $out_len << 6 ) | ( $length1 & 0x3f );
    } elsif ( !( $length0 & 0x10 ) ) {
        my $length1 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length2 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        $out_len = $length0 & 0x1f;
        $out_len = ( $out_len << 6 ) | ( $length1 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length2 & 0x3f );
    } elsif ( !( $length0 & 0x08 ) ) {
        my $length1 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length2 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length3 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        $out_len = $length0 & 0x1f;
        $out_len = ( $out_len << 6 ) | ( $length1 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length2 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length3 & 0x3f );
    } elsif ( !( $length0 & 0x04 ) ) {
        my $length1 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length2 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length3 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length4 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        $out_len = $length0 & 0x1f;
        $out_len = ( $out_len << 6 ) | ( $length1 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length2 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length3 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length4 & 0x3f );
    } elsif ( !( $length0 & 0x02 ) ) {
        my $length1 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length2 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length3 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length4 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        my $length5 = unpack( 'C', substr( $in_data, $iidx++, 1 ) );
        $out_len = $length0 & 0x1f;
        $out_len = ( $out_len << 6 ) | ( $length1 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length2 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length3 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length4 & 0x3f );
        $out_len = ( $out_len << 6 ) | ( $length5 & 0x3f );
    } else {
        die "Unsupported length";
    }

    while ( $iidx < $in_len ) {
        my $ctrl = unpack( 'C', substr( $in_data, $iidx++, 1 ) );

        warn "$iidx, $oidx control $ctrl [[$out_data]]" if $DEBUG;

        if ( $ctrl < ( 1 << 5 ) ) {
            $ctrl++;
            my $toadd = substr( $in_data, $iidx, $ctrl );
            warn "  literal run $ctrl [$toadd]" if $DEBUG;
            $out_data .= $toadd;
            $oidx += $ctrl;
            $iidx += $ctrl;
        } else {
            my $len = $ctrl >> 5;
            my $reference = ( $oidx - ( ( $ctrl & 0x1f ) << 8 ) - 1 );
            if ( $len == 7 ) {
                $len += unpack( 'C', substr( $in_data, $iidx++, 1 ) );
            }
            $reference -= unpack( 'C', substr( $in_data, $iidx++, 1 ) );
            warn "  back reference $reference $len" if $DEBUG;
            $oidx += $len - 3;
            $len  += 3;

            while ( --$len != 0 ) {
                $out_data .= substr( $out_data, $reference++, 1 );
            }
        }
    }
    return $out_data;
}

1;

__END__

=head1 NAME

Compress::LZF_PP - A pure-Perl LZF decompressor

=head1 SYNOPSIS

  use Compress::LZF_PP;
  my $decompressed = decompress($compressed);
 
=head1 DESCRIPTION

This module is a pure-Perl LZF decompressor. LZF is an extremely fast 
(not that much slower than a pure memcpy) compression algorithm.
It is implemented in XS in L<Compress::LZF> module. This is a pure-Perl
LZF decompressor. Being pure-Perl, it is about 50x slower than 
L<Compress::LZF>. Only use this if you can not use L<Compress::LZF>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or 
modify it under the same terms as Perl itself.
