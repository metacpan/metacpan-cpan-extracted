## no critic (RCS,VERSION,encapsulation,Module)
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('DBIx::Connector');
    use_ok('Authen::Passphrase::SaltedSHA512');
}

done_testing();
