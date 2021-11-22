package Crypt::Perl::ECDSA::EC::Point;

use strict;
use warnings;

#----------------------------------------------------------------------
# NOTE TO SELF: This module’s internal coordinates are
# homogeneous/projective coordinates, not Cartesian.
#----------------------------------------------------------------------

use Crypt::Perl::BigInt ();

my ($bi1, $bi2, $bi3);

END {
    undef $bi1, $bi2, $bi3;
}

sub new_infinity {
    my ($class) = @_;

    return $class->new( undef, undef );
}

#$curve is ECCurve
#$x and $y are “ECFieldElement”
#$z isa bigint (?)
sub new {
    my ($class, $curve, $x, $y, $z) = @_;

    $bi1 ||= Crypt::Perl::BigInt->new(1);
    $bi2 ||= Crypt::Perl::BigInt->new(2);
    $bi3 ||= Crypt::Perl::BigInt->new(3);

    my $self = {
        curve => $curve,
        x => $x,
        y => $y,

        # Generally z won’t be given since we expect
        # Cartesian coordinates as input. But accepting
        # z allows this constructor to receive Jacobi
        # coordinates as well.
        z => $z || $bi1->copy(),

        zinv => undef,
    };

    return bless $self, $class;
}

sub is_infinity {
    my ($self) = @_;

    return 1 if !defined $self->{'x'} && !defined $self->{'y'};

    return( ($self->{'z'}->is_zero() && !$self->{'y'}->to_bigint()->is_zero()) || 0 );
}

#returns ECFieldElement (Cartesian)
sub get_x {
    my ($self) = @_;

    return $self->_get_x_or_y('x');
}

#returns ECFieldElement (Cartesian)
#Used in key generation (not signing … ?)
sub get_y {
    my ($self) = @_;

    return $self->_get_x_or_y('y');
}

sub _get_x_or_y {
    my ($self, $to_get) = @_;

    if (!defined $self->{'zinv'}) {
        $self->{'zinv'} = $self->{'z'}->copy()->bmodinv($self->{'curve'}{'q'});
    }

    return $self->{'curve'}->from_bigint(
        $self->{$to_get}->to_bigint()->copy()->bmul($self->{'zinv'})->bmod($self->{'curve'}{'q'})
    );
}

sub twice {
    my ($self) = @_;

    return $self if $self->is_infinity();

    #if ($self->{'y'}->to_bigint()->signum() == 0) {
    #    return $self->{'curve'}->get_infinity();
    #}

    my $x1 = $self->{'x'}->to_bigint();
    my $y1 = $self->{'y'}->to_bigint();

    my $y1z1 = $y1->copy()->bmul($self->{'z'});

    my $y1sqz1 = $y1z1->copy()->bmul($y1)->bmod($self->{'curve'}{'q'});

    my $a = $self->{'curve'}{'a'};

    # w = 3 * x1^2 + a * z1^2
    #var w = x1.square().multiply(THREE);
    my $w = $x1->copy()->bpow($bi2)->bmul($bi3);

    if (!$a->is_zero()) {
        #$w += ($self->{'z'} ** 2) * $a;
        $w->badd( $a->copy()->bmul( $self->{'z'} )->bmul($self->{'z'}) );
    }

    $w->bmod($self->{'curve'}{'q'});

    # x3 = 2 * y1 * z1 * (w^2 - 8 * x1 * y1^2 * z1)
    #var x3 = w.square().subtract(x1.shiftLeft(3).multiply(y1sqz1)).shiftLeft(1).multiply(y1z1).mod(this.curve.q);

    my $x3 = $w->copy()->bmuladd( $w, $y1sqz1->copy()->bmul($x1)->blsft($bi3)->bneg() )->bmul($bi2)->bmul($y1z1);
    #my $x3 = 2 * $y1z1 * (($w ** 2) - ($x1 << 3) * $y1sqz1);
    #my $x3 = ($w ** 2) - (($x1 << 3) * $y1sqz1);
    #$x3 = $x3 << 1;
    #$x3 *= $y1z1;

    # y3 = 4 * y1^2 * z1 * (3 * w * x1 - 2 * y1^2 * z1) - w^3
    #var y3 = w.multiply(THREE).multiply(x1).subtract(y1sqz1.shiftLeft(1)).shiftLeft(2).multiply(y1sqz1).subtract(w.square().multiply(w)).mod(this.curve.q);
    #my $y3 = 4 * $y1sqz1 * (3 * $w * $x1 - 2 * $y1sqz1) - ($w ** 3);

    my $y3 = $y1sqz1->copy()->blsft($bi2);

    $y3->bmuladd(

        #We don’t need y1sqz1 anymore
        $w->copy()->bmul($bi3)->bmuladd($x1, $y1sqz1->blsft($bi1)->bneg()),

        #Don’t need $w anymore
        $w->bpow($bi3)->bneg(),
    );

    #// z3 = 8 * (y1 * z1)^3
    #var z3 = y1z1.square().multiply(y1z1).shiftLeft(3).mod(this.curve.q);
    #my $z3 = ($y1z1 ** 3) << 3;
    my $z3 = $y1z1->bpow($bi3)->blsft($bi3);  #don’t need y1z1 anymore

    #In original JS logic
    $_->bmod($self->{'curve'}{'q'}) for ($x3, $y3, $z3);

    #return new ECPointFp(this.curve, this.curve.fromBigInteger(x3), this.curve.fromBigInteger(y3), z3);
    return (ref $self)->new(
        $self->{'curve'},
        $self->{'curve'}->from_bigint($x3),
        $self->{'curve'}->from_bigint($y3),
        $z3,
    );
}

