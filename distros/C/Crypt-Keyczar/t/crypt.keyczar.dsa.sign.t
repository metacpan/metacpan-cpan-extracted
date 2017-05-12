use Test::More tests => 9;
use strict;
use warnings;

sub BEGIN {
    use_ok('Crypt::Keyczar');
    use_ok('Crypt::Keyczar::Util');
    use_ok('Crypt::Keyczar::DsaPublicKey');
    use_ok('Crypt::Keyczar::DsaPrivateKey');
}

my $JSON_PRIV = q|{"publicKey": {"q": "AJJfsQZrhUV8p6TmpPqa084JwX9j", "p": "AIAAAAAAAAXxHhQxJRZ-PPj2BDrHHLV8c8pX6nyOLAW3Bc7CX_SfBiGH2VyImoz6JlAOZi6x_XspxdUvpTjV7J9uO9hwnF31m3SQjdkZW2DQDb5OS1rW_4MGrTJCktKtlZz7f8_5AoO8yHSY2XWNDqrpBEiNvaTX1ttQ59nREiR1", "y": "AGlQuRpbat4drE_fcdSZrEVfS6Fme3tNfUoJVRec1pUhoSo9PBHKFx3lbBmI8Vnub8vuY1nM2yTadOZ8H4-TYxB5JNMVTK7vLNdVcWvUUF9zRZCwps1bl0_Al29X0I1iQYJN6Klxi_QbKaSf5PhfXLVom9bJYp7_TwZCouaab296", "g": "AES5hk-DKXP__t6yDsXIdykf7lhSKHqQCW5H2V5dMg8JkoFBSP7mIvaCHT4IxoxdM2AIpWgcoi5XSrd_hD2sjNa1JHTb9BUh31dHJLym6rTsV12ClN6f78Cjt0oKFIRI__yWn9KM-vLEsjpd10VHlPfbEgKYePCnXFt7Y78G0wGr", "size": 1024}, "size": 1024, "x": "AGLJry5Q0CZo9cH6XRYd2ZZZppwg"}
|;
my $JSON_PUB = q|{"q": "AJJfsQZrhUV8p6TmpPqa084JwX9j", "p": "AIAAAAAAAAXxHhQxJRZ-PPj2BDrHHLV8c8pX6nyOLAW3Bc7CX_SfBiGH2VyImoz6JlAOZi6x_XspxdUvpTjV7J9uO9hwnF31m3SQjdkZW2DQDb5OS1rW_4MGrTJCktKtlZz7f8_5AoO8yHSY2XWNDqrpBEiNvaTX1ttQ59nREiR1", "y": "AGlQuRpbat4drE_fcdSZrEVfS6Fme3tNfUoJVRec1pUhoSo9PBHKFx3lbBmI8Vnub8vuY1nM2yTadOZ8H4-TYxB5JNMVTK7vLNdVcWvUUF9zRZCwps1bl0_Al29X0I1iQYJN6Klxi_QbKaSf5PhfXLVom9bJYp7_TwZCouaab296", "g": "AES5hk-DKXP__t6yDsXIdykf7lhSKHqQCW5H2V5dMg8JkoFBSP7mIvaCHT4IxoxdM2AIpWgcoi5XSrd_hD2sjNa1JHTb9BUh31dHJLym6rTsV12ClN6f78Cjt0oKFIRI__yWn9KM-vLEsjpd10VHlPfbEgKYePCnXFt7Y78G0wGr", "size": 1024}|;
my $MESSAGE = "This is some test data";

my $priv = Crypt::Keyczar::DsaPrivateKey->read($JSON_PRIV);
ok($priv, 'create private key object');
my $engine = $priv->get_engine();
ok($engine, 'create dsa engine');
$engine->update($MESSAGE);
$engine->update(Crypt::Keyczar::FORMAT_BYTES());
my $sign = $engine->sign();
ok($sign, 'sign message');

my $pub = Crypt::Keyczar::DsaPublicKey->read($JSON_PUB);
ok($priv, 'create public key object');
my $pe = $pub->get_engine();
$pe->update($MESSAGE);
$pe->update(Crypt::Keyczar::FORMAT_BYTES());
ok($pe->verify($sign), 'verify message');
