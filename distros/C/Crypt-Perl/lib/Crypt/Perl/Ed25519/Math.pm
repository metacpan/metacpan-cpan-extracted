package Crypt::Perl::Ed25519::Math;

use strict;
use warnings;

sub reduce {
    my ($r) = @_;

    my @x;

    for my $i ( 0 .. 63 ) {
        $x[$i] = $r->[$i];
        $r->[$i] = 0;
    }

    modL( $r, \@x );

    return;
}

# p and q are arrays of arrays; s is an array of numbers
sub scalarmult {
    my ($p, $q, $s) = @_;

    @{$p}[0 .. 3] = ( [ gf0() ], [ gf1() ], [ gf1() ], [ gf0() ] );

    my $b;

    for my $i ( reverse( 0 .. 255 ) ) {
        $b = ( $s->[ ( $i >> 3 ) | 0 ] >> ($i & 7) ) & 1;
        _cswap( $p, $q, $b );
        add( $q, $p );
        add( $p, $p );
        _cswap( $p, $q, $b );
    }

    return;
}

# p is an array of arrays; s is an array of numbers
sub scalarbase {
    my ($p, $s) = @_;

    my @q = ( [ X() ], [ Y() ], [ gf1() ], [ gf0() ] );

    _M( $q[3], [X()], [Y()] );

    scalarmult($p, \@q, $s);
}

# p is an array of arrays
sub pack {
    my ($p) = @_;

    my $tx = [ gf0() ];
    my $ty = [ gf0() ];
    my $zi = [ gf0() ];

    _inv25519( $zi, $p->[2] );

    _M( $tx, $p->[0], $zi );
    _M( $ty, $p->[1], $zi );

    my $r = _pack25519($ty);

    $r->[31] ^= (_par25519($tx) << 7);

    return $r;
}

sub add {
    my ($p, $q) = @_;

    my $a = [ gf0() ];
    my $b = [ gf0() ];
    my $c = [ gf0() ];
    my $d = [ gf0() ];
    my $e = [ gf0() ];
    my $f = [ gf0() ];
    my $g = [ gf0() ];
    my $h = [ gf0() ];
    my $t = [ gf0() ];

    _Z($a, $p->[1], $p->[0]);
    _Z($t, $q->[1], $q->[0]);
    _M($a, $a, $t);
    _A($b, $p->[0], $p->[1]);
    _A($t, $q->[0], $q->[1]);
    _M($b, $b, $t);
    _M($c, $p->[3], $q->[3]);
    _M($c, $c, [ D2() ]);
    _M($d, $p->[2], $q->[2]);
    _A($d, $d, $d);
    _Z($e, $b, $a);
    _Z($f, $d, $c);
    _A($g, $d, $c);
    _A($h, $b, $a);

    _M($p->[0], $e, $f);
    _M($p->[1], $h, $g);
    _M($p->[2], $g, $f);
    _M($p->[3], $e, $h);
}

sub modL {
    my ($r, $x) = @_;

    my ($k);

    for my $i ( reverse( 32 .. 63 ) ) {
        my $carry = 0;

        my ($j, $k);

        for (
            ($j = $i - 32), ($k = $i - 12);
            $j < $k;
            ++$j
        ) {
            $x->[$j] += $carry - 16 * $x->[$i] * (L())[$j - ($i - 32)];

            # originally “>> 8” rather than “/ 256”;
            $carry = _floor( ($x->[$j] + 128) / 256 );

            $x->[$j] -= $carry * 256;
        }

        $x->[$j] += $carry;
        $x->[$i] = 0;
    }

    my $carry = 0;

    # In Perl, -98 >> 4 = 1152921504606846969. :-<
    my $x31_rshift_4 = _floor( $x->[31] / 16 );

    for my $j ( 0 .. 31 ) {
        $x->[$j] += $carry - $x31_rshift_4 * (L())[$j];

        # originally “>> 8” rather than “/ 256”; we also need floor
        $carry = _floor( $x->[$j] / 256 );

        $x->[$j] &= 255;
    }

    $x->[$_] -= $carry * (L())[$_] for 0 .. 31;

    for my $i ( 0 .. 31 ) {
        $x->[$i + 1] += $x->[$i] >> 8;
        $r->[$i] = $x->[$i] & 255;
    }

    return;
}

use constant gf0 => (0) x 16;

#----------------------------------------------------------------------

use constant gf1 => ( 1, (0) x 15 );

use constant L => (
    0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58,
    0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14,
    (0) x 15, 0x10,
);

