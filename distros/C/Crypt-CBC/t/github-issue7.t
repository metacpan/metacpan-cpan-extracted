use strict;
use warnings;
use Test::More;
use Crypt::CBC;

eval "use Crypt::Blowfish()";
if ($@) {
    print "1..0 # Skipped: Crypt::Blowfish not installed\n";
    exit;
}

# small script for Blowfish encryption and decryption

# The key for the blowfish encoding/decoding below
my $privateString = '123456789012345678901234567890123456789012';

my $teststring = "Testtext";

my $key = pack('H*', $privateString);

my $params = {
                'key' => $key,
                'cipher' => 'Blowfish',
                'header' => 'randomiv',
                'nodeprecate' => 1
            };

my $cipher = Crypt::CBC->new($params);
my $encoded = $cipher->encrypt_hex($teststring);

my $decoded = $cipher->decrypt_hex($encoded);

ok($teststring eq $decoded, "Properly decoded Blowfish with header => randomiv");

done_testing();
