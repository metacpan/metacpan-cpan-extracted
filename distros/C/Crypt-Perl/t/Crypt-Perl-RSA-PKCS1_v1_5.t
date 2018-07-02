#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Crypt::Perl::RSA::PKCS1_v1_5 ();

my %strs = (
    sha256 => [
        '00.01.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.00.30.31.30.0d.06.09.60.86.48.01.65.03.04.02.01.05.00.04.20.8a.7f.35.4e.ab.d3.af.b9.d7.73.91.00.56.f1.1f.34.77.a7.25.d4.de.af.bc.cd.00.4a.19.b1.b6.89.c7.59',
        '8a.7f.35.4e.ab.d3.af.b9.d7.73.91.00.56.f1.1f.34.77.a7.25.d4.de.af.bc.cd.00.4a.19.b1.b6.89.c7.59',
    ],

    sha384 => [
        '00.01.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.ff.00.30.41.30.0d.06.09.60.86.48.01.65.03.04.02.02.05.00.04.30.26.87.56.ad.03.09.4f.ef.7c.26.ef.15.8f.f9.e1.f8.90.23.b3.4a.71.1a.d7.fe.1d.ae.71.23.f9.40.a2.89.e8.37.4a.80.4f.b6.40.c2.e4.bb.5d.26.c7.8a.69.f8',
        '26.87.56.ad.03.09.4f.ef.7c.26.ef.15.8f.f9.e1.f8.90.23.b3.4a.71.1a.d7.fe.1d.ae.71.23.f9.40.a2.89.e8.37.4a.80.4f.b6.40.c2.e4.bb.5d.26.c7.8a.69.f8',
    ],
);

$_->[0] =~ tr<.><>d for values %strs;

for my $hash_alg (sort keys %strs) {
    my $binary = pack 'H*', $strs{$hash_alg}[0];

    my $decoded;

    lives_ok(
        sub {
            $decoded = Crypt::Perl::RSA::PKCS1_v1_5::decode($binary, $hash_alg);
        },
        "decode() succeeds ($hash_alg)",
    );

    is(
        sprintf('%v.02x', $decoded),
        $strs{$hash_alg}[1],
        "decoded $hash_alg payload",
    );
}

done_testing();
