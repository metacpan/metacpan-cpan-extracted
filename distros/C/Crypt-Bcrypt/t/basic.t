use warnings;
use strict;

use Test::More;

use Crypt::Bcrypt qw/bcrypt bcrypt_check/;

my $password = "Hello World,";
my $salt = "A" x 16;

my $hash = eval { bcrypt($password, "2b", 12, $salt) };

ok($hash);
ok(bcrypt_check($password, $hash));

done_testing;
