package Crypto::ECC::Point;
$Crypto::ECC::Point::VERSION = '0.004';
use Moo;

extends(my $CurveFp = "Crypto::ECC::CurveFp");

has x     => ( is => 'ro' );
has y     => ( is => 'ro' );
has order => ( is => 'ro' );

around BUILDARGS => __PACKAGE__->BUILDARGS_val2gmp(qw(x y order));

sub infinity { 'infinity' }

sub cmp {
    my ( $class, $p1, $p2 ) = @_;

    if ( !$p1->isa($class) ) {
        if ( $p2->isa($class) ) {
            return 1;
        }
        if ( !$p2->isa($class) ) {
            return 0;
        }
    }

    if ( !$p2->isa($class) ) {
        if ( $p1->isa($class) ) {
            return 1;
        }
        if ( !$p1->isa($class) ) {
            return 0;
        }
    }

    return 1 if ( $p1->x <=> $p2->x ) != 0;

    return 1 if ( $p1->y <=> $p2->y ) != 0;

    return $class->next( $p1, $p2 );
}

sub add {
    my ( $class, $p1, $p2 ) = @_;

    if ( $class->cmp( $p2, $class->infinity ) == 0 && $p1->isa($class) ) {
        return $p1;
    }

    if ( $class->cmp( $p1, $class->infinity ) == 0 && $p2->isa($class) ) {
        return $p2;
    }

    if (   $class->cmp( $p1, $class->infinity ) == 0
        && $class->cmp( $p2, $class->infinity ) == 0 )
    {
        return $class->infinity;
    }

    if ( $CurveFp->cmp( $p1, $p2 ) != 0 ) {
        die "The Elliptic Curves do not match.";
    }

    if ( ( ( $p1->x <=> $p2->x ) % $p1->prime ) == 0 ) {
        if ( ( ( $p1->y + $p2->y ) % $p1->prime ) == 0 ) {
            return $class->infinity;
        }
        else {
            return $class->double($p1);
        }
    }

    my $p = $p1->prime;

    my $l = ( $p2->y - $p1->y ) * ( $p2->x - $p1->x )->bmodinv($p);

    my $x3 = ( ( ( $l**2 ) - $p1->x ) - $p2->x ) % $p;

    my $y3 = ( ( $l * ( $p1->x - $x3 ) ) - $p1->y ) % $p;

    my $p3 = $p1->copy( x => $x3, y => $y3 );

    return $p3;
}

sub mul {
    my ( $class, $x2, $p1 ) = @_;

    my $e = $x2;

    if ( $class->cmp( $p1, $class->infinity ) == 0 ) {
        return $class->infinity;
    }

    if ( defined $p1->order ) {
        $e %= $p1->order;
    }

    if ( ( $e <=> 0 ) == 0 ) {
        return $class->infinity;
    }

    return if ( $e <=> 0 ) <= 0;

    my $e3 = $e * 3;

    my $negative_self = $p1->negative;

    my $i = $class->leftmost_bit($e3) / 2;

    my $result = $p1;

    while ( ( $i <=> 1 ) > 0 ) {
        $result = $class->double($result);

        my $e3bit = ( $e3 & $i ) <=> 0;
        my $ebit  = ( $e & $i ) <=> 0;

        if ( $e3bit != 0 && $ebit == 0 ) {
            $result = $class->add( $result, $p1 );
        }
        elsif ( $e3bit == 0 && $ebit != 0 ) {
            $result = $class->add( $result, $negative_self );
        }

        $i /= 2;
    }

    return $result;
}

sub double {
    my ( $class, $p1 ) = @_;

    my $p = $p1->prime;
    my $a = $p1->a;

    my $inverse = ( 2 * $p1->y )->bmodinv($p);

    my $three_x2 = 3 * ( $p1->x**2 );

    my $l = ( ( $three_x2 + $a ) * $inverse ) % $p;

    my $x3 = ( ( $l**2 ) - ( 2 * $p1->x ) ) % $p;

    my $y3 = ( ( $l * ( $p1->x - $x3 ) ) - $p1->y ) % $p;

    if ( ( 0 <=> $y3 ) > 0 ) {
        $y3 = $p + $y3;
    }

    my $p3 = $p1->copy( x => $x3, y => $y3 );

    return $p3;
}

sub leftmost_bit {
    my ( $class, $x ) = @_;

    return if ( $x <=> 0 ) < 1;

    my $result = Math::BigInt->new(1);

    while ( ( $result <=> $x ) < 0 || ( $result <=> $x ) == 0 ) {
        $result *= 2;
    }

    $result /= 2;

    return $result;
}

sub negative {
    my ($p) = @_;
    return $p->copy( y => 0 - $p->y );
}

1;
