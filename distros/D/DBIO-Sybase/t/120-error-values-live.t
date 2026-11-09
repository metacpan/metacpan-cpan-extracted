use strict;
use warnings;
use Test::More;
use DBIO::Schema;
use DBIO::Core;

# LIVE half of ADR 0006 (core ADR 0075): the text ASE and its client library
# write into an error never holds a value of the statement.
#
# WHY IT MATTERS. ASE quotes the offending value into some of its messages
# (Msg 249/247 conversion, Msg 3604-family duplicate key) and the client
# library does the same (cs_convert / to_numeric()), also for a value that was
# a bind -- and a log or a web page then shows what the user typed, or the
# converted value the engine made of it. The claim, per form: the exception
# (or warning) names the type, column, constraint, table, message number and
# the count of bind values, and not the value; a literal of the statement
# itself stays; $dbh->errstr stays raw (only the text that is thrown is
# masked). Core masks the bound values it knows (four characters and more);
# what only the driver can mask is the shorter value, the value the engine
# converted before it quoted it (-1294967296 for 3000000000, 12345.7 for
# 12345.67) and the unquoted ones of the client library.
#
# Works in tables of its own (dbio_fw_<pid>_*) in the database of the DSN,
# dropped here; needs a login allowed to create a table, no database is
# created. Gated like the other live tests: DBIO_TEST_SYBASE_DSN, _USER and
# _PASS. What the client library does with a value differs (FreeTDS converts
# on the client side and says nothing about an int overflow, an unsigned
# value or a 'ab' for an int); each case tests what arrives.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $P = "dbio_fw_$$";
my %T = map { $_ => "${P}_$_" } qw/a b c d e/;

# One schema per storage class, the same sources in each.
sub build_schema {
  my ($name, $storage_type) = @_;

  my $schema = "FwLive::$name";
  {
    no strict 'refs';
    @{"${schema}::ISA"} = ('DBIO::Schema');
  }
  $schema->load_components('Sybase');
  $schema->storage_type($storage_type) if $storage_type;

  my %cols = (
    A => [
      id  => { data_type => 'integer' },
      d   => { data_type => 'date', is_nullable => 1 },
      ts  => { data_type => 'datetime', is_nullable => 1 },
      tm  => { data_type => 'time', is_nullable => 1 },
      bdt => { data_type => 'bigdatetime', is_nullable => 1 },
      si  => { data_type => 'smallint', is_nullable => 1 },
      ti  => { data_type => 'tinyint', is_nullable => 1 },
      dec => { data_type => 'decimal', size => [4, 1], is_nullable => 1 },
      m   => { data_type => 'money', is_nullable => 1 },
      i   => { data_type => 'integer', is_nullable => 1 },
      ui  => { data_type => 'unsigned int', is_nullable => 1 },
      c   => { data_type => 'varchar', size => 10, is_nullable => 1 },
      nn  => { data_type => 'varchar', size => 10, default_value => 'x' },
      ck  => { data_type => 'integer', is_nullable => 1 },
    ],
    B => [
      a => { data_type => 'integer' },
      b => { data_type => 'integer' },
      v => { data_type => 'varchar', size => 10, is_nullable => 1 },
    ],
    C => [
      id   => { data_type => 'integer' },
      body => { data_type => 'text', is_nullable => 1 },
    ],
    D => [
      id => { data_type => 'integer' },
      k  => { data_type => 'varchar', size => 40, is_nullable => 1 },
    ],
    E => [
      id => { data_type => 'integer' },
      k  => { data_type => 'varchar', size => 40, is_nullable => 1 },
    ],
  );
  my %table = (A => $T{a}, B => $T{b}, C => $T{c}, D => $T{d}, E => $T{e});
  my %pk = (A => ['id'], B => [qw/a b/], C => ['id'], D => ['id'], E => ['id']);

  for my $src (sort keys %cols) {
    my $class = "${schema}::Result::$src";
    {
      no strict 'refs';
      @{"${class}::ISA"} = ('DBIO::Core');
    }
    $class->table($table{$src});
    $class->add_columns(@{ $cols{$src} });
    $class->set_primary_key(@{ $pk{$src} });
    $schema->register_class($src => $class);
  }

  return $schema;
}

