#--------------------------------------------------------------------#
# Crypt::GOST_PP
#       Date Written:   10-Dec-2001 12:33:55 PM
#       Last Modified:  26-Feb-2002 10:47:28 AM
#       Author:         Kurt Kincaid (sifukurt@yahoo.com)
#       Copyright (c) 2002, Kurt Kincaid
#           All Rights Reserved.
#
#       This is free software and may be modified and/or
#       redistributed under the same terms as Perl itself.
#--------------------------------------------------------------------#

package Crypt::GOST_PP;
use integer;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw();

use strict;
no strict 'refs';

use vars qw( @b @t @R @S @h @o @K $VERSION );

$VERSION = "1.10";

sub new {
    my ( $argument, $pp ) = @_;
    Setup( $pp );
    my $class = ref ( $argument ) || $argument;
    my $self = {};
    bless $self, $class;
    return $self;
} 

sub encrypt {
    my ( $self, $text ) = @_;
    return GOST( $text );
}

sub decrypt {
    my ( $self, $text ) = @_;
    return GOST( $text, 1 );
}

sub GOST {
    my ( $v, $w, $a, $q, $c, $out, $self );
    my ( $e, $d ) = @_;
    @h = 0 .. 7;
    @o = reverse @h;
    while ( $a < length $e ) {
        $v = N( $e, $a );
        $w = N( $e, ( $a += 8 ) - 4 );
        grep $q++ % 2 ? $v ^= F( $w + $K[ $_ ] ) : ( $w ^= F( $v + $K[ $_ ] ) ), $d ? ( @h, ( @o ) x 3 ) : ( ( @h ) x 3, @o );
        $out .= pack "N2", $w, $v;
    }
    return $out;
}

sub F {
    my $u = 0;
    grep $u |= $S[ $_ ][ $_[ 0 ] >> $_ * 4 & 15 ] << $_ * 4, reverse 0 .. 7;
    return $u << 11 | $u >> 21;
}

sub R {
    return int( rand( shift ) );
}

sub N {
    return vec $_[ 0 ], $_[ 1 ] / 4, 32;
}

sub Setup {
    my $p = shift;
    my ( $s, $i, $c );
    for ( $i = 0; $i < length $p; $i += 4 ) {
        srand( $s ^= N( $p, $i ) );
    }
    @b = @t = 0 .. 15;
    while ( $c < 8 ) {
        grep { push @b, splice @b, R( 9 ), 5 } @t;
        $R[ $c ] = R( 2**32 );
        @{ $S[ $c++ ] } = @b;
    }

}

1;
__END__

=head1 NAME

Crypt::GOST_PP - Pure Perl implementation of the GOST encryption algorithm

=head1 SYNOPSIS

  use Crypt::GOST_PP;
  $ref = Crypt::GOST_PP->new( $passphrase );
  $encrypted = $ref->encrypt( $plaintext );
  
  $ref2 = Crypt::GOST_PP->new( $passphrase );
  $decrypted = $ref2->decrypt( $encrypted );

=head1 DESCRIPTION

GOST is a 64-bit symmectric block cipher with a 256-bit key, from the
former Soviet Union.

It is important to note that there are (or have been) several other GOST
encryption modules for perl. This version is in no way intended to
supersede any other such implementations, specifically Crypt::GOST. The
purpose for writing this module was that I do a great deal of work on
Win32 systems, and I have been unsuccessful in my attempts to get
Crypt::GOST to install correctly in that environment. A previous version
of Crypt::GOST, v0.41, was also a pure perl implementation, but it
lacked documentation, and as such it was more difficult to use than one
would prefer. As a result of these two things, I wanted to write a pure
perl implementation, with requisite documentation, that will run
regardless of the OS.

Much of the core logic of Crypt::GOST_PP was originally based on Vipul
Ved Prakash's "GOST in 417 bytes of Perl" L<http://www.vipul.net/gost/>.
The code contained herein has undergone numerous revisions and
modifications since that original diminutive implementation.

=head1 AUTHOR

Kurt Kincaid (sifukurt@yahoo.com)

=head1 SEE ALSO

L<perl>, L<http://www.vipul.net/gost/>

=cut
