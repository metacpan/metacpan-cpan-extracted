#---------------------------------------------------------------------------#
# Crypt::RC5
#       Date Written:   23-Nov-2001 10:47:02 AM
#       Last Modified:  05-Nov-2002 09:52:18 AM
#       Author:    Kurt Kincaid
#       Copyright (c) 2002, Kurt Kincaid
#           All Rights Reserved
#
# NOTICE:  RC5 is a fast block cipher designed by Ronald Rivest
#          for RSA Data Security (now RSA Security) in 1994. It is a
#          parameterized algorithm with a variable block size, a variable
#          key size, and a variable number of rounds. This particular
#          implementation is 32 bit. As such, it is suggested that a minimum
#          of 12 rounds be performed.
#---------------------------------------------------------------------------#

package Crypt::RC5;

use Exporter;
use integer;
use strict;
no strict 'refs';
use vars qw/ $VERSION @EXPORT_OK @ISA @S /;

@ISA       = qw(Exporter);
@EXPORT_OK = qw($VERSION RC5);
$VERSION   = '2.00';

sub new ($$$) {
    my ( $class, $key, $rounds ) = @_;
    my $self = bless {}, $class;
    my @temp = unpack( "C*", $key );
    my $newKey;
    foreach my $temp ( @temp ) {
        $temp = sprintf( "%lx", $temp );
        if ( length( $temp ) < 2 ) {
            $temp = "0" . $temp;
        }
        $newKey .= $temp;
    }
    my @L = unpack "V*", pack "H*x3", $newKey;
    my $T = 0xb7e15163;
    @S = ( M( $T ), map { $T = M( $T + 0x9e3779b9 ) } 0 .. 2 * $rounds );
    my ( $A, $B ) = ( 0, 0 );
    for ( 0 .. 3 * ( @S > @L ? @S : @L ) - 1 ) {
        $A = $S[ $_ % @S ] = ROTL( 3, M( $S[ $_ % @S ] ) + M( $A + $B ) );
        $B = $L[ $_ % @L ] = ROTL( M( $A + $B ), M( $L[ $_ % @L ] ) + M( $A + $B ) );
    }
    return $self;
}

sub encrypt ($$) {
    my ( $self, $text ) = @_;
    return $self->RC5( $text );
}

sub decrypt ($$) {
    my ( $self, $text ) = @_;
    return $self->RC5( $text, 1 );
}

sub decrypt_iv ($$$) {
    my ( $self, $text, $iv ) = @_;
    die "iv must be 8 bytes long" if length( $iv ) != 8;

    my @ivnum = unpack( 'C*', $iv . $text );
    my @plain = unpack( 'C*', $self->RC5( $text, 1 ) );
    for ( 0 .. @plain ) { $plain[ $_ ] ^= $ivnum[ $_ ]; }
    return pack( 'C*', @plain );
}

sub RC5 ($$) {
    my ( $self, $text, $decrypt ) = @_;
    my $last;
    my $processed = '';
    while ( $text =~ /(.{8})/gs ) {
        $last = $';
        $processed .= Process( $1, $decrypt );
    }
    if ( length( $text ) % 8 ) {
        $processed .= Process( $last, $decrypt );
    }
    return $processed;
}

sub M ($) {
    return unpack( 'V', pack( 'V', pop ) );
}

sub ROTL ($$) {
    my ( $x, $n );
    ( $x = pop ) << ( $n = 31 & pop ) | 2**$n - 1 & $x >> 32 - $n;
}

sub ROTR ($$) {
    ROTL( 32 - ( 31 & shift ), shift );
}

sub Process ($$) {
    my ( $block, $decrypt ) = @_;
    my ( $A, $B ) = unpack "V2", $block . "\0" x 3;
    $_ = '$A = M( $A+$S[0] );$B = M( $B+$S[1] )';
    $decrypt || eval;
    for ( 1 .. @S - 2 ) {
        if ( $decrypt ) {
            $B = $A ^ ROTR( $A, M( $B - $S[ @S - $_ ] ) );
        } else {
            $A = M( $S[ $_ + 1 ] + ROTL( $B, $A ^ $B ) );
        }
        $A ^= $B ^= $A ^= $B;
    }
    $decrypt && ( y/+/-/, eval );
    return pack "V2", $A, $B;
}

1;
__END__


=head1 NAME

Crypt::RC5 - Perl implementation of the RC5 encryption algorithm.

=head1 SYNOPSIS

  use Crypt::RC5;

  $ref = Crypt::RC5->new( $key, $rounds );
  $ciphertext = $ref->encrypt( $plaintext );

  $ref2 = Crypt::RC5->new( $key, $rounds );
  $plaintext2 = $ref2->decrypt( $ciphertext );

=head1 DESCRIPTION

RC5 is a fast block cipher designed by Ronald Rivest for RSA Data Security (now RSA Security) in 1994. It is a parameterized algorithm with a variable block size, a variable key size, and a variable number of rounds. This particular implementation is 32 bit. As such, it is suggested that a minimum of 12 rounds be performed.

Core logic based on "RC5 in 6 lines of perl" at http://www.cypherspace.org

=head1 AUTHOR

Kurt Kincaid (sifukurt@yahoo.com)

Ronald Rivest for RSA Security, Inc.

=head1 SEE ALSO

L<perl>, L<http://www.cypherspace.org>, L<http://www.rsasecurity.com>

=cut

