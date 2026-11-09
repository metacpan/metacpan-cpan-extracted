#!/usr/bin/env perl
# t/129-error-values-masked-live.t -- LIVE. The values of a statement stay out
# of the exceptions the storage throws, over each access path.
#
# WHY this matters: SQL Server writes the offending value into its own error
# text ("Conversion failed when converting the varchar value 'x' to data type
# int.", "The duplicate key value is (x).", "Truncated value: 'x'.") also when
# the value was a bind. The family's rule is that a message names keys,
# columns and options, never values (core ADR 0075; $dbh->errstr stays raw).
# Each form is provoked through the storage API; the exception text, its
# message and its detail must not hold the value, and type, table, column,
# constraint and "with N bind value(s)" must still be there. A literal that
# stands in the statement itself is the statement's, and stays in the
# "[for Statement ...]" part.
#
# Access paths (each skips without its environment):
#   DBD::ODBC                   DBIO_TEST_MSSQL_ODBC_DSN / _USER / _PASS
#   DBD::Sybase                 DBIO_TEST_MSSQL_DSN / _USER / _PASS
#   DBD::Sybase, no placeholders (NoBindVars: the values are in the statement)
#
# Only objects named dbio_fw_* are made, and they are dropped again.

use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

my %ENV_PREFIX = (
  'DBD::Sybase' => 'DBIO_TEST_MSSQL',
  'DBD::ODBC'   => 'DBIO_TEST_MSSQL_ODBC',
);

my %CONNECT;
for my $dbd (keys %ENV_PREFIX) {
  my ($dsn, $user, $pass) = @ENV{ map { "$ENV_PREFIX{$dbd}_$_" } qw/DSN USER PASS/ };
  $CONNECT{$dbd} = [ $dsn, $user, $pass ] if $dsn and defined $user and defined $pass;
}

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN} or $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, with _USER and _PASS, to run this test'
  unless %CONNECT;

if ($CONNECT{'DBD::Sybase'}) {
  if (not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_sybase')) {
    diag 'DBD::Sybase is not looked at: test needs '
       . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_sybase');
    delete $CONNECT{'DBD::Sybase'};
  }
  elsif (not eval { require DBIO::Sybase::Storage; 1 }) {
    die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };
    diag 'DBD::Sybase is not looked at: DBIO::Sybase is not installed';
    delete $CONNECT{'DBD::Sybase'};
  }
}

if ($CONNECT{'DBD::ODBC'}
    and not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc')) {
  diag 'DBD::ODBC is not looked at: test needs '
     . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_odbc');
  delete $CONNECT{'DBD::ODBC'};
}

plan skip_all => 'Neither access path has what it needs installed' unless %CONNECT;

local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;
local $SIG{__WARN__} = sub {
  warn $_[0] unless $_[0] =~ /compiled against buggy FreeTDS version/;
};

