use Test2::V0;
use Test2::Require::Module 'Crypt::SaltedHash';

use Crypt::Passphrase::SaltedHash;
use Crypt::SaltedHash;
use Crypt::SysRandom qw( random_bytes );

use Digest::MD5 ();
use Digest::SHA ();

use MIME::Base64 qw( encode_base64 );

ok my $validator = Crypt::Passphrase::SaltedHash->new;

my $password = encode_base64( random_bytes(12) );

for my $alg (qw( MD5 SHA )) {

    my $csh  = Crypt::SaltedHash->new( algorithm => $alg );
    my $hash = $csh->add($password)->generate;

    note $hash;

    ok $validator->accepts_hash($hash),                 "accepts_hash";
    ok $validator->verify_password( $password, $hash ), "verify_password";

}

done_testing;
