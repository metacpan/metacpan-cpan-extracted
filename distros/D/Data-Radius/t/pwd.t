use strict;
use warnings;
use Test::More tests => 4 + 1;
use Test::NoWarnings;

BEGIN { use_ok('Data::Radius::Util', qw(encrypt_pwd decrypt_pwd)) };

my $authenticator = pack('L<4', 561138743, 3194401087, 2213483623, 4032919672);
my $secret = 'top-secret';
my $plain_pwd = 'super-password';
my $enc_pwd = "\xB6\x89\x18\x42\x3E\xA9\x9B\x9F\x50\xBD\x7C\x89\x80\xC3\xB2\x11";

my $pwd = encrypt_pwd($plain_pwd, $secret, $authenticator);
is($pwd, $enc_pwd, "encrypted password");

$pwd = decrypt_pwd($enc_pwd, $secret, $authenticator);
is($pwd, $plain_pwd, 'decrypted password');

my $pwd_short = encrypt_pwd('Z', 'top-secret', $authenticator);
is($pwd_short, "\x9F\xFC\x68\x27\x4C\x84\xEB\xFE\x23\xCE\x0B\xE6\xF2\xA7\xB2\x11", 'short password');