#XXX clear
sub dump {
    my ($self, $label) = @_;

    $label = q<> if !defined $label;

    printf "$label.x: %s\n", $self->{'x'}->to_bigint()->as_hex();
    printf "$label.y: %s\n", $self->{'y'}->to_bigint()->as_hex();
    printf "$label.z: %s\n", $self->{'z'}->as_hex();
}

sub multiply {
    my ($self, $k) = @_;

    if ($self->is_infinity()) {
        return $self;
    }

    # “Montgomery ladder” algorithm taken from Wikipedia:
    #
    # R0 ← 0
    # R1 ← P
    # for i from m downto 0 do
    #     if di = 0 then
    #         R1 ← point_add(R0, R1)
    #         R0 ← point_double(R0)
    #     else
    #         R0 ← point_add(R0, R1)
    #         R1 ← point_double(R1)
    # return R0
    #
    # This thwarts the timing attacks that can recover private keys
    # by running the standard “double-and-add” algorithm over and over
    # and analyzing response times.

    my $r0 = ref($self)->new_infinity();
    my $r1 = $self;

    for my $i ( reverse( 0 .. ($k->bit_length() - 1) ) ) {
        if ($k->test_bit($i)) {
            $r0 = $r0->add($r1);
            $r1 = $r1->twice();
        }
        else {
            $r1 = $r0->add($r1);
            $r0 = $r0->twice();
        }
    }

    return $r0;
}

