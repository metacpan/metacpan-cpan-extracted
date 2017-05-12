use strict;
BEGIN {
  use Test::More;
  use Test::Exception;
  use Test::Deep;
  use lib 't';
  use PgLinkTestUtil;
  my $ts = PgLinkTestUtil::load_conf;
  if (!exists $ts->{TEST_SYBASE}) {
    plan skip_all => 'TEST_SYBASE not configured';
  } else {
    plan tests => 19;
  }
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

sub remote_exec {
  $dbh->do('SELECT dbix_pglink.exec(?, ?)', {}, 'TEST_SYBASE', shift);
}

# remote DDL

eval { remote_exec('DROP TABLE all_types'); };
eval { remote_exec('DROP TABLE crud'); };
eval { remote_exec('DROP TABLE "Quoted Table"'); };
eval { remote_exec('DROP TABLE foo'); };
eval { remote_exec('sp_droptype t_type1'); };

lives_ok {
  remote_exec(q/sp_addtype @typename='t_type1', @phystype=int/);
} 'create user type';

# unichar/univarchar commented out for test on ASE 12.0
lives_ok {
  remote_exec(<<'END_OF_SQL');
CREATE TABLE all_types (
  f_numeric_identity numeric(16) identity,
  f_binary           binary(4) default 0xFF001122,
  f_bit              bit default 1,
  f_char             char(3) default 'foo',
  f_datetime         datetime default '2007-10-01 12:34',
  f_decimal          decimal(10,2) default 1234567.89,
  f_float            float default 1.23456789,
  f_image            image default 0xFE,
  f_int              int default 1234567890,
  f_money            money default 123.45,
  f_numeric          numeric(5,2) default 987.65,
  f_real             real default 1.2345678,
  f_smalldatetime    smalldatetime default '2001-01-01 12:34',
  f_smallint         smallint default 32767,
  f_smallmoney       smallmoney default 543.21,
  f_sysname          sysname(6) default 'foobar',
  f_text             text default 'barfoo',
  f_timestamp        timestamp,
  f_tinyint          tinyint default 255,
--  f_unichar          unichar(3) default 'bar',
--  f_univarchar       univarchar(5) default 'abc',
  f_varbinary        varbinary(10) default 0xAABBCC,
  f_varchar          varchar(5) default 'xyz',
  f_type1            t_type1 default 1
)
END_OF_SQL
} 'create all_types';

lives_ok {
  remote_exec('insert into all_types (f_int) values (1234567890)');
} 'insert 1 row';

lives_ok {
  my $data = $dbh->selectall_arrayref(<<'END_OF_SQL',
SELECT * FROM dbix_pglink.query('TEST_SYBASE',
  'select * from all_types') as s(
  f_numeric_identity numeric,
  f_binary           bytea,
  f_bit              bit(1),
  f_char             char(3),
  f_datetime         timestamp,
  f_decimal          decimal(10,2),
  f_float            float,
  f_image            bytea,
  f_int              int,
  f_money            numeric,
  f_numeric          numeric(5,2),
  f_real             real,
  f_smalldatetime    timestamp,
  f_smallint         smallint,
  f_smallmoney       numeric,
  f_sysname          text,
  f_text             text,
  f_timestamp        bytea,
  f_tinyint          smallint,
--  f_unichar          char(3),
--  f_univarchar       varchar(5),
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
  f_numeric_identity => 1,
  f_binary           => "ff001122", #0xFF001122, unconverted hex string
   # ad-hoc query can not distinguish BINARY type from IMAGE type, and DBD::Sybase convert only IMAGE
  f_bit              => 1,
  f_char             => 'foo',
  f_datetime         => '2007-10-01 12:34:00',
  f_decimal          => 1234567.89,
  f_float            => 1.23456789,
  f_image            => "\376", #0xFE
  f_int              => 1234567890,
  f_money            => re('^123.45(00)?$'),
  f_numeric          => 987.65,
  f_real             => '1.23457', # last digit lost and rounding occured!
  f_smalldatetime    => '2001-01-01 12:34:00',
  f_smallint         => 32767,
  f_smallmoney       => re('^543.21(00)?$'),
  f_sysname          => 'foobar',
  f_text             => 'barfoo',
  f_timestamp        => re('.{8}'), # any 8 bytes
  f_tinyint          => 255,
#  f_unichar          => 'bar',
#  f_univarchar       => 'abc',
  f_varbinary        => "aabbcc", #0xAABBCC, unconverted hex string
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
)
END_OF_SQL
} 'create crud';

lives_ok {
  $dbh->do(<<'END_OF_SQL');
SELECT dbix_pglink.exec('TEST_SYBASE', 'insert into crud values(?, ?, ?)',
  ARRAY[i::text,i::text,'row#'||i::text])
FROM generate_series(1,5) as s(i)
END_OF_SQL
} 'insert with params';

lives_ok {
  remote_exec(<<'END_OF_SQL');
create table "Quoted Table" (
  "Column ""1"""    int,
  "`'!@#%^&*()-+/?\|[]{},.<>;:" int
)
END_OF_SQL
} 'create quoted table';




lives_ok {
  remote_exec('CREATE TABLE foo(a int, b varchar(20))');
} 'create table foo';

sub select_foo {
  $dbh->selectall_arrayref(q/SELECT * FROM dbix_pglink.query('TEST_SYBASE', 
    'select * from foo order by 1') as s(a int, b text)/, 
    {Slice=>{}}
  );
}

lives_ok {
  is_deeply( 
    $dbh->selectall_arrayref(q/
      SELECT dbix_pglink.exec('TEST_SYBASE', 'insert into foo values(?, ?)', 
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
      SELECT dbix_pglink.exec('TEST_SYBASE', 'update foo set b=? where a=?', 
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
      SELECT dbix_pglink.exec('TEST_SYBASE', 'delete from foo where a=?', 
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
  $dbh->do(q/SELECT dbix_pglink.exec('TEST_SYBASE', 'nonsense')/);
} qr/error from Perl function: DBD::Sybase::st execute failed: Server message number=2812.*text=Stored procedure 'nonsense' not found/, 
  'exec: invalid query';


