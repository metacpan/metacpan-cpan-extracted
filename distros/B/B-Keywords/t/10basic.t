# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN {
    plan( tests => 7 );
    $^W = 1;
}
use lib qw( ../lib lib );
use B::Keywords;

#########################

ok( scalar @B::Keywords::Scalars );
ok( scalar @B::Keywords::Arrays );
ok( scalar @B::Keywords::Hashes );
ok( scalar @B::Keywords::Filehandles );
ok( scalar @B::Keywords::Symbols );
ok( scalar @B::Keywords::Functions );
ok( scalar @B::Keywords::Barewords );