use constant D2 => (
    0xf159, 0x26b2, 0x9b94, 0xebd6, 0xb156, 0x8283, 0x149a, 0x00e0,
    0xd130, 0xeef3, 0x80f2, 0x198e, 0xfce7, 0x56df, 0xd9dc, 0x2406,
);

use constant X => (
    0xd51a, 0x8f25, 0x2d60, 0xc956, 0xa7b2, 0x9525, 0xc760, 0x692c,
    0xdc5c, 0xfdd6, 0xe231, 0xc0a4, 0x53fe, 0xcd6e, 0x36d3, 0x2169,
);

use constant Y => (
    0x6658, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666,
    0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666, 0x6666,
);

sub _S { _M( $_[0], $_[1], $_[1] ) }

sub _inv25519 {
    my ($o, $i) = @_;

    my $c = [ @{$i}[0 .. 15] ];

    for my $a ( reverse( 0 .. 253 ) ) {
        _S($c, $c);

        next if $a == 2;
        next if $a == 4;

        _M( $c, $c, $i );
    }

    @{$o}[0 .. 15] = @{$c}[0 .. 15];

    return;
}

sub _pack25519 {
    my ($n) = @_;

    my $b;

    my $o = [];

    my $t = [ @{$n}[0 .. 15] ];

    my $m = [ gf0() ];

    _car25519($t) for 1 .. 3;

    for my $j (0, 1) {
        $m->[0] = $t->[0] - 0xffed;

        for my $i ( 1 .. 14 ) {
            $m->[$i] = $t->[$i] - 0xffff - (($m->[$i - 1] >> 16) & 1);
            $m->[$i - 1] &= 0xffff;
        }

        $m->[15] = $t->[15] - 0x7fff - (($m->[14] >> 16) & 1);

        $b = ($m->[15] >> 16) & 1;

        $m->[14] &= 0xffff;

        _sel25519( $t, $m, 1 - $b );
    }

    for my $i ( 0 .. 15 ) {
        $o->[2 * $i] = $t->[$i] & 0xff;
        $o->[2 * $i + 1] = $t->[$i] >> 8;
    }

    return $o;
}

sub _par25519 {
    my ($a) = @_;

    my $d = _pack25519($a);

    return $d->[0] & 1;
}

# o, a, and b are arrays of numbers
sub _A {
    my ($o, $a, $b) = @_;

    $o->[$_] = $a->[$_] + $b->[$_] for 0 .. 15;

    return;
}

# o, a, and b are arrays of numbers
sub _Z {
    my ($o, $a, $b) = @_;

    $o->[$_] = $a->[$_] - $b->[$_] for 0 .. 15;

    return;
}

# o, a, and b are arrays of numbers
sub _M {
    my ($o, $a, $b) = @_;

    my @t = (0) x 31;

    for my $a_idx ( 0 .. 15 ) {
        $t[$a_idx + $_] += $a->[$a_idx] * $b->[$_] for 0 .. 15;
    }

    # $t->[15] left as-is
    for my $t_idx ( 0 .. 14 ) {
        $t[$t_idx] += 38 * $t[16 + $t_idx];
    }

    my ($c, $v);

    _car25519(\@t);
    _car25519(\@t);

    @{$o}[0 .. 15] = @t[0 .. 15];

    return;
}

sub _car25519 {
    my ($o) = @_;

    my $c = 1;
    my $v;

    for my $o_item ( @{$o}[0 .. 15] ) {
        $v = $o_item + $c + 65535;

        # c = Math.floor(v / 65536)
        $c = int( $v / 65536 );
        $c-- if $v < 0;

        # t0 = v - c * 65536
        $o_item = $v - ($c * 65536);
    }

    $o->[0] += $c - 1 + 37 * ($c - 1);

    return;
}

# p and q are arrays of numbers
sub _sel25519 {
    my ($p, $q, $b) = @_;

    # $b is either 0 or 1.
    my $c = $b && -1;

    for my $i ( 0 .. 15 ) {
        my $t = $c && ($c & signed_xor($p->[$i], $q->[$i]));

        $p->[$i] = signed_xor($p->[$i], $t) if $t;
        $q->[$i] = signed_xor($q->[$i], $t) if $t;
    }
}

# p and q are arrays of arrays
sub _cswap {
    my ($p, $q, $b) = @_;

    for my $i ( 0 .. 3 ) {
        _sel25519( $p->[$i], $q->[$i], $b );
    }
}

