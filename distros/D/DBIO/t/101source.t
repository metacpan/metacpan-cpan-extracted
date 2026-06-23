use warnings;
use strict;

use Test::More;
use Test::Exception;

use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

throws_ok {$schema->source()} qr/\Qsource() expects a source name/, 'Empty args for source caught';

done_testing();