{
  package T::FW::Result::T;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_fw_t');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    n  => { data_type => 'integer', is_nullable => 1 },
    ti => { data_type => 'tinyint', is_nullable => 1 },
    si => { data_type => 'smallint', is_nullable => 1 },
    s  => { data_type => 'varchar', size => 5, is_nullable => 1 },
    ns => { data_type => 'nvarchar', size => 5, is_nullable => 1 },
    bt => { data_type => 'bit', is_nullable => 1 },
    d  => { data_type => 'datetime', is_nullable => 1 },
    g  => { data_type => 'uniqueidentifier', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::FW::Result::C;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_fw_c');
  __PACKAGE__->add_columns(
    a => { data_type => 'integer' },
    b => { data_type => 'varchar', size => 40 },
    u => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('a', 'b');
}

{
  package T::FW::Result::K;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_fw_k');
  __PACKAGE__->add_columns(
    k => { data_type => 'varchar', size => 40 },
    v => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('k');
}

{
  package T::FW::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(T => 'T::FW::Result::T');
  __PACKAGE__->register_class(C => 'T::FW::Result::C');
  __PACKAGE__->register_class(K => 'T::FW::Result::K');
}

my %ADMIN;
sub admin {
  my $dbd = shift;
  return $ADMIN{$dbd} ||= do {
    my $dbh = DBI->connect(@{ $CONNECT{$dbd} }, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('SET LOCK_TIMEOUT 10000');
    $dbh;
  };
}

my @TABLES = qw(dbio_fw_t dbio_fw_c dbio_fw_k);

sub drop_tables {
  my $dbd = shift;
  admin($dbd)->do("IF OBJECT_ID('$_', 'U') IS NOT NULL DROP TABLE $_") for @TABLES;
}

sub create_tables {
  my $dbd = shift;
  drop_tables($dbd);
  admin($dbd)->do($_) for (
    'CREATE TABLE dbio_fw_t (id INT IDENTITY PRIMARY KEY, n INT NULL, ti TINYINT NULL,'
  . ' si SMALLINT NULL, s VARCHAR(5) NULL, ns NVARCHAR(5) NULL, bt BIT NULL,'
  . ' d DATETIME NULL, g UNIQUEIDENTIFIER NULL)',
    'CREATE TABLE dbio_fw_c (a INT NOT NULL, b VARCHAR(40) NOT NULL, u VARCHAR(40) NULL,'
  . ' CONSTRAINT pk_dbio_fw_c PRIMARY KEY (a, b), CONSTRAINT uq_dbio_fw_c_u UNIQUE (u))',
    'CREATE TABLE dbio_fw_k (k VARCHAR(40) NOT NULL PRIMARY KEY, v INT NULL)',
  );
}

sub empty_tables {
  my $dbd = shift;
  admin($dbd)->do("DELETE FROM $_") for @TABLES;
}

my $LONG = 'geheim42' . ('x' x 4500);
my $ODD  = qq{geheim'"x,y:z\nw};
my $MORE = qr/with \d+ bind values?\b/;

# name, seed SQL, code (gets the schema), gone (strings that must not occur),
# keep (patterns that must). A value that is only a short word is checked in
# the form the server quotes it.
my @CASES = (
  [ 'conversion failed, varchar to int', [],
    sub { $_[0]->resultset('T')->create({ n => 'geheim42' }) },
    ['geheim42'], [qr/Conversion failed/, qr/data type int/, $MORE] ],
  [ 'conversion failed, short value', [],
    sub { $_[0]->resultset('T')->create({ n => 'ab' }) },
    [qr/value 'ab'/], [qr/Conversion failed/, qr/data type int/, $MORE] ],
  [ 'conversion failed, short value with an apostrophe (written as it is)', [],
    sub { $_[0]->resultset('T')->create({ n => "a'b" }) },
    [qr/a'b/], [qr/Conversion failed/, qr/data type int/, $MORE] ],
  [ 'conversion failed, nvarchar to int', [],
    sub { $_[0]->resultset('T')->search(\[ 'n = ?', [ { sqlt_datatype => 'nvarchar' } => 'geheim42' ] ])->all },
    ['geheim42'], [qr/Conversion failed/, qr/data type int/, $MORE] ],
  [ 'conversion failed, value over 4000 bytes', [],
    sub { $_[0]->resultset('T')->create({ n => $LONG }) },
    ['geheim42', 'xxxxxxxxxxxxxxxx'], [qr/Conversion failed|overflow|convert/i, $MORE] ],
  [ 'overflowed INT1', [],
    sub { $_[0]->resultset('T')->create({ ti => '3000000000' }) },
    ['3000000000'], [qr/overflow|Conversion failed/i, $MORE] ],
  [ 'overflowed INT2', [],
    sub { $_[0]->resultset('T')->create({ si => '3000000000' }) },
    ['3000000000'], [qr/overflow|Conversion failed/i, $MORE] ],
  [ 'primary key twice (varchar)', [],
    sub { my $rs = $_[0]->resultset('K'); $rs->create({ k => 'geheim42', v => 1 }); $rs->create({ k => 'geheim42', v => 2 }) },
    ['geheim42'], [qr/PRIMARY KEY constraint/, qr/dbio_fw_k/, qr/duplicate key value/, $MORE] ],
  [ 'primary key twice (composite)', [],
    sub { my $rs = $_[0]->resultset('C'); $rs->create({ a => 7, b => 'geheim42' }); $rs->create({ a => 7, b => 'geheim42' }) },
    ['geheim42', qr/duplicate key value is \(7/], [qr/pk_dbio_fw_c/, qr/dbio_fw_c/, qr/duplicate key value/, $MORE] ],
  [ 'unique constraint twice', [],
    sub { my $rs = $_[0]->resultset('C'); $rs->create({ a => 1, b => 'x1', u => 'geheim@x.y' }); $rs->create({ a => 2, b => 'x2', u => 'geheim@x.y' }) },
    ['geheim@x.y'], [qr/uq_dbio_fw_c_u/, qr/dbio_fw_c/, qr/duplicate key value/, $MORE] ],
  [ 'truncated varchar', [],
    sub { $_[0]->resultset('T')->create({ s => 'geheim42-zu-lang' }) },
    ['gehei', 'geheim42'], [qr/would be truncated/, qr/dbio_fw_t/, qr/column 's'/, qr/Truncated value/, $MORE] ],
  [ 'truncated nvarchar', [],
    sub { $_[0]->resultset('T')->create({ ns => 'geheim42-zu-lang' }) },
    ['gehei', 'geheim42'], [qr/would be truncated/, qr/dbio_fw_t/, qr/column 'ns'/, qr/Truncated value/, $MORE] ],
  [ 'truncated, apostrophe in the value', [],
    sub { $_[0]->resultset('T')->create({ s => "ge'he'im42-zu-lang" }) },
    [qr/ge'he/, qr/ge''he/, 'im42'], [qr/would be truncated/, qr/column 's'/, qr/Truncated value/, $MORE] ],
  [ 'syntax error near a value', [],
    sub { $_[0]->resultset('T')->search(\[ 's = ? ?', 'ok1234', 'geheim42' ])->all },
    ['geheim42'], [qr/Incorrect syntax|Must declare|syntax/i] ],
  [ 'syntax error, value from the SQL kept', [],
    sub { $_[0]->resultset('T')->search(\[ "s = 'literal-im-sql' AND n = ? ?", 'ok1234', 'geheim42' ])->all },
    ['geheim42'], [qr/literal-im-sql/, qr/Incorrect syntax|Must declare|syntax/i] ],
  [ 'literal in the statement stays, bound value goes', [],
    sub { $_[0]->resultset('T')->search(\[ "s = 'literal-im-sql' AND n = ?", 'geheim42' ])->all },
    ['geheim42'], [qr/literal-im-sql/, qr/Conversion failed/, qr/data type int/] ],
  [ 'MERGE inserts a duplicate', ["INSERT INTO dbio_fw_c (a, b) VALUES (1, 'geheim42')"],
    sub {
      $_[0]->storage->dbh_do(sub {
        $_[1]->do(
          'MERGE dbio_fw_c AS t USING (SELECT 1 AS a, ? AS b) AS s ON t.a = s.a AND t.b = s.b + \'#\''
        . ' WHEN NOT MATCHED THEN INSERT (a, b) VALUES (s.a, s.b);', undef, 'geheim42');
      });
    },
    ['geheim42'], [qr/PRIMARY KEY constraint/, qr/pk_dbio_fw_c/, qr/duplicate key value/] ],
  [ 'populate, void, duplicate in the data', [],
    sub { $_[0]->resultset('K')->populate([ { k => 'a1', v => 1 }, { k => 'geheim42', v => 2 }, { k => 'geheim42', v => 3 } ]); () },
    ['geheim42'], [qr/PRIMARY KEY constraint|duplicate key/, qr/dbio_fw_k/] ],
  [ 'populate, list, duplicate in the data', [],
    sub { my @r = $_[0]->resultset('K')->populate([ { k => 'a1', v => 1 }, { k => 'geheim42', v => 2 }, { k => 'geheim42', v => 3 } ]); () },
    ['geheim42'], [qr/PRIMARY KEY constraint|duplicate key/, qr/dbio_fw_k/] ],
  [ 'populate, void, conversion', [],
    sub { $_[0]->resultset('K')->populate([ { k => 'a1', v => 1 }, { k => 'a2', v => 'geheim42' } ]); () },
    ['geheim42'], [qr/Conversion failed/, qr/data type int/] ],
  [ 'update a key to an existing value', ["INSERT INTO dbio_fw_k (k) VALUES ('geheim42')", "INSERT INTO dbio_fw_k (k) VALUES ('other')"],
    sub { $_[0]->resultset('K')->search({ k => 'other' })->update({ k => 'geheim42' }) },
    ['geheim42'], [qr/PRIMARY KEY constraint/, qr/dbio_fw_k/, qr/duplicate key value/, qr/bind value/] ],
  [ 'value with quotes, comma, colon, newline (duplicate)', [],
    sub { my $rs = $_[0]->resultset('K'); $rs->create({ k => $ODD }); $rs->create({ k => $ODD }) },
    ['geheim', 'y:z', 'x,y'], [qr/PRIMARY KEY constraint/, qr/dbio_fw_k/, qr/duplicate key value/] ],
  [ 'value with quotes, comma, colon, newline (conversion)', [],
    sub { $_[0]->resultset('T')->create({ n => $ODD }) },
    ['geheim', 'y:z', 'x,y'], [qr/Conversion failed/, qr/data type int/] ],
  [ 'bit', [],
    sub { $_[0]->resultset('T')->create({ bt => 'geheim42' }) },
    ['geheim42'], [qr/Conversion failed/, qr/data type bit/] ],
  [ 'datetime', [],
    sub { $_[0]->resultset('T')->create({ d => 'geheim42' }) },
    ['geheim42'], [qr/Conversion failed|date/i] ],
  [ 'uniqueidentifier', [],
    sub { $_[0]->resultset('T')->create({ g => 'geheim42' }) },
    ['geheim42'], [qr/Conversion failed|uniqueidentifier/i] ],
);

sub texts_of {
  my $err = shift;
  my @t = ("$err");
  if (Scalar::Util::blessed($err)) {
    push @t, map { $err->$_ } grep { $err->can($_) } qw(message detail);
  }
  return grep { defined } @t;
}

my @WAYS;
push @WAYS, [ 'DBD::ODBC',                  'DBD::ODBC',   0 ] if $CONNECT{'DBD::ODBC'};
push @WAYS, [ 'DBD::Sybase',                'DBD::Sybase', 0 ] if $CONNECT{'DBD::Sybase'};
push @WAYS, [ 'DBD::Sybase (NoBindVars)',   'DBD::Sybase', 1 ] if $CONNECT{'DBD::Sybase'};

require Scalar::Util;

END {
  for my $dbd (keys %ADMIN) { eval { drop_tables($dbd) } }
}

for my $way (@WAYS) {
  my ($label, $dbd, $nobindvars) = @$way;

  create_tables($dbd);

  my $schema = T::FW::Schema->connect(@{ $CONNECT{$dbd} });
  if ($nobindvars) {
    # set, not read: reading the capability would connect to detect it
    $schema->storage->_use_typeless_placeholders(0);
  }
  $schema->storage->dbh;

  if ($nobindvars) {
    ok $schema->storage->isa('DBIO::Storage::DBI::NoBindVars'), "$label: the storage is a NoBindVars class";
  }

  for my $case (@CASES) {
    my ($name, $seed, $code, $gone, $keep) = @$case;
    empty_tables($dbd);
    admin($dbd)->do($_) for @$seed;

    my $err;
    eval { $code->($schema); 1 } and $err = undef or $err = $@;

    unless ($err) {
      fail "$label: $name: the statement is refused";
      next;
    }

    my @texts = texts_of($err);
    diag "$label: $name\n" . substr($texts[0], 0, 700) if $ENV{DBIO_TEST_FW_DUMP};
    my @leaks;
    for my $g (@$gone) {
      for my $t (@texts) {
        push @leaks, "$g" if ref $g ? $t =~ $g : index($t, $g) >= 0;
      }
    }
    ok !@leaks, "$label: $name: no value in the exception"
      or diag "leaked: @leaks\n", map { "---\n$_\n" } @texts;

    for my $k (@$keep) {
      like $texts[0], $k, "$label: $name: still says $k";
    }
  }

  drop_tables($dbd);
}

done_testing;
