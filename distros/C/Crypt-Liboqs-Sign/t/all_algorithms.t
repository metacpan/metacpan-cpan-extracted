use strict;
use warnings;
use Test::More;
use Crypt::Liboqs::Sign qw(_oqs_alg_list _oqs_keypair _oqs_sign _oqs_verify);

my @algorithms = _oqs_alg_list();
ok(scalar @algorithms > 0, 'At least one algorithm available');

# Some algorithms are very slow (SLH-DSA/SPHINCS+ -s variants, OV, SNOVA).
# Only test all if LIBOQS_TEST_ALL is set.
my %slow_pattern;
unless ($ENV{LIBOQS_TEST_ALL}) {
    %slow_pattern = map { $_ => 1 } grep {
        /SPHINCS.*-s-/ || /^OV-/ || /^SNOVA/
    } @algorithms;
}

for my $alg (@algorithms) {
    if ($slow_pattern{$alg}) {
        SKIP: {
            skip "$alg is slow, set LIBOQS_TEST_ALL=1 to test", 1;
        }
        next;
    }

    subtest $alg => sub {
        my ($pk, $sk) = _oqs_keypair($alg);
        ok(defined $pk && length($pk) > 0, "generated public key");
        ok(defined $sk && length($sk) > 0, "generated secret key");

        my $message = "Test message for $alg";
        my $signature = _oqs_sign($alg, $message, $sk);
        ok(defined $signature && length($signature) > 0, "generated signature");

        my $valid = _oqs_verify($alg, $signature, $message, $pk);
        ok($valid, "signature is valid");

        my $invalid = _oqs_verify($alg, $signature, "wrong message", $pk);
        ok(!$invalid, "rejects wrong message");
    };
}

done_testing();
