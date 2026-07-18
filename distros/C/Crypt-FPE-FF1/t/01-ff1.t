use strict;
use warnings;
use Test::More;

use Crypt::FPE::FF1;

# Known vector from upstream README:
# key=EF4359D8D580AA4F7F036D6F04FC6A94
# tweak=D8E7920AFA330A73, radix=10
my $ff1 = Crypt::FPE::FF1->new(
  key_hex   => 'EF4359D8D580AA4F7F036D6F04FC6A94',
  tweak_hex => 'D8E7920AFA330A73',
  radix     => 10,
);

my $pt = '890121234567890000';
my $ct = $ff1->encrypt($pt);
is $ct, '318181603547192051', 'FF1 encrypt matches example vector';

my $rt = $ff1->decrypt($ct);
is $rt, $pt, 'round-trip decrypt';

# Regression: length < 2 used to abort the whole process (C-level assert
# on a degenerate Feistel split) instead of raising a Perl exception.
eval { $ff1->encrypt('5') };
like $@, qr/length must be >= 2/, 'single-char input raises instead of crashing';

# Regression: domains smaller than NIST's 1,000,000 floor used to be
# silently accepted, undermining FF1's security guarantees.
eval { $ff1->encrypt('1234') };
like $@, qr/radix\^length must be >= 1,000,000/, 'sub-floor domain size is rejected';

# Regression: characters outside the radix's alphabet used to be silently
# reinterpreted (str[i]-'0') by the C layer instead of rejected, producing
# non-invertible ciphertext.
eval { $ff1->encrypt('12 45678') };
like $@, qr/is not a valid digit/, 'out-of-alphabet character is rejected';

# Long input used to overflow a fixed 100-element stack buffer in the C
# layer (confirmed via AddressSanitizer); now heap-allocated to length.
my $long_pt = '1' x 150;
my $long_ct = $ff1->encrypt($long_pt);
is length($long_ct), 150, 'long input round-trips without overflow';
is $ff1->decrypt($long_ct), $long_pt, 'long input decrypts back correctly';

done_testing;
