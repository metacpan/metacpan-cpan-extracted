use Test::More qw(no_plan);
use Crypt::PKCS5;
use strict;


while (my $v = load()) {
    my $DK = Crypt::PKCS5::pbkdf1($v->{P}, $v->{S}, $v->{c}, $v->{dkLen});
    ok($DK eq $v->{DK});
}

sub load {
    my %result = ();
    while (defined(my $l = <DATA>)) {
        chomp $l;
        last if $l eq '';

        my ($k, $v) = split /:\s+/, $l;
        $result{$k} = $v;
    }
    return undef if !defined $result{P};

    $result{P} = pack 'H*', $result{P};
    $result{S} = pack 'H*', $result{S};
    $result{DK} = pack 'H*', $result{DK};

    return \%result;
}
__DATA__
P: 48656c6c6f20576f726c6421
S: 0000000000000000
c: 1
dkLen: 8
DK: 060c8871dd580d51

P: 48656c6c6f20576f726c6421
S: 0000000000000000
c: 1
dkLen: 16
DK: 060c8871dd580d512cbb4cc2d19208a7

P: 48656c6c6f20576f726c6421
S: 0000000000000000
c: 2
dkLen: 16
DK: b8ad1bd1fc91b9e16c93503ef9a466ee

P: 48656c6c6f20576f726c6421
S: 0000000000000000
c: 10
dkLen: 16
DK: 644956998e82e89fec263d6de326ad3d

P: 48656c6c6f20576f726c6421
S: 0000000000000000
c: 100
dkLen: 16
DK: 25daf837c823b6d6fa729733f5d3da66

P: 48656c6c6f20576f726c6421
S: 0000000000000000
c: 1000
dkLen: 16
DK: d11229bb54ae6e6ce9bfff0e18091388

P: 48656c6c6f20576f726c6421
S: 0000000000000000
c: 10000
dkLen: 16
DK: 84f06609d37479fd8a09c0add2ae77d6

P: 48656c6c6f20576f726c6421
S: 8800000000000000
c: 1
dkLen: 16
DK: e2b08e14288dbd8ab3327720d7bd44c0

P: 48656c6c6f20576f726c6421
S: 0077000000000000
c: 1
dkLen: 16
DK: 0530fd33fde456ba226206907a886212

P: 48656c6c6f20576f726c6421
S: 0000660000000000
c: 1
dkLen: 16
DK: 59b982b8f82888297d9b66f44a1a9822

P: 48656c6c6f20576f726c6421
S: 0000005500000000
c: 1
dkLen: 16
DK: 60da375e7aae99f66dc7f7a2f849f783

P: 48656c6c6f20576f726c6421
S: 0000000044000000
c: 1
dkLen: 16
DK: 48b5b04f3dc443d6b72a7a42ec69bc33

P: 48656c6c6f20576f726c6421
S: 0000000000330000
c: 1
dkLen: 16
DK: 176e76fb4cb88608bfc8a467c599fd96

P: 48656c6c6f20576f726c6421
S: 0000000000002200
c: 1
dkLen: 16
DK: 3a42a42e889f4df338725d18765370ed

P: 48656c6c6f20576f726c6421
S: 0000000000000011
c: 1
dkLen: 16
DK: 5c836c067818dc4c0aee27a03031ed36

P: 48656c6c6f20576f726c6421
S: 7f7f7f7f7f7f7f7f
c: 1
dkLen: 16
DK: 5909a22a4daf7a97a8d33dc3fd33ec79

P: 48656c6c6f20576f726c6421
S: ffffffffffffffff
c: 1
dkLen: 16
DK: 0b48e072a82050473722344a3dfedfb3

