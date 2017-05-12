## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Authen::Passphrase::SaltedSHA512',
        qw( generate_salted_sha512 validate_salted_sha512 ) )
      || print "Bail out!\n";
}

diag(
"Testing Authen::Passphrase::SaltedSHA512 $Authen::Passphrase::SaltedSHA512::VERSION, Perl $], $^X"
);