# Perl’s ^ operator isn’t signed-savvy,
# so (-60116 ^ 0) = 18446744073709491500.
#
# TODO: add tests
sub signed_xor {

    if ( ($_[0] < 0) xor ($_[1] < 0) ) {
        return ($_[0] ^ $_[1]) - ~0 - 1;
    }

    # signs are same -> can use native xor
    return $_[0] ^ $_[1];
}

sub signed_or {

    # signs are same -> can use native xor
    if ( ($_[0] < 0) eq ($_[1] < 0) ) {
        return $_[0] | $_[1];
    }

    return ($_[0] | $_[1]) - ~0 - 1;
}

#----------------------------------------------------------------------
# Verify logic

sub unpackneg {
    my ($r, $p) = @_;

    $_ = [ gf0() ] for my (
        $t,
        $chk,
        $num,
        $den,
        $den2,
        $den4,
        $den6,
    );

    _set25519( $r->[2], [ gf1() ]);

    _unpack25519($r->[1], $p);

    _S($num, $r->[1]);
    _M($den, $num, [ D() ]);
    _Z($num, $num, $r->[2]);
    _A($den, $r->[2], $den);

    _S($den2, $den);
    _S($den4, $den2);
    _M($den6, $den4, $den2);
    _M($t, $den6, $num);
    _M($t, $t, $den);

    _pow2523($t, $t);
    _M($t, $t, $num);
    _M($t, $t, $den);
    _M($t, $t, $den);
    _M($r->[0], $t, $den);

    _S($chk, $r->[0]);
    _M($chk, $chk, $den);

    if (_neq25519($chk, $num)) {
        _M($r->[0], $r->[0], [ I() ]);
    }

    _S($chk, $r->[0]);
    _M($chk, $chk, $den);

    if (_neq25519($chk, $num)) {
        die "-1??";
    }

    # “>>” appears to be safe here.
    if (_par25519($r->[0]) == ($p->[31] >> 7)) {
        _Z($r->[0], [ gf0() ], $r->[0]);
    }

    _M( $r->[3], $r->[0], $r->[1] );

    return 0;
}

sub crypto_verify_32 {
    my ($x, $xi, $y, $yi) = @_;

    return _vn($x, $xi, $y, $yi, 32);
}

use constant D => (
    0x78a3, 0x1359, 0x4dca, 0x75eb, 0xd8ab, 0x4141, 0x0a4d, 0x0070,
    0xe898, 0x7779, 0x4079, 0x8cc7, 0xfe73, 0x2b6f, 0x6cee, 0x5203,
);

use constant I => (
    0xa0b0, 0x4a0e, 0x1b27, 0xc4ee, 0xe478, 0xad2f, 0x1806, 0x2f43,
    0xd7a7, 0x3dfb, 0x0099, 0x2b4d, 0xdf0b, 0x4fc1, 0x2480, 0x2b83,
);

sub _set25519 {
    my ($r, $a) = @_;

    $r->[$_] = $a->[$_] | 0 for 0 .. 15;
}

sub _unpack25519 {
    my ($o, $n)  = @_;

    for my $i (0 .. 15) {

        # originally “<< 8” rather than “256 *”
        $o->[$i] = $n->[ 2 * $i ] + (256 * $n->[ 2 * $i + 1 ])
    }

    $o->[15] &= 0x7fff;
}

sub _pow2523 {
    my ($o, $i) = @_;

    my $c = [ @{$i}[0 .. 15] ];

    for my $a ( reverse( 0 .. 250 ) ) {
        _S( $c, $c );

        if ($a != 1) {
            _M( $c, $c, $i );
        }
    }

    @{$o}[0 .. 15] = @{$c}[0 .. 15];
}

sub _neq25519 {
    my ($a, $b) = @_;

    my $c = _pack25519($a);
    my $d = _pack25519($b);

    return crypto_verify_32($c, 0, $d, 0);
}

sub _vn {
    my ($x, $xi, $y, $yi, $n) = @_;

    my $d = 0;

    for my $i ( 0 .. ($n - 1) ) {
        $d = signed_or( $d, signed_xor($x->[ $xi + $i ], $y->[ $yi + $i ]) );
    }

    # Originally “>>> 8”, which appears to be JS’s equivalent
    # operator to Perl’s >>.
    return (1 & (($d - 1) >> 8)) - 1;
}

sub _floor {
    my $int = int $_[0];

    $int -= 1 if ($_[0] < 0) && ($int != $_[0]);

    return $int;
}

1;
