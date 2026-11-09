use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_dt_sqlite')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_dt_sqlite');

my $schema = DBIO::SQLite::Test->init_schema(no_deploy => 1, # Deploying would connect
);

# The schema declares its driver (core ADR 0067): the storage is the driver's
# from the start, not a generic one reblessed once the DSN is looked at.
is(
    ref $schema->storage, 'DBIO::SQLite::Storage',
    'Starting with the declared driver storage'
);

# Calling date_time_parser picks up datetime_parser_type from the declared
# driver class

my $parser = $schema->storage->datetime_parser();

is($parser, 'DateTime::Format::SQLite', 'Got expected storage-set datetime_parser');
isa_ok($schema->storage, 'DBIO::SQLite::Storage', 'storage');

done_testing;
