use strict;
use Test::More tests => 2;
use Test::Exception;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

ok(
  $dbh->selectrow_array(
    'SELECT dbix_pglink.build_accessors(?, ?, ?, ?, ?, ?, ?)', 
    {}, 
    'TEST',    # conn_name
    'test_pg', # local_schema
    undef,     # remote_catalog
    'source',  # remote_schema
    '%',       # remote_object
    undef,     # remote_object_types
    undef,     # object_name_mapping
  ),
  'build accessor'
);
