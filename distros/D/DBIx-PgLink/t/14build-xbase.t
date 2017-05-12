use strict;
BEGIN {
  use Test::More;
  use Test::Exception;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_XBASE}) {
    plan skip_all => 'TEST_XBASE not configured';
  } else {
    plan tests => 1;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

ok(
  $dbh->selectrow_array(
    'SELECT dbix_pglink.build_accessors(?, ?, ?, ?, ?, ?, ?)', 
    {}, 
    'TEST_XBASE', # conn_name
    'test_xbase', # local_schema
    undef,     # remote_catalog
    undef,     # remote_schema
    '%',       # remote_object
    undef,     # remote_object_types
    undef,     # object_name_mapping
  ),
  'build accessor'
);
