package App::locket::TextRandomart;

use strict;
use warnings;

my $base = 8;
my %size = (
    y => $base + 1,
    x => $base * 2 + 1,
);

my $palette = " .o+=*BOX@%&#/^SE";
my $palette_cap = -1 + length $palette;

sub mn ($$) { return $_[0] < $_[1] ? $_[0] : $_[1] }
sub mx ($$) { return $_[0] > $_[1] ? $_[0] : $_[1] }

use POSIX qw/ floor /;

sub randomart {
    my $self = shift;
    my %arguments;
    if ( @_ == 1 ) {
        $arguments{ digest } = shift;
    }
    else {
        %arguments = @_;
    }

    my $digest = $arguments{ digest };
    return unless $digest; # 0 is not a valid digest, etc.

    my @digest_bytes = unpack 'C*', pack 'H*', $digest;

    my @field;
    {
        my ( $x, $y, $i );
        my %origin;
        $x = $origin{ x } = floor( $size{ x } / 2 );
        $y = $origin{ y } = floor( $size{ y } / 2 );

        $i = 0;
        while( $i < @digest_bytes ) {
            my $byte;
            $byte = $digest_bytes[ $i ];
            my $j = 0;
            while ( $j < 4 ) {
                $x += ( $byte & 0x1 ) ? 1 : -1;
                $y += ( $byte & 0x2 ) ? 1 : -1;
                $x = mx( $x, 0 );
                $y = mx( $y, 0 );
                $x = mn( $x, $size{ x } - 1 );
                $y = mn( $y, $size{ y } - 1 );
                $field[ $x ][ $y ] ||= 0;
                if ( $field[ $x ][ $y ] < ( $palette_cap - 2 ) ) {
                    $field[ $x ][ $y ] += 1;
                }
                $byte = $byte >> 2;
                $j += 1;
            }
            $i += 1;
        }

        $field[ $origin{ x } ][ $origin{ y } ] = $palette_cap - 1;
        $field[ $x ][ $y ] = $palette_cap;
    }

    my @art;

    push @art, '+', ( '-' x $size{ x } ), '+';
    push @art, "\n";

    my $y = 0;
    while ( $y < $size{ y } ) {
        push @art, '|';
        my $x = 0;
        while ( $x < $size{ x } ) {
            push @art, substr $palette, mn( $field[ $x ][ $y ] || 0, $palette_cap ), 1;
            $x += 1;
        }
        push @art, '|';
        push @art, "\n";
        $y += 1;
    }

    push @art, '+', ( '-' x $size{ x } ), '+';

    return join '', @art;
}

1;