my %schema_class = (
  bind => build_schema('Bind'),
  nbv  => build_schema('NoBindVars', '+DBIO::Sybase::Storage::ASE::NoBindVars'),
);

my $bind_schema = $schema_class{bind}->connect($dsn, $user, $pass);
my $dbh = $bind_schema->storage->dbh;
my $freetds = ( $dbh->{syb_oc_version} || '' ) =~ /freetds/i ? 1 : 0;
note 'client library: ' . ( $dbh->{syb_oc_version} || '(unknown)' );

my $schemas = {
  bind => $bind_schema,
  nbv  => $schema_class{nbv}->connect($dsn, $user, $pass),
};

END {
  if ($dbh) {
    local ($@, $?);
    for my $t (values %T) {
      eval { local $dbh->{PrintError} = 0; $dbh->do("drop table $t") };
    }
  }
}

my @DDL = (
  "create table $T{a} (id int not null primary key, d date null, ts datetime null,"
    . " tm time null, bdt bigdatetime null, si smallint null, ti tinyint null,"
    . " dec decimal(4,1) null, m money null, i int null, ui unsigned int null,"
    . " c varchar(10) null, nn varchar(10) default 'x' not null,"
    . " ck int null constraint ${P}_ck check (ck is null or ck > 0))",
  "create table $T{b} (a int not null, b int not null, v varchar(10) null,"
    . " primary key (a, b))",
  "create table $T{c} (id int not null primary key, body text null)",
  "create table $T{d} (id int not null, k varchar(40) null)",
  "create table $T{e} (id int not null, k varchar(40) null)",
);

unless (eval { $dbh->do($_) for @DDL; 1 }) {
  my $why = "$@";
  undef $dbh;
  plan skip_all => "the tables of this test cannot be created (a login that may not create a table?): $why";
}
$dbh->do("create unique index ${P}_ie on $T{e} (k) with ignore_dup_key");

# ---------------------------------------------------------------------------
# What a form is: the schema it runs on, the code, the strings that must not
# be in the text (a string, or a qr// for the short ones), and what must be.

