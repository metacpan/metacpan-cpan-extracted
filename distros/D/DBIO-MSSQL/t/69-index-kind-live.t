use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::MSSQL::Deploy;

# LIVE (karr k68). CREATE [UNIQUE] [CLUSTERED|NONCLUSTERED] INDEX name ON
# table (columns) is the T-SQL form; the driver used to write the kind behind
# ON <table>, which the server refuses. t/50 and t/68 pin the text offline;
# this file has a server accept it: the index is created with the kind asked
# for (sys.indexes.type_desc), and a second diff after the deploy is empty.

# Both access paths when both are configured: DBD::Sybase and DBD::ODBC.
my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/}      ],
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/} ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN} (or _ODBC_DSN), _USER and _PASS to run this test'
  unless @paths;

{
  package KindLive::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');
}
{
  package KindLive::Schema::Result::Doc;
  use DBIO::Cake;
  __PACKAGE__->load_components('MSSQL::Result');
  table 'k68_docs';
  col id   => integer auto_inc;
  col name => varchar(64);
  col slug => varchar(64);
  primary_key 'id';
  idx k68_nonc => ['name'];
  idx k68_uniq => ['slug'], type => 'unique';
}
{
  package KindLive::Schema::Result::Heap;
  use DBIO::Cake;
  __PACKAGE__->load_components('MSSQL::Result');
  table 'k68_heap';
  col name => varchar(64);
  col slug => varchar(64);
  # a heap has no clustered index yet: this one is the first
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'k68_clust', columns => ['name', 'slug'],
    driver => { mssql => { kind => 'clustered' } },
  });
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'k68_nonc_kind', columns => ['slug'],
    driver => { mssql => { kind => 'nonclustered' } },
  });
}
KindLive::Schema->register_class(Doc  => 'KindLive::Schema::Result::Doc');
KindLive::Schema->register_class(Heap => 'KindLive::Schema::Result::Heap');

for my $path (@paths) {
  my ($dsn, $user, $pass) = @$path;
  my ($dbd) = $dsn =~ /^dbi:(\w+)/i;
  my $db = '_dbio_k68_' . $$ . '_' . time();
  # keep the spelling of the key: DBD::Sybase reads `database=` and ignores
  # `Database=`, which lands on the login's default database
  my $dsn_db = $dsn;
  $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
    or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;

  my $admin = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
  $admin->do("CREATE DATABASE $db");

  my $ok = eval {
    my $schema = KindLive::Schema->connect($dsn_db, $user, $pass);
    my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);

    $deploy->install;
    pass "$dbd: install: the server accepts the generated CREATE INDEX statements";

    my $dbh = DBI->connect($dsn_db, $user, $pass, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    is $dbh->selectrow_array('SELECT DB_NAME()'), $db, "$dbd: connected to the database under test";
    my %type = map { $_->[0] => $_->[1] } @{ $dbh->selectall_arrayref(
      q{SELECT name, type_desc FROM sys.indexes WHERE name LIKE 'k68[_]%'}) };
    is $type{k68_nonc},      'NONCLUSTERED', "$dbd: idx without kind: nonclustered";
    is $type{k68_uniq},      'NONCLUSTERED', "$dbd: unique idx: nonclustered";
    is $type{k68_clust},     'CLUSTERED',    "$dbd: kind 'clustered' is a clustered index";
    is $type{k68_nonc_kind}, 'NONCLUSTERED', "$dbd: kind 'nonclustered' is a nonclustered index";
    my ($uniq) = $dbh->selectrow_array(q{SELECT is_unique FROM sys.indexes WHERE name = 'k68_uniq'});
    ok $uniq, "$dbd: the unique index is unique";
    $dbh->disconnect;

    my $diff = $deploy->diff;
    ok !$diff->has_changes, "$dbd: the second diff after the deploy is empty"
      or diag $diff->summary;
    $schema->storage->disconnect;
    1;
  };
  my $err = $@;
  eval { $admin->do("DROP DATABASE $db"); 1 } or diag "could not drop $db: $@";
  $admin->disconnect;
  die $err unless $ok;
}

done_testing;
