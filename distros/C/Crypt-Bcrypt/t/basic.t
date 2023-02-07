use warnings;
use strict;

use Test::More;

use Crypt::Bcrypt qw/bcrypt bcrypt_check bcrypt_hashed bcrypt_check_hashed bcrypt_needs_rehash/;

my $password = "Hello World,";
my $salt = "A" x 16;

my $hash1 = bcrypt($password, "2b", 12, $salt);

ok($hash1);
ok(bcrypt_check($password, $hash1));

my $hash2 = bcrypt_hashed($password, "2b", 14, $salt, 'sha256');
like($hash2, qr/ ^ \$ bcrypt-sha256 \$ v=2,t=(2\w),r=(\d{2}) \$ /x, 'Prehashed bcrypt hash');
ok(bcrypt_check_hashed($password, $hash2), 'Hashed password validates');

ok(!bcrypt_needs_rehash('$2b$08$GA.eGA.eGA.eGA.eGA.eG.JwAb5PEYyk29BLAt7Dw0/5f.uaH6K32', '2b', 8), '');
ok(bcrypt_needs_rehash('$2a$08$GA.eGA.eGA.eGA.eGA.eG.JwAb5PEYyk29BLAt7Dw0/5f.uaH6K32', '2b', 8), '');
ok(bcrypt_needs_rehash('$2b$07$GA.eGA.eGA.eGA.eGA.eG.JwAb5PEYyk29BLAt7Dw0/5f.uaH6K32', '2b', 8), '');

done_testing;
