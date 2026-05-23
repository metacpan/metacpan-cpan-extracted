use Test2::V0;

use Crypt::Passphrase::SaltedHash;

use Digest::MD5 2.25 ();
use Digest::SHA 5.96 ();

ok my $validator = Crypt::Passphrase::SaltedHash->new;

my $password = "some!secret";

my @hashes = ( "{SMD5}ElwnrQKILMsBiMCpyvBM/EF2y/w=", "{SSHA}JKnToa8FrxcDfyftCt/wEg0F+0hbsD+X", );

for my $hash (@hashes) {
    subtest $hash => sub {
        ok $validator->accepts_hash($hash),                 "accepts_hash";
        ok $validator->verify_password( $password, $hash ), "verify_password";
    };

}

done_testing;
