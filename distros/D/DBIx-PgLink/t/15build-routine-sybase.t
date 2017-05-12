use strict;
BEGIN {
  use Test::More;
  use Test::Exception;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_SYBASE}) {
    plan skip_all => 'TEST_SYBASE not configured';
  } else {
    plan tests => 3;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

sub remote_exec {
  $dbh->do('SELECT dbix_pglink.exec(?, ?)', {}, 'TEST_SYBASE', shift);
}

eval { remote_exec('DROP PROCEDURE pglink_test1') }; 
diag "DROP PROCEDURE: $@\n";

lives_ok {
  remote_exec(<<'END_OF_SQL');
CREATE PROCEDURE pglink_test1 
  @a int
AS 
BEGIN
  if @a is null return -1
  select discounttype, discount from discounts order by 1
END
END_OF_SQL
} 'create procedure';


lives_ok {
  $dbh->selectrow_array(
    'SELECT dbix_pglink.build_accessors(?, ?, ?, ?, ?, ?::text[], ?)', 
    {}, 
    'TEST_SYBASE', # conn_name
    'test_sybase',  # local_schema
    'pubs2',  # remote_catalog
    'dbo',     # remote_schema
    '%',       # remote_object
    '{PROCEDURE}',     # remote_object_types
    undef,     # object_name_mapping
  ),
}  'build accessor';

lives_ok {
  $dbh->do(
    'SELECT dbix_pglink.build_procedure(?, ?, ?, ?, ?, ?, ?::text[])', 
    {}, 
    'TEST_SYBASE', # conn_name
    'test_sybase',  # local_schema
    'pubs2',  # remote_catalog
    '%',     # remote_schema (can be 'dbo' or user name if not dbowner)
    'pglink_test1',  # remote_object
    'pglink_test1',  # local_object
    '{discounttype,TEXT,discount,FLOAT}',  # column_info
  ),
} 'build procedure with explicit column_info';
