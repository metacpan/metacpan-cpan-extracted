package t::Crypt::Perl::Ed25519::PrivateKey;

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Bytes::Random::Secure::Tiny ();

use FindBin;
use lib "$FindBin::Bin/../lib";

use Crypt::Perl::Ed25519::PrivateKey;

{
    my $msg = 'test';

    my $key = Crypt::Perl::Ed25519::PrivateKey->new('01234567890123456789012345678901');

    my $signature = $key->sign($msg);

    cmp_deeply(
        [ unpack 'C*', $signature ],
        [ 97,68,231,142,114,20,32,84,42,59,212,177,59,182,143,41,165,138,164,199,94,17,44,24,176,202,84,5,74,48,117,63,136,196,250,28,130,1,232,251,158,60,163,46,6,27,119,230,184,59,186,61,115,60,249,205,72,94,172,56,206,229,198,5 ],
        'signature of “test”',
    #) or diag "got: @signature";
    ) or diag sprintf( "got: %v.02x", $signature );

    is(
        $key->verify( $msg, $signature ),
        1,
        'verify()',
    );

    substr( $signature, 0, 1, 'z' );

    ok(
        !$key->verify( $msg, $key->sign("$msg $msg") ),
        'verify() - mismatch',
    );
}

#----------------------------------------------------------------------
my @pre_assigned_tests = (
    {
        private => [ 226, 85, 30, 181, 147, 126, 178, 234, 14, 82, 163, 108, 30, 146, 174, 101, 160, 27, 188, 20, 189, 13, 91, 33, 156, 147, 170, 24, 41, 250, 191, 143 ],
        public => [ 149, 76, 21, 14, 234, 81, 92, 79, 160, 82, 8, 246, 69, 114, 70, 202, 242, 205, 147, 62, 245, 189, 87, 25, 230, 4, 106, 16, 135, 62, 147, 164 ],
        message => '37.21.9a.9e.99.d9.53.47.cb.ca.3f.e9.48.11.3d.77.95.ff.a1.08.8f.72.21.89',
        signature => 'b5.65.af.54.be.70.78.a3.87.82.f2.f6.ec.d3.f5.26.96.aa.7d.87.3e.c9.5c.e0.e4.d6.da.5b.88.07.bf.dc.a7.4f.80.30.f9.b3.f6.90.a4.30.6f.0e.88.59.4f.e6.3c.6a.f3.4b.3b.c1.c0.0d.57.61.12.49.78.d1.22.0a',
    },
    {
        private => [ 147, 28, 170, 11, 118, 37, 231, 19, 158, 20, 105, 109, 36, 41, 131, 70, 145, 242, 5, 56, 236, 254, 172, 1, 254, 145, 81, 13, 59, 63, 98, 151 ],
        public => [ 113, 214, 236, 64, 43, 34, 172, 89, 22, 8, 89, 127, 187, 195, 16, 170, 170, 149, 184, 173, 39, 192, 163, 139, 91, 88, 149, 88, 122, 106, 227, 56 ],
        message => '64.3c.a0.34.ac.7e.46.19.7b.7a.a6.b5.50.08.40.8c.71.5f.d9.83.f1.7b.cf.bf',
        signature => '50.a0.a1.86.2a.e4.40.b9.af.63.5f.cd.6e.41.c8.2d.a3.a2.00.8b.8f.b8.af.2e.a4.c5.23.42.75.84.d6.35.83.56.2f.71.5e.b5.41.fb.f0.55.93.4a.f9.68.af.af.1e.0d.d5.4a.07.32.b3.3f.65.b4.eb.9e.cc.f3.c6.0c',
    },
    {
        private => [ 200, 101, 165, 21, 192, 50, 14, 180, 38, 210, 151, 69, 59, 93, 25, 218, 60, 211, 229, 151, 57, 3, 159, 148, 204, 54, 140, 86, 82, 237, 85, 34 ],
        public => [ 239, 145, 206, 165, 6, 213, 190, 169, 99, 17, 132, 230, 4, 201, 139, 169, 47, 19, 240, 68, 159, 180, 218, 153, 158, 17, 250, 102, 215, 217, 30, 42 ],
        message => '1c.96.78.ca.c4.1e.97.00.c4.d5.08.6e.93.91.11.f2.09.2c.68.12.c6.c1.bc.ef',
        signature => '0b.d3.f5.3d.d3.0d.df.10.35.85.ff.7b.54.ed.29.c4.09.fe.2f.b6.46.a4.07.82.3b.62.bd.b7.61.03.e6.e2.c4.8c.ea.00.6c.78.d6.88.92.63.a1.50.ce.f4.5d.f4.70.1b.ae.a6.33.e3.ef.35.03.e7.bd.a0.e8.cf.cc.03',
    },
);

for my $idx ( 0 .. $#pre_assigned_tests) {
    note "PRE-DESIGNATED: " . (1 + $idx);

    my ($priv_ar, $pub_ar, $msg_vec, $sig_vec) = @{ $pre_assigned_tests[$idx] }{ 'private', 'public', 'message', 'signature' };

    my $pub_str = join q<.>, map { sprintf '%02x', $_ } @$pub_ar;

    my $key = Crypt::Perl::Ed25519::PrivateKey->new( join q<>, map { chr } @$priv_ar );
    is_deeply(
        sprintf('%v.02x', $key->get_public() ),
        $pub_str,
        'correct public key determined',
    );

    my $msg = join q<>, map { chr hex } split m<\.>, $msg_vec;

    my $sig = $key->sign($msg);

    is(
        sprintf('%v.02x', $sig),
        $sig_vec,
        'expected signature',
    );

    my $real_sig = join q<>, map { chr hex } split m<\.>, $sig_vec;
    ok( $key->verify($msg, $real_sig), 'verify()' );
}

#----------------------------------------------------------------------

my $rng = Bytes::Random::Secure::Tiny->new();

for my $i ( 1 .. 8 ) {
    my $key = Crypt::Perl::Ed25519::PrivateKey->new();

    my $msg1 = $rng->bytes(24);
    my $sig1 = $key->sign($msg1);

    ok( $key->verify($msg1, $sig1), "round-trip ($i) - should verify" ) or do {
        diag explain( {
            key => $key,
            message => sprintf('%v.02x', $msg1),
            signature => sprintf('%v.02x', $sig1),
        } );
    };

    my $msg2 = $rng->bytes(25);

    ok( !$key->verify($msg2, $sig1), "round-trip ($i) - should mismatch" ) or do {
        diag explain( {
            key => $key,
            message => sprintf('%v.02x', $msg2),
            signature => sprintf('%v.02x', $sig1),
        } );
    };
}

#----------------------------------------------------------------------

my $private = Crypt::Perl::Ed25519::PrivateKey->new(
    join( q<>, map { chr hex } split m<\.>, '9d.61.b1.9d.ef.fd.5a.60.ba.84.4a.f4.92.ec.2c.c4.44.49.c5.69.7b.32.69.19.70.3b.ac.03.1c.ae.7f.60' ),
);

my $thumbprint = $private->get_jwk_thumbprint('sha256');
is(
    $thumbprint,
    'kPrK_qmxVWaYVA9wwBF6Iuo3vVzz7TxHCTwXBygrS4k',
    'JWK thumbprint (SHA-256)',
);

done_testing();
