use strict;
BEGIN {
  use Test::More;
  use Test::Exception;
  use Test::Deep;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_MSSQL}) {
    plan skip_all => 'TEST_MSSQL not configured';
  } else {
    plan tests => 19;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

sub remote_exec {
  $dbh->do('SELECT dbix_pglink.exec(?, ?)', {}, 'TEST_MSSQL', shift);
}

sub eval_remote_exec {
  eval { remote_exec(@_) };
#  diag "Error: $@\n" if $@;
}

# remote DDL

eval_remote_exec('DROP TABLE all_types');
eval_remote_exec('DROP TABLE crud');
eval_remote_exec('DROP TABLE "Quoted Table"');
eval_remote_exec('DROP TABLE foo');
eval_remote_exec('sp_droptype t_type1');

lives_ok {
  remote_exec(q/sp_addtype @typename='t_type1', @phystype=int/);
} 'create user type';

lives_ok {
  remote_exec(<<'END_OF_SQL');
CREATE TABLE all_types (
  f_int_identity     int identity,
  f_bigint           bigint default 1234567890123456,
  f_binary           binary(4) default 0xFF001122,
  f_bit              bit default 1,
  f_char             char(3) default 'foo',
  f_datetime         datetime default '2007-10-01 12:34',
  f_decimal          decimal(10,2) default 1234567.89,
  f_float            float default 1.23456789,
  f_image            image default 0xFE,
  f_int              int default 1234567890,
  f_money            money default 123.45,
  f_nchar            nchar(3) default 'bar',
  f_ntext            ntext default 'baz',
  f_numeric          numeric(5,2) default 987.65,
  f_nvarchar         nvarchar(5) default 'abc',
  f_real             real default 1.2345678,
  f_smalldatetime    smalldatetime default '2001-01-01 12:34',
  f_smallint         smallint default 32767,
  f_smallmoney       smallmoney default 543.21,
  f_sql_variant      sql_variant default 'anything',
  f_sysname          sysname default 'foobar',
  f_text             text default 'barfoo',
  f_timestamp        timestamp,
  f_tinyint          tinyint default 255,
  f_uniqueidentifier uniqueidentifier default newid(),
  f_varbinary        varbinary(10) default 0xAABBCC,
  f_varchar          varchar(5) default 'xyz',
  f_type1            t_type1 default 1
);
END_OF_SQL
} 'create all_types';

lives_ok {
  remote_exec('insert into all_types (f_int) values (default)');
} 'insert 1 row';

lives_ok {
  my $data = $dbh->selectall_arrayref(<<'END_OF_SQL',
SELECT * FROM dbix_pglink.query('TEST_MSSQL',
  'select * from all_types') as s(
  f_int_identity     int,
  f_bigint           bigint,
  f_binary           bytea,
  f_bit              bit(1),
  f_char             char(3),
  f_datetime         timestamp,
  f_decimal          decimal(10,2),
  f_float            float,
  f_image            bytea,
  f_int              int,
  f_money            numeric,
  f_nchar            char(3),
  f_ntext            text,
  f_numeric          numeric(5,2),
  f_nvarchar         varchar(5),
  f_real             real,
  f_smalldatetime    timestamp,
  f_smallint         smallint,
  f_smallmoney       numeric,
  f_sql_variant      text,
  f_sysname          text,
  f_text             text,
  f_timestamp        bytea,
  f_tinyint          smallint,
  f_uniqueidentifier text,
  f_varbinary        bytea,
  f_varchar          varchar(5),
  f_type1            int
)
END_OF_SQL
    {Slice=>{}}
  );
  use bytes;
  cmp_deeply(
    $data,
    [{
  f_int_identity     => 1,
  f_bigint           => '1234567890123456',
  f_binary           => "\377\000\021\042", #0xFF001122,
  f_bit              => 1,
  f_char             => 'foo',
  f_datetime         => '2007-10-01 12:34:00',
  f_decimal          => 1234567.89,
  f_float            => 1.23456789,
  f_image            => "\376", #0xFE
  f_int              => 1234567890,
  f_money            => '123.4500',
  f_nchar            => 'bar',
  f_ntext            => 'baz',
  f_numeric          => 987.65,
  f_nvarchar         => 'abc',
  f_real             => '1.23457', # last digit lost and rounding occured!
  f_smalldatetime    => '2001-01-01 12:34:00',
  f_smallint         => 32767,
  f_smallmoney       => '543.2100',
  f_sql_variant      => 'anything',
  f_sysname          => 'foobar',
  f_text             => 'barfoo',
  f_timestamp        => re('.{8}'), # any 8 bytes
  f_tinyint          => 255,
  f_uniqueidentifier => re('^[0-9A-F-]{36}$'), # as text
  f_varbinary        => "\252\273\314", #0xAABBCC
  f_varchar          => 'xyz',
  f_type1            => 1,
    }],
    'fetch all_types'
  );
} 'query all_types';




lives_ok {
  remote_exec(<<'END_OF_SQL');
create table crud (
  id int primary key,
  i  int,
  t  varchar(20)
);
END_OF_SQL
} 'create crud';

lives_ok {
  $dbh->do(<<'END_OF_SQL');
SELECT dbix_pglink.exec('TEST_MSSQL', 'insert into crud values(?, ?, ?)',
  ARRAY[i::text,i::text,'row#'||i::text])
FROM generate_series(1,5) as s(i)
END_OF_SQL
} 'insert with params';

lives_ok {
  remote_exec(<<'END_OF_SQL');
create table "Quoted Table" (
  "Column ""1"""    int,
  "`'!@#$%^&*()_-+/?\|[]{},.<>;:" int
);
END_OF_SQL
} 'create quoted table';




lives_ok {
  remote_exec('CREATE TABLE foo(a int, b varchar(20))');
} 'create table foo';

sub select_foo {
  $dbh->selectall_arrayref(q/SELECT * FROM dbix_pglink.query('TEST_MSSQL', 
    'select * from foo order by 1') as s(a int, b text)/, 
    {Slice=>{}}
  );
}

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST_MSSQL', 'insert into foo values(?, ?)', 
        ARRAY['999','foo']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: insert 1 row'
  );
} 'exec: insert';

is_deeply(
  select_foo(),
  [ { a=>999, b=>'foo' } ],
  'exec: row inserted'
);

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST_MSSQL', 'update foo set b=? where a=?', 
        ARRAY['bar','999']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: update 1 row'
  );
} 'exec: update';

is_deeply(
  select_foo(),
  [ { a=>999, b=>'bar' } ],
  'exec: row updated'
);

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST_MSSQL', 'delete from foo where a=?', 
        ARRAY['999']
      )/, 
      {Slice=>{}}
    ),
    [{ 'exec'=>1 }],
    'exec: delete 1 row'
  );
} 'exec: delete';

is_deeply(
  select_foo(),
  [],
  'exec: row deleted'
);

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST_MSSQL', 'nonsense')/);
} qr/error from Perl function:.*Could not find stored procedure 'nonsense'/, 'exec: invalid query';


