use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

throws_ok {
  $schema->resultset('Artist')->search
} qr/\Qsearch is *not* a mutator/, 'Proper exception on search in void ctx';

done_testing;
