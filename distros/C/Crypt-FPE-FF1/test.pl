use lib 'lib';
use blib;
use Crypt::FPE::FF1::Format;

my %base = (
  key_hex   => "EF4359D8D580AA4F7F036D6F04FC6A94",
  tweak_hex => "D8E7920AFA330A73",
);

sub test {
  my ($fmt, $plain_text) = @_;
  my $cipher_text = eval { $fmt->encrypt_masked($plain_text) };
  if ($@) {
    print "Encrypting '$plain_text'... FAILED: $@\n";
    return;
  }
  my $decrypted_text = $fmt->decrypt_masked($cipher_text);

  print "Encrypting '$plain_text'...\n";
  print "\tEncrypted: '$cipher_text'\n";
  print "\tDecrypted: '$decrypted_text'\n\n";
}

print "=== mode => 'strict' (default; NIST SP 800-38G compliant) ===\n";
print "Runs below the 1,000,000-domain floor (e.g. a lone capital letter) are rejected rather than silently left in plaintext.\n\n";
my $strict = Crypt::FPE::FF1::Format->new(%base);
test($strict, 5613765533);
test($strict, '(561) 376-5533!');
test($strict, 'Hunter');       # fails: only 1 uppercase char ('H')
test($strict, 'Hello World');  # fails: only 2 uppercase chars ('H','W')

print "=== mode => 'combined' (single radix-62 pass; larger domain) ===\n";
print "Preserves length and formatting-character positions, but not per-character digit/lower/upper shape.\n\n";
my $combined = Crypt::FPE::FF1::Format->new(%base, mode => 'combined');
test($combined, 5613765533);
test($combined, '(561) 376-5533!');
test($combined, 'Hunter');
test($combined, 'Hello World');

print "=== mode => 'permissive' (opt-in; below-floor domains allowed) ===\n";
print "Preserves per-character shape like 'strict', but accepts weak or single-character runs. Requires unsafe => 1.\n\n";
my $permissive = Crypt::FPE::FF1::Format->new(%base, mode => 'permissive', unsafe => 1);
test($permissive, 'Hunter');
test($permissive, 'Hello World');
