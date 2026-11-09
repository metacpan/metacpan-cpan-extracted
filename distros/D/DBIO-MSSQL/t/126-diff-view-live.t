use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Core ();
use DBIO::MSSQL::Deploy;
use DBIO::MSSQL::Introspect;

# LIVE (karr k82): the diff creates, replaces and drops views. Every scenario
# starts from a database built with plain SQL, upgrades it to a schema of
# classes, checks what the server holds, and a second diff must be empty. Each
# scenario has a database of its own, _dbio_k82_<pid>_<n>, dropped at the end;
# nothing else is touched. The statements are pinned offline in
# t/125-diff-view.t.

my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/} ],
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/}      ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN} (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless @paths;

my %conn = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);
my $seq = 0;

# source: [ class, table, { col => \%info }, pk, view definition or undef ]
sub build_schema {
  my ($tag, @sources) = @_;
  my $schema_class = "K82::${tag}::Schema";
  eval "package $schema_class; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); 1"
    or die $@;
  for my $s (@sources) {
    my ($name, $table, $cols, $pk, $view) = @$s;
    my $rc = "$schema_class\::Result::$name";
    eval "package $rc; use base 'DBIO::Core'; 1" or die $@;
    $rc->table_class('DBIO::ResultSource::View') if defined $view;
    $rc->table($table);
    $rc->result_source_instance->view_definition($view) if defined $view;
    $rc->add_columns(map { ($_ => $cols->{$_}) } sort keys %$cols);
    $rc->set_primary_key($pk) if $pk;
    $schema_class->register_class($name => $rc);
  }
  return $schema_class;
}

