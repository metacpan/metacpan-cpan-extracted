use strict;
use warnings;

use Test::More;
use Crypt::SaltedHash;
use Test::Fatal;

my $string = "+++linux";
$string =~ m/[+]*(.*)/;

is $1, 'linux', '$1 set to "linux"';

my $stored_password = '$PBKDF2$HMACSHA1:1000:bHV4ZW1idXJna0tB4/Lo9MtMLaGHOtY9ig==$sUKYw9mZ66E8fLL2w01Rq2EotiY=';
my $password = 'somepw';

my $return;
my $lives = exception { $return = Crypt::SaltedHash->validate( $stored_password, $password, undef ) };

is $lives,  undef, 'validate() lived even through non-match and $1 already set!';
ok !$return, 'validate() returns false properly';

done_testing;