my $SPECIAL = qq{geheim'q"w, x:y\nzzzz};

my @cases = (
  # name, schema, code, [absent], [present]
  [ 'DATE, create (Msg 249)', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 1, d => 'geheimdate' }) },
    ['geheimdate'], [qr/DATE/, qr/with 2 bind values/, qr/Msg|number=24[79]/] ],
  [ 'DATETIME, create', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 2, ts => 'geheimts' }) },
    ['geheimts'], [qr/DATETIME/, qr/with 2 bind values/] ],
  [ 'TIME, create', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 3, tm => '25:61:61geheimtime' }) },
    ['geheimtime', '25:61:61'], [qr/TIME/, qr/with 2 bind values/] ],
  [ 'BIGDATETIME, create', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 4, bdt => 'geheimbdt' }) },
    ['geheimbdt'], [qr/BIGDATETIME/, qr/with 2 bind values/] ],
  [ 'SMALLINT 3000000000, create (converted value -1294967296)', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 5, si => 3000000000 }) },
    ['3000000000', '-1294967296'], [qr/SMALLINT/, qr/with 2 bind values/] ],
  [ 'TINYINT 300, create (three characters, short)', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 6, ti => 300 }) },
    [qr/value '300'/, qr/\b300\b[^\n]*field/], [qr/TINYINT/, qr/with 2 bind values/] ],
  [ "DATE '7', create (one character)", 'bind',
    sub { $_[0]->resultset('A')->create({ id => 7, d => '7' }) },
    [qr/value '7'/], [qr/DATE/, qr/with 2 bind values/] ],
  [ 'DECIMAL(4,1) 99999.9, create (client library)', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 8, dec => '99999.9' }) },
    ['99999.9'], [qr/DECIMAL|to_numeric|NUMERIC|overflow/i, qr/with 2 bind values/] ],
  [ "DECIMAL(4,1) 'ab', create (client library, two characters)", 'bind',
    sub { $_[0]->resultset('A')->create({ id => 9, dec => 'ab' }) },
    [qr/failed for '?ab/], [qr/to_numeric|syntax/i, qr/with 2 bind values/] ],
  [ 'DECIMAL(4,1) 12345.67, create (the client library names 12345.7)', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 10, dec => '12345.67' }) },
    ['12345.67', '12345.7'], [qr/to_numeric|overflow/i] ],
  [ 'DATETIME, update of a row found', 'bind',
    sub {
      my $row = $_[0]->resultset('A')->create({ id => 11, c => 'one' });
      $row->update({ ts => 'geheimupdate' });
    },
    ['geheimupdate'], [qr/DATETIME/, qr/with \d+ bind values/] ],
  [ 'DATE, update by search with a literal in the statement', 'bind',
    sub {
      $_[0]->resultset('A')->search({ -and => [ \"c = 'literalwhere'" ] })
        ->update({ d => 'geheimsearch' });
    },
    ['geheimsearch'], [qr/DATE/, qr/literalwhere/] ],
  [ 'value with quote, double quote, comma, colon and line break', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 12, d => $SPECIAL }) },
    ['geheim', 'q"w', 'x:y', 'zzzz'], [qr/DATE/, qr/with 2 bind values/] ],
  [ 'populate of several rows, the second one bad', 'bind',
    sub {
      $_[0]->resultset('A')->populate([
        { id => 20, d => '2020-01-01' },
        { id => 21, d => 'geheimmulti' },
        { id => 22, d => '2020-01-03' },
      ]);
    },
    ['geheimmulti'], [qr/DATE/] ],
  [ 'composite key, update of a key column onto an existing key (Msg 2601)', 'bind',
    sub {
      my $rs = $_[0]->resultset('B');
      $rs->create({ a => 1, b => 2, v => 'one' });
      $rs->create({ a => 3, b => 4, v => 'two' });
      $rs->find({ a => 1, b => 2 })->update({ a => 3, b => 4 });
    },
    [qr/\(3, 4\)/, qr/key[^\n]*\b3\b[^\n]*\b4\b/], [qr/duplicate key/i, qr/\Q$T{b}\E/] ],
  [ 'DATE in a WHERE, select', 'bind',
    sub { $_[0]->resultset('A')->search({ d => 'geheimwhere' })->all },
    ['geheimwhere'], [qr/DATE/, qr/with 1 bind value/] ],
  [ 'NOT NULL column (Msg 515): column and table stay', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 23, nn => undef }) },
    [], [qr/\bnn\b/, qr/\Q$T{a}\E/] ],
  [ 'check constraint (Msg 548): the constraint stays, the value does not', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 24, ck => -123456 }) },
    ['-123456'], [qr/\Q${P}_ck\E/] ],
  [ 'string too long (Msg 9502)', 'bind',
    sub { $_[0]->resultset('A')->create({ id => 25, c => 'geheimlang12345' }) },
    ['geheimlang12345'], [qr/truncat|9502/i, qr/with 2 bind values/] ],
  [ 'create unique index over duplicate rows (statement without binds)', 'bind',
    sub {
      $_[0]->resultset('D')->create({ id => $_, k => 'geheimdup' }) for 1, 2;
      $_[0]->storage->dbh_do(sub { $_[1]->do("create unique index ${P}_id on $T{d} (k)") });
    },
    ['geheimdup'], [qr/duplicate key/i] ],
  [ 'create unique index over duplicate rows, the key with a line break', 'bind',
    sub {
      $_[0]->storage->dbh_do(sub {
        $_[1]->do("delete from $T{d}");
        $_[1]->do("insert into $T{d} values ($_, 'geheimzeile' + char(10) + 'zweitezeile')") for 1, 2;
        $_[1]->do("create unique index ${P}_id2 on $T{d} (k)");
      });
    },
    ['geheimzeile', 'zweitezeile'], [qr/duplicate key/i] ],
  [ 'DATE, create on the NoBindVars storage (the statement carries the value)', 'nbv',
    sub { $_[0]->resultset('A')->create({ id => 30, d => 'geheimnbv' }) },
    ['geheimnbv'], [qr/DATE/, qr/for Statement/] ],
  [ 'SMALLINT, create on the NoBindVars storage', 'nbv',
    sub { $_[0]->resultset('A')->create({ id => 31, si => 3000000000 }) },
    ['3000000000', '-1294967296'], [qr/SMALLINT/] ],
  [ 'DECIMAL(4,1), create on the NoBindVars storage', 'nbv',
    sub { $_[0]->resultset('A')->create({ id => 32, dec => '99999.9' }) },
    ['99999.9'], [qr/to_numeric|overflow|DECIMAL|NUMERIC/i] ],
  [ 'populate on the NoBindVars storage, the second row bad', 'nbv',
    sub {
      $_[0]->resultset('A')->populate([
        { id => 33, d => '2020-01-01' },
        { id => 34, d => 'geheimnbvmulti' },
      ]);
    },
    ['geheimnbvmulti'], [qr/DATE/] ],
);

