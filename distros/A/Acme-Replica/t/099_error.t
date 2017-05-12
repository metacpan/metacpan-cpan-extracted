use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

use Acme::Replica;

dies_ok{
    fail( replica_of(\&sub) );
} 'Not a (SCALAR|ARRAY|HASH) reference.';
