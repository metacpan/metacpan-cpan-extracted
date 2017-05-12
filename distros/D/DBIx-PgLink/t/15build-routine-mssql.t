use strict;
BEGIN {
  use Test::More;
  use Test::Exception;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_MSSQL}) {
    plan skip_all => 'TEST_MSSQL not configured';
  } else {
    plan tests => 7;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

sub remote_exec {
  $dbh->do('SELECT dbix_pglink.exec(?, ?)', {}, 'TEST_MSSQL', shift);
}

eval { remote_exec('DROP PROCEDURE pglink_test1') };
lives_ok {
  remote_exec(<<'END_OF_SQL');
CREATE PROCEDURE pglink_test1 
  @a int
AS 
BEGIN
  if @a is null return -1
  select * from Region order by 1
END
END_OF_SQL
} 'create procedure';

# Northwind sample database is very old and has no functions
eval { remote_exec('DROP FUNCTION func1') };
eval { remote_exec('DROP FUNCTION func2') };
eval { remote_exec('DROP FUNCTION func3') };

lives_ok {
  remote_exec(<<'END_OF_SQL');
create function func1 (@i int) returns varchar(20) as
begin
  return '<'+convert(varchar,@i)+'>'
end
END_OF_SQL
} 'create func1 (scalar)';

lives_ok {
  remote_exec(<<'END_OF_SQL');
create function func2 (@i int) returns TABLE as
  return (select * from Region where RegionID=@i)
END_OF_SQL
} 'create func2 (table)';

lives_ok {
  remote_exec(<<'END_OF_SQL');
create function func3 (@i int) returns @res TABLE (
  RegionID int,
  RegionDescript nvarchar(50)
)
as
begin
  insert into @res select * from Region where RegionID=@i
  return
end
END_OF_SQL
} 'create func3 (multistatement table)';



lives_ok {
  $dbh->do(
    'SELECT dbix_pglink.build_accessors(?, ?, ?, ?, ?, ?::text[], ?::text[])', 
    {}, 
    'TEST_MSSQL', # conn_name
    'northwind',  # local_schema
    'Northwind',  # remote_catalog
    'dbo',     # remote_schema
    '%',       # remote_object
    '{PROCEDURE}',     # remote_object_types
    undef,     # object_name_mapping
  ),
}  'build procedure';

lives_ok {
  $dbh->do(
    'SELECT dbix_pglink.build_procedure(?, ?, ?, ?, ?, ?, ?::text[])', 
    {}, 
    'TEST_MSSQL', # conn_name
    'northwind',  # local_schema
    'Northwind',  # remote_catalog
    '%',     # remote_schema (can be 'dbo' or user name if not dbowner)
    'pglink_test1',  # remote_object
    'pglink_test1',  # local_object
    '{RegionID,INT,RegionDescription,VARCHAR}',  # column_info
  ),
} 'build procedure with explicit column_info';


lives_ok {
  $dbh->do(
    'SELECT dbix_pglink.build_accessors(?, ?, ?, ?, ?, ?::text[], ?::text[])', 
    {}, 
    'TEST_MSSQL', # conn_name
    'northwind',  # local_schema
    'Northwind',  # remote_catalog
    '%',     # remote_schema
    '%',       # remote_object
    '{FUNCTION}',     # remote_object_types
    undef,     # object_name_mapping
  ),
}  'build function';



