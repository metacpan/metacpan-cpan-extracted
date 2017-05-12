use Test::More tests => 6;
use strict;
use warnings;

sub BEGIN {
    use_ok('Crypt::Keyczar');
    use_ok('Crypt::Keyczar::Util');
    use_ok('Crypt::Keyczar::DsaPublicKey');
}

my $JSON = q|{"q": "AJJfsQZrhUV8p6TmpPqa084JwX9j", "p": "AIAAAAAAAAXxHhQxJRZ-PPj2BDrHHLV8c8pX6nyOLAW3Bc7CX_SfBiGH2VyImoz6JlAOZi6x_XspxdUvpTjV7J9uO9hwnF31m3SQjdkZW2DQDb5OS1rW_4MGrTJCktKtlZz7f8_5AoO8yHSY2XWNDqrpBEiNvaTX1ttQ59nREiR1", "y": "AGlQuRpbat4drE_fcdSZrEVfS6Fme3tNfUoJVRec1pUhoSo9PBHKFx3lbBmI8Vnub8vuY1nM2yTadOZ8H4-TYxB5JNMVTK7vLNdVcWvUUF9zRZCwps1bl0_Al29X0I1iQYJN6Klxi_QbKaSf5PhfXLVom9bJYp7_TwZCouaab296", "g": "AES5hk-DKXP__t6yDsXIdykf7lhSKHqQCW5H2V5dMg8JkoFBSP7mIvaCHT4IxoxdM2AIpWgcoi5XSrd_hD2sjNa1JHTb9BUh31dHJLym6rTsV12ClN6f78Cjt0oKFIRI__yWn9KM-vLEsjpd10VHlPfbEgKYePCnXFt7Y78G0wGr", "size": 1024}|;
my $MESSAGE = "This is some test data";
my $SIGN = q{AKrpf84wLAIUHo2PcU2cxUc43bsv7rrwT-GC6pECFGqkvmKfh8WhAQBcKLaWydgqhsha};

my $key = Crypt::Keyczar::DsaPublicKey->read($JSON);
ok($key, 'create key object');
my $engine = $key->get_engine();
ok($engine, 'create dsa engine');
my $sign = substr Crypt::Keyczar::Util::decode($SIGN), 5; # skip header
$engine->update($MESSAGE);
$engine->update(Crypt::Keyczar::FORMAT_BYTES());
ok($engine->verify($sign), 'verify message');
