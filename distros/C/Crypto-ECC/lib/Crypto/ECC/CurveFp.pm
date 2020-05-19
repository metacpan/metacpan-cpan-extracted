package Crypto::ECC::CurveFp;
$Crypto::ECC::CurveFp::VERSION = '0.004';
use Moo;

with "Object::GMP";

has a     => ( is => 'ro' );
has b     => ( is => 'ro' );
has prime => ( is => 'ro' );

around BUILDARGS => __PACKAGE__->BUILDARGS_val2gmp(qw(prime));

sub cmp {
    my ( $class, $p1, $p2 ) = @_;

    my $same;

    return 1 if ( $p1->a <=> $p2->a ) != 0;

    return 1 if ( $p1->b <=> $p2->b ) != 0;

    return ( $p1->prime <=> $p2->prime ) != 0;
}

1;
