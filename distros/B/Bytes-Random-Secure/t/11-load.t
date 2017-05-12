## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
    use_ok( 'Bytes::Random::Secure' ) || print "Bail out!\n";
}

diag(
  "Testing Bytes::Random::Secure $Bytes::Random::Secure::VERSION, Perl $], $^X"
);

