## no critic (RCS,VERSION,encapsulation,Module)
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Authen::Passphrase');
    use_ok('Authen::Passphrase::SaltedDigest');
    use_ok('Bytes::Random::Secure');
}

done_testing();
