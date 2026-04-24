use strict;
use warnings;
use Test::More;

use Crypt::OpenSSL::RSA;

plan tests => 4;

# Test that eval-caught OpenSSL failures don't pollute subsequent error messages.
# Bug: croakSsl() used ERR_get_error() once (oldest error) instead of draining
# the queue to the last (most recent/descriptive) error.

my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);

# Trigger a decrypt failure inside eval
eval { $rsa->decrypt("not valid ciphertext that is too short") };
my $first_error = $@;
ok($first_error, "decrypt failure with short input caught in eval");

# Trigger a different decrypt failure
eval { $rsa->decrypt("x" x 256) };
my $second_error = $@;
ok($second_error, "decrypt failure with full-length garbage caught in eval");

# The second error should be a real decryption error, not stale from the first
like($second_error, qr/OpenSSL error: \S/, "second error has a meaningful OpenSSL message");

# Trigger yet another failure after two eval-caught ones — error queue should be clean
eval { $rsa->encrypt("A" x 500) };
my $third_error = $@;
like($third_error, qr/too large|data greater|asym cipher failure|plaintext too long/i,
    "third error reports actual problem (data too large), not stale from earlier failures");
