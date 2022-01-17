use Test::More;

use Dancer2::Plugin::CryptPassphrase;
use Crypt::Passphrase;
use utf8;
use lib 't/lib';
use Test::App;

my $app = Test::App::app();

my $authenticator = Crypt::Passphrase->new(
    encoder => 'Argon2',
);

my $plugin = Dancer2::Plugin::CryptPassphrase->new(
    app       => $app,
    encoder   => 'Argon2',
    vaidators => ['+Test::Encoder']
);

my $password = "mypassword";

ok $plugin->verify_password( $password, "BAD$password" ),
  "verify_password OK for password using old validator";

ok $plugin->password_needs_rehash("BAD$password"),
  "... and password_needs_rehash returns true";

ok my $hash = $plugin->hash_password($password), "we can call hash_password";

like $hash, qr/^\$argon2/, "... and hash is upgraded to Argon2";

ok $authenticator->verify_password( $password, $hash ),
  "... and Crypt::Passphrase verifies the hash";

done_testing;
