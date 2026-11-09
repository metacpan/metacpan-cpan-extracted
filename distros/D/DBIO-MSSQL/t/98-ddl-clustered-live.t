use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::MSSQL::DDL;
use DBIO::Exception ();

# LIVE (karr k71, written 2026-10-19, NOT yet run: no live runs that day).
# Counterpart of t/96 (offline).
#
# What it has to show against SQL Server 2022:
#   A. A PRIMARY KEY is CLUSTERED by default, so a second, declared clustered
#      index on the same table is refused by the server with Msg 1902 -- the
#      driver refuses the same declaration before the server sees it.
#   B. A table with a primary key and a NONCLUSTERED declared index runs
#      through, and the catalog says: PK CLUSTERED, index NONCLUSTERED.
#   C. A table WITHOUT a primary key and a declared CLUSTERED index runs
#      through, and the catalog says: CLUSTERED.
#
# One database of its own, _dbio_k71c_<pid>_<n>, dropped at the end.

my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/} ],
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/}      ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN} (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless @paths;
my ($dsn, $user, $pass) = @{ $paths[0] };
my ($dbd) = $dsn =~ /^dbi:(\w+)/i;

my %conn = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);
my $admin = DBI->connect($dsn, $user, $pass, \%conn);
my $db = sprintf '_dbio_k71c_%d_1', $$;
my $dsn_db = $dsn;
$dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
  or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;

sub statements { grep { /\S/ } split /\n\n+/, $_[0] }

my $n = 0;
sub schema_with {
  my (%o) = @_;
  my $schema = 'K71ClLive::S' . ++$n;
  my $pk = $o{pk} ? q{__PACKAGE__->set_primary_key('id');} : '';
  eval qq{
    package $schema; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL');
    package ${schema}::Result::T; use DBIO 'Core';
    __PACKAGE__->table('$o{table}');
    __PACKAGE__->add_columns(id => { data_type => 'integer' },
      name => { data_type => 'varchar', size => 20 });
    $pk
    1;
  } or die $@;
  my $src = "${schema}::Result::T"->result_source_instance;
  $src->add_index_declaration($_) for @{ $o{idx} };
  $schema->register_class(T => "${schema}::Result::T");
  return $schema;
}

$admin->do("CREATE DATABASE [$db]");
my $ok = eval {
  my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
  my $clustered = { name => 'k71c_c', columns => ['name'],
                    driver => { mssql => { kind => 'clustered' } } };
  my $nonclustered = { name => 'k71c_n', columns => ['name'],
                       driver => { mssql => { kind => 'nonclustered' } } };

  # A. the server's own refusal, and the driver's before it
  {
    my $schema = schema_with(table => 'a_pk', pk => 1, idx => [$clustered]);
    my $err = eval { DBIO::MSSQL::DDL->install_ddl($schema); 1 } ? '' : $@;
    like "$err", qr/refus/, 'driver: clustered index + primary key is refused';

    # the DDL as it would be without the driver's check: the same table by hand
    my $server = eval {
      $dbh->do('CREATE TABLE a_pk (id int NOT NULL, name nvarchar(20) NOT NULL, PRIMARY KEY (id))');
      $dbh->do('CREATE CLUSTERED INDEX k71c_c ON a_pk (name)');
      1;
    } ? '' : $@;
    like $server, qr/1902|clustered index/i,
      'server: the same declaration fails (Msg 1902: one clustered index per table)';
  }

  # B. primary key + nonclustered index runs
  {
    my $schema = schema_with(table => 'b_pk', pk => 1, idx => [$nonclustered]);
    my $ddl = DBIO::MSSQL::DDL->install_ddl($schema);
    my $err = eval { $dbh->do($_) for statements($ddl); 1 } ? '' : $@;
    is $err, '', 'PK + nonclustered index: the server accepts the DDL';
    my %type = map { @$_ } @{ $dbh->selectall_arrayref(
      q{SELECT i.name, i.type_desc FROM sys.indexes i
        WHERE i.object_id = OBJECT_ID('b_pk') AND i.name IS NOT NULL}) };
    my ($pk) = grep { /^PK_|^PK__/ } keys %type;
    is $type{k71c_n}, 'NONCLUSTERED', '... the declared index is nonclustered';
    is $type{$pk}, 'CLUSTERED', '... the primary key stays CLUSTERED, as before';
  }

  # C. no primary key + clustered index runs
  {
    my $schema = schema_with(table => 'c_heap', pk => 0, idx => [$clustered]);
    my $ddl = DBIO::MSSQL::DDL->install_ddl($schema);
    my $err = eval { $dbh->do($_) for statements($ddl); 1 } ? '' : $@;
    is $err, '', 'no PK + clustered index: the server accepts the DDL';
    my ($t) = $dbh->selectrow_array(
      q{SELECT type_desc FROM sys.indexes
        WHERE object_id = OBJECT_ID('c_heap') AND name = 'k71c_c'});
    is $t, 'CLUSTERED', '... and the catalog says CLUSTERED';
  }
  1;
};
my $err = $@;
eval {
  $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
    . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
  1;
} or diag "could not drop $db: $@";
die $err unless $ok;

done_testing;
