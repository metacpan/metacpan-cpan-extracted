package Crypt::Perl::ECDSA::Math;

#Math that’s really only useful for us in the context of ECDSA.

use strict;
use warnings;

use Crypt::Perl::BigInt ();

#A port of libtomcrypt’s mp_sqrtmod_prime().
#The return value will be a Crypt::Perl::BigInt reference.
#
#See also implementations at:
#   https://rosettacode.org/wiki/Tonelli-Shanks_algorithm
#
#See “Handbook of Applied Cryptography”, algorithms 3.34 and 3.36,
#for reference.
sub tonelli_shanks {
    my ($n, $p) = @_;

    _make_bigints($n, $p);

    return 0 if $n->is_zero();

    die "prime must be odd" if $p->beq(2);

    if (jacobi($n, $p) == -1) {
        die sprintf( "jacobi(%s, %s) must not be -1", $n->as_hex(), $p->as_hex());
    }

    #HAC 3.36
    if ( $p->copy()->bmod(4)->beq(3) ) {
        return $n->copy()->bmodpow( $p->copy()->binc()->brsft(2), $p );
    }

    my $Si = 0;
    my $Q = $p->copy()->bdec();
    while ( $Q->is_even() ) {
        $Q->brsft(1);
        $Si++;
    }

    my $Z = Crypt::Perl::BigInt->new(2);
    while (1) {
        last if jacobi($Z, $p) == -1;
        $Z->binc();
    }

    my $C = $Z->copy()->bmodpow($Q, $p);

    my $t1 = $Q->copy()->binc()->brsft(1);

    my $R = $n->copy()->bmodpow($t1, $p);

    my $T = $n->copy()->bmodpow($Q, $p);

    my $Mi = $Si;

    while (1) {
        my $i = 0;

        $t1 = $T->copy();

        while (1) {
            last if $t1->is_one();
            $t1->bmodpow(2, $p);
            $i++;
        }

        return $R if $i == 0;

        $t1 = _bi2()->bmodpow($Mi - $i - 1, $p);

        $t1 = $C->bmodpow($t1, $p);

        $C = $t1->copy()->bmodpow(2, $p);
        $R->bmul($t1)->bmod($p);
        $T->bmul($C)->bmod($p);
        $Mi = $i;
    }
}

my $BI2;
sub _bi2 {
    return( ($BI2 ||= Crypt::Perl::BigInt->new(2))->copy() );
}

#cf. mp_jacobi()
#
#The return value is a plain scalar (-1, 0, or 1).
#
sub jacobi {
    my ($a, $n) = @_;

    _make_bigints($a, $n);

    my $ret = 1;

    #This loop avoids deep recursion.
    while (1) {
        my ($ret2, $help) = _jacobi_backend($a, $n);

        $ret *= $ret2;

        last if !$help;

        ($a, $n) = @$help;
    }

    return $ret;
}

sub _make_bigints {
    ref || ($_ = _bi($_)) for @_;
}

sub _jacobi_backend {
    my ($a, $n) = @_;

    die "“a” can’t be negative!" if $a < 0;

    die "“n” must be positive!" if $n <= 0;

    #step 1
    if ($a->is_zero()) {
        return $n->is_one() ? 1 : 0;
    }

    #step 2
    return 1 if $a->is_one();

    #default
    my $si = 0;

    my $a1 = $a->copy();

    #Determine $a1’s greatest factor that is a power of 2,
    #which is the number of lest-significant 0 bits.
    my $ki = _count_lsb($a1);

    $a1->brsft($ki);

    #step 4
    if (($ki & 1) == 0) {
        $si = 1;
    }
    else {
        my $residue = $n->copy()->band(7)->numify();

        if ( $residue == 1 || $residue == 7 ) {
            $si = 1;
        }
        elsif ( $residue == 3 || $residue == 5 ) {
            $si = -1;
        }
    }

    #step 5
    if ( $n->copy()->band(3)->beq(3) && $a1->copy()->band(3)->beq(3) ) {
        $si = 0 - $si;
    }

    return $si if $a1->is_one();

    my $p1 = $n->copy()->bmod($a1);

    return( $si, [$p1, $a1] );
}

#cf. mp_cnt_lsb()
sub _count_lsb {
    my ($num) = @_;

    #sprintf('%b',$num) =~ m<(0*)\z>;
    $num->as_bin() =~ m<(0*)\z>;

    return length $1;
}

sub _bi { return Crypt::Perl::BigInt->new(@_) }

1;