# the LOB path: over FreeTDS the content is refused before anything is sent and
# the message names table and column; over Open Client the content is written
# in a second step and a failure there goes through the same seam
push @cases, [ 'TEXT column, create with content', 'bind',
  sub { $_[0]->resultset('C')->create({ id => 40, body => 'geheimtextinhalt' }) },
  ['geheimtextinhalt'], [qr/\bbody\b/, qr/\Q$T{c}\E/] ]
  if $freetds;

for my $case (@cases) {
  my ($name, $which, $code, $absent, $present) = @$case;
  my $schema = $schemas->{$which};

  my $error = do {
    local $SIG{__WARN__} = sub { };
    local $@;
    eval { $code->($schema); 1 } ? undef : "$@";
  };

  subtest $name => sub {
    ok defined $error, 'the statement fails' or return;
    note substr($error, 0, 400);

    for my $a (@$absent) {
      if (ref $a) { unlike $error, $a, "no value: $a" }
      else        { ok index($error, $a) < 0, "no value: $a" }
    }
    like $error, $_, "kept: $_" for @$present;
  };
}

# ---------------------------------------------------------------------------
# The client library's warning (no error: the row is written with what the
# library made of the value). It is a warn() out of DBD::Sybase.

for my $which (qw/bind nbv/) {
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { $schemas->{$which}->resultset('A')->create({ id => $which eq 'bind' ? 50 : 51, m => 'geheimmoney' }) };
  }
  subtest "MONEY, warning of the client library ($which)" => sub {
    my @cs = grep { /cs_convert/ } @warnings;
    if (!@cs) {
      pass('this client library says nothing about the value');
      return;
    }
    unlike join('', @cs), qr/geheimmoney/, 'the warning holds no value';
    like join('', @cs), qr/cs_convert failed \(to_money\(\*\*\*\)\)/, 'the conversion stays named';
  };
}

# ---------------------------------------------------------------------------
# $dbh->errstr stays raw: only the text that is thrown is masked.

subtest 'errstr of the handle stays as the engine wrote it' => sub {
  my $schema = $schemas->{bind};
  my $dbh2 = $schema->storage->dbh;
  my $err;
  {
    local $dbh2->{PrintError} = 0;
    my $sth = $dbh2->prepare("insert into $T{a} (id, d) values (?, ?)");
    # core's error handler throws the masked text; the handle keeps its own
    eval { $sth->execute(60, 'geheimerrstr') };
    $err = $sth->errstr // $dbh2->errstr;
  }
  SKIP: {
    skip 'no error on this client library', 1 unless defined $err;
    like $err, qr/geheimerrstr/, 'the handle keeps the raw text';
  }
};

# ---------------------------------------------------------------------------
# Duplicate key under ignore_dup_key (Msg 3604): documented, no value in the
# message, no error.

subtest 'ignore_dup_key: no error, the message holds no key' => sub {
  my $rs = $schemas->{bind}->resultset('E');
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $rs->create({ id => 1, k => 'geheimignore' });
  my $err = do { local $@; eval { $rs->create({ id => 2, k => 'geheimignore' }); 1 } ? undef : "$@" };
  is $rs->count, 1, 'the second row was ignored';
  unlike( ( $err // '' ) . join('', @warnings), qr/geheimignore/, 'no key in a message' );
};

done_testing;