#$b isa ECPoint
sub add {
    my ($self, $b) = @_;
#$b->dump('$b');

    #if(this.isInfinity()) return b;
    #if(b.isInfinity()) return this;

    return $b if $self->is_infinity();
    return $self if $b->is_infinity();

    #// u = Y2 * Z1 - Y1 * Z2
    #var u = b.y.toBigInteger().multiply(this.z).subtract(this.y.toBigInteger().multiply(b.z)).mod(this.curve.q);
    my $u = $b->{'y'}->to_bigint()->copy()->bmuladd(
        $self->{'z'},
        $self->{'y'}->to_bigint()->copy()->bneg()->bmul($b->{'z'}),
    );
# $b->{'z'};

    #// v = X2 * Z1 - X1 * Z2
    #var v = b.x.toBigInteger().multiply(this.z).subtract(this.x.toBigInteger().multiply(b.z)).mod(this.curve.q);
    my $v = $b->{'x'}->to_bigint()->copy()->bmuladd(
        $self->{'z'},
        $self->{'x'}->to_bigint()->copy()->bneg()->bmul($b->{'z'}),
    );


    $_->bmod($self->{'curve'}{'q'}) for ($u, $v);
#print "u: " . $u->as_hex() . $/;
#print "v: " . $v->as_hex() . $/;
    #if(BigInteger.ZERO.equals(v)) {
    #    if(BigInteger.ZERO.equals(u)) {
    #        return this.twice(); // this == b, so double
    #    }
	#return this.curve.getInfinity(); // this = -b, so infinity
    #}
    if ($v->is_zero()) {
        if ($u->is_zero()) {
            return $self->twice();
        }

        return $self->{'curve'}->get_infinity();
    }

    #var THREE = new BigInteger("3");
    #var x1 = this.x.toBigInteger();
    #var y1 = this.y.toBigInteger();
    #var x2 = b.x.toBigInteger();
    #var y2 = b.y.toBigInteger();
    my ($x1, $y1, $z1) = @{$self}{ qw( x y z ) };
    my ($x2, $y2, $z2) = @{$b}{ qw( x y z ) };

    $_ = $_->to_bigint() for ($x1, $y1, $x2, $y2);

    #var v2 = v.square();
    #var v3 = v2.multiply(v);
    #var x1v2 = x1.multiply(v2);
    #var zu2 = u.square().multiply(this.z);

    my $v2 = $v->copy()->bmul($v);
    my $v3 = $v->copy()->bmul($v2);

    my $x1v2 = $x1->copy()->bmul($v2);
    my $zu2 = $u->copy()->bmul($u)->bmul($self->{'z'});
#use Data::Dumper;
#print Dumper( map { $_->as_hex() } $u, $v, $x1, $y1, $z1, $x2, $y2, $z2, $v2, $v3, $x1v2, $zu2 );

    #// x3 = v * (z2 * (z1 * u^2 - 2 * x1 * v^2) - v^3)
    #var x3 = zu2.subtract(x1v2.shiftLeft(1)).multiply(b.z).subtract(v3).multiply(v).mod(this.curve.q);
    #my $x3 = $v * ($z2 * ($z1 * ($u ** 2) - 2 * $x1 * ($v ** 2)) - ($v ** 3));
    my $x3 = $u->copy()->bmul($u);
    $x3->bmuladd( $z1, $x1->copy()->blsft($bi1)->bneg()->bmul($v)->bmul($v) );
    $x3->bmuladd( $z2, $v->copy()->bpow($bi3)->bneg() );
    $x3->bmul($v);

    #// y3 = z2 * (3 * x1 * u * v^2 - y1 * v^3 - z1 * u^3) + u * v^3
    #var y3 = x1v2.multiply(THREE).multiply(u).subtract(y1.multiply(v3)).subtract(zu2.multiply(u)).multiply(b.z).add(u.multiply(v3)).mod(this.curve.q);
    #my $y3 = $z2 * (3 * $x1 * $u * $v2 - $y1 * $v3 - $z1 * ($u ** 3)) + $u * $v3;
    my $y3 = $u->copy()->bmul($bi3)->bmul($x1);
    $y3->bmuladd($v2, $y1->copy()->bmul($v3)->bneg());      #no more y1 after this
    $y3->bsub( $u->copy()->bpow($bi3)->bmul($z1) );

    $y3->bmuladd( $z2, $u->bmul($v3) );             #we don’t need $u anymore

    #// z3 = v^3 * z1 * z2
    #var z3 = v3.multiply(this.z).multiply(b.z).mod(this.curve.q);
    my $z3 = $v3->bmul($z1)->bmul($z2);

    $_->bmod($self->{'curve'}{'q'}) for ($x3, $y3, $z3);

    return (ref $self)->new(
        $self->{'curve'},
        $self->{'curve'}->from_bigint($x3),
        $self->{'curve'}->from_bigint($y3),
        $z3,
    );
}

1;