for my $path (@paths) {
  my ($dsn, $user, $pass) = @$path;
  my ($dbd) = $dsn =~ /^dbi:(\w+)/i;
  my $admin = DBI->connect($dsn, $user, $pass, \%conn);

  my $scenario = sub {
    my ($name, %arg) = @_;
    $name = "$dbd: $name";
    my $db = sprintf '_dbio_k82_%d_%d', $$, ++$seq;
    my $dsn_db = $dsn;
    $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
      or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;

    $admin->do("CREATE DATABASE [$db]");
    my $ok = eval {
      my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
      $dbh->do($_) for @{ $arg{before} || [] };

      my $schema_class = build_schema($name =~ s/\W/_/gr, @{ $arg{after} });
      my $schema = $schema_class->connect($dsn_db, $user, $pass, { %conn });
      my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);

      my $diff = $deploy->diff;
      ok $diff->has_changes, "$name: the diff sees the change";
      my $applied = eval { $deploy->apply($diff, allow_destructive => 1); 1 };
      ok $applied, "$name: the server accepts the upgrade" or diag $@ . "\n" . $diff->as_sql;

      $arg{check}->($dbh) if $applied;

      my $again = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
      ok !$again->has_changes, "$name: the second diff is empty"
        or diag $again->summary . "\n" . $again->as_sql;
      $schema->storage->disconnect;
      $dbh->disconnect;
      1;
    };
    my $err = $@;
    eval {
      $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
        . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
      1;
    } or diag "could not drop $db: $@";
    die $err unless $ok;
  };

  my $int  = { data_type => 'int' };
  my $nvc  = { data_type => 'varchar', size => 20, is_nullable => 1 };
  my $views = sub {
    join ',', sort map { $_->[0] }
      @{ $_[0]->selectall_arrayref('SELECT s.name + \'.\' + v.name FROM sys.views v JOIN sys.schemas s ON s.schema_id = v.schema_id') };
  };
  my $rows = sub { join ',', map { $_->[0] } @{ $_[0]->selectall_arrayref("SELECT $_[1] FROM $_[2] ORDER BY 1") } };
  my $table_sql = 'CREATE TABLE base (id INT NOT NULL PRIMARY KEY, name NVARCHAR(20) NULL)';
  my @base = ([ Base => 'base', { id => $int, name => $nvc }, 'id' ]);

  # the model reads the stored text
  {
    my $db = sprintf '_dbio_k82_%d_%d', $$, ++$seq;
    my $dsn_db = $dsn;
    $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
      or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;
    $admin->do("CREATE DATABASE [$db]");
    my $ok = eval {
      my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
      $dbh->do($table_sql);
      $dbh->do("CREATE VIEW dbo.v AS SELECT id,\n  name FROM base");
      $dbh->do('CREATE SCHEMA vs82');
      $dbh->do('CREATE VIEW vs82.w AS SELECT id FROM dbo.base');
      my $m = DBIO::MSSQL::Introspect->new(dbh => $dbh, schemas => ['vs82'])->model;
      is $m->{tables}{v}{kind}, 'view', "$dbd: introspect: v is a view";
      like $m->{tables}{v}{definition}, qr/\ACREATE VIEW dbo\.v AS SELECT id,\r?\n  name FROM base\z/,
        "$dbd: introspect: the stored text of a view";
      like $m->{tables}{'vs82.w'}{definition}, qr/\ACREATE VIEW vs82\.w AS/,
        "$dbd: introspect: the view of another schema";
      ok !exists $m->{tables}{base}{definition}, "$dbd: introspect: a table has none";
      $dbh->do('CREATE VIEW z AS SELECT id FROM dbo.v');
      $dbh->do('CREATE VIEW vs82.x AS SELECT id FROM dbo.z');
      $dbh->do('CREATE VIEW vs82.y AS SELECT id FROM vs82.w');
      $m = DBIO::MSSQL::Introspect->new(dbh => $dbh, schemas => ['vs82'])->model;
      is_deeply $m->{tables}{z}{depends_on}, ['v'], "$dbd: introspect: the view a view reads";
      is_deeply $m->{tables}{'vs82.x'}{depends_on}, ['z'], "$dbd: introspect: across the schema border";
      is_deeply $m->{tables}{'vs82.y'}{depends_on}, ['vs82.w'], "$dbd: introspect: inside another schema";
      ok !exists $m->{tables}{v}{depends_on}, "$dbd: introspect: a view that reads a table only";
      $dbh->disconnect;
      1;
    };
    my $err = $@;
    $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
      . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
    die $err unless $ok;
  }

  $scenario->('view added',
    before => [ $table_sql ],
    after  => [ @base, [ V => 'v', { id => $int, name => $nvc }, undef, 'SELECT id, name FROM base' ] ],
    check  => sub {
      is $views->($_[0]), 'dbo.v', 'the view exists';
    });

  $scenario->('view dropped',
    before => [ $table_sql, 'CREATE VIEW v AS SELECT id FROM base', 'INSERT INTO base (id, name) VALUES (1, N\'x\')' ],
    after  => [ @base ],
    check  => sub {
      is $views->($_[0]), '', 'the view is gone';
      is $rows->($_[0], 'id', 'base'), '1', 'the table and its row stay';
    });

  $scenario->('view definition changed',
    before => [ $table_sql, 'CREATE VIEW v AS SELECT id FROM base',
                'INSERT INTO base (id, name) VALUES (1, N\'x\')' ],
    after  => [ @base, [ V => 'v', { id => $int, name => $nvc }, undef, 'SELECT id, name FROM base' ] ],
    check  => sub {
      is $rows->($_[0], 'name', 'v'), 'x', 'the view reads the new column';
    });

  $scenario->('view in a schema, schema and table new',
    before => [ $table_sql ],
    after  => [ @base,
      [ S => 'vs82.t', { id => $int }, 'id' ],
      [ V => 'vs82.v', { id => $int }, undef, 'SELECT id FROM vs82.t' ] ],
    check  => sub {
      is $views->($_[0]), 'vs82.v', 'the view is in its schema';
    });

  $scenario->('view in a schema, dropped',
    before => [ 'CREATE SCHEMA vs82', 'CREATE TABLE vs82.t (id INT NOT NULL PRIMARY KEY)',
                'CREATE VIEW vs82.v AS SELECT id FROM vs82.t' ],
    after  => [ [ S => 'vs82.t', { id => $int }, 'id' ] ],
    check  => sub {
      is $views->($_[0]), '', 'the view of the schema is gone';
    });

  $scenario->('view with a definition of more than 32768 characters, and a view over a dropped table',
    before => [ $table_sql, 'CREATE TABLE old_t (id INT NOT NULL PRIMARY KEY)',
                'CREATE VIEW ov AS SELECT id FROM old_t',
                'CREATE VIEW long_v AS SELECT id, N\'' . ('a' x 40000) . '\' AS pad FROM base' ],
    after  => [ @base,
      [ L => 'long_v', { id => $int, pad => { data_type => 'varchar', size => -1 } }, undef,
        'SELECT id, N\'' . ('b' x 40000) . '\' AS pad FROM base' ] ],
    check  => sub {
      my ($len) = $_[0]->selectrow_array('SELECT LEN(definition) FROM sys.sql_modules WHERE object_id = OBJECT_ID(N\'long_v\')');
      cmp_ok $len, '>', 40000, 'the long view holds the new text';
      my ($b) = $_[0]->selectrow_array('SELECT CHARINDEX(N\'bbb\', definition) FROM sys.sql_modules WHERE object_id = OBJECT_ID(N\'long_v\')');
      cmp_ok $b, '>', 0, 'it is the new one';
      is $views->($_[0]), 'dbo.long_v', 'the view of the dropped table is gone with it';
    });

  # views that read views, the name order the wrong one: a_top reads z_base
  my @deps = (
    [ Base => 'base', { id => $int, name => $nvc }, 'id' ],
  );
  my $zb = 'SELECT id, name FROM base';
  my $at = 'SELECT id FROM z_base';
  $scenario->('views on views, added (name order is the wrong one)',
    before => [ $table_sql ],
    after  => [ @deps,
      [ ATop  => 'a_top',  { id => $int }, undef, $at ],
      [ ZBase => 'z_base', { id => $int, name => $nvc }, undef, $zb ] ],
    check  => sub { is $views->($_[0]), 'dbo.a_top,dbo.z_base', 'both views exist' });

  $scenario->('views on views, dropped (the reader goes first)',
    before => [ $table_sql, "CREATE VIEW z_base AS $zb", "CREATE VIEW a_top AS $at" ],
    after  => [ @deps ],
    check  => sub { is $views->($_[0]), '', 'both views are gone' });

  $scenario->('views on views, both changed',
    before => [ $table_sql, "CREATE VIEW z_base AS $zb", "CREATE VIEW a_top AS $at" ],
    after  => [ @deps,
      [ ATop  => 'a_top',  { id => $int, name => $nvc }, undef, 'SELECT id, name FROM z_base' ],
      [ ZBase => 'z_base', { id => $int, name => $nvc }, undef, 'SELECT id, name FROM base WHERE id > 0' ] ],
    check  => sub { is $views->($_[0]), 'dbo.a_top,dbo.z_base', 'both views exist' });

  $scenario->('same body, another layout: no change but the table',
    before => [ $table_sql, "CREATE VIEW v AS\nSELECT   id\n  FROM base" ],
    after  => [ [ Base => 'base', { id => $int, name => $nvc, extra => $nvc }, 'id' ],
                [ V => 'v', { id => $int }, undef, 'SELECT id FROM base' ] ],
    check  => sub {
      like $_[0]->selectrow_array(q{SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID(N'v')}),
        qr/SELECT   id/, 'the view was not rewritten';
    });
}

done_testing;
