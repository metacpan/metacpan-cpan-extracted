use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Core ();
use DBIO::MSSQL::Deploy;
use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Introspect;

# LIVE (karr k76). Counterpart of t/107-index-filter.t (offline).
#
# Shows against SQL Server:
#   A. the server hands filter_definition back in its own form, and the
#      introspect reads it (has_filter / filter_definition);
#   B. the DDL of a declared filtered index (mssql_indexes and the canonical
#      declaration) runs, and the server's filter is the declared one;
#   C. an upgrade adds, changes and removes a filter (drop + create), and a
#      second diff is empty -- including where the declaration says
#      "a = 1" and the server says "([a]=(1))";
#   D. the server's own refusals the DDL anticipates: a filter on a clustered
#      index, on a unique constraint.
#
# One database of its own, dbio_mssql_k76_<pid>_<n>, dropped at the end.

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

my $seq = 0;
sub schema_class {
  my ($tag, %o) = @_;
  my $sc = "K76::${tag}::Schema";
  eval "package $sc; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); 1" or die $@;
  my $rc = "$sc\::Result::T";
  eval "package $rc; use base 'DBIO::Core'; __PACKAGE__->load_components('MSSQL::Result'); 1" or die $@;
  $rc->table('t');
  $rc->add_columns(id => { data_type => 'integer' },
    a => { data_type => 'integer', is_nullable => 1 },
    b => { data_type => 'varchar', size => 20, is_nullable => 1 });
  $rc->set_primary_key('id');
  $rc->mssql_index($_ => $o{hand}{$_}) for sort keys %{ $o{hand} || {} };
  $rc->result_source_instance->add_index_declaration($_) for @{ $o{idx} || [] };
  $sc->register_class(T => $rc);
  return $sc;
}

sub filters {
  my ($dbh) = @_;
  return { map { $_->[0] => $_->[1] } @{ $dbh->selectall_arrayref(q{
    SELECT name, filter_definition FROM sys.indexes
    WHERE object_id = OBJECT_ID('t') AND name LIKE 'ix[_]%'}) } };
}

sub scenario {
  my ($name, %arg) = @_;
  my $db = sprintf 'dbio_mssql_k76_%d_%d', $$, ++$seq;
  my $dsn_db = $dsn;
  $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
    or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;
  $admin->do("CREATE DATABASE [$db]");
  my $ok = eval {
    my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
    $dbh->do($_) for @{ $arg{before} || [] };
    my $sc = schema_class($name =~ s/\W/_/gr, %{ $arg{declare} || {} });
    my $schema = $sc->connect($dsn_db, $user, $pass, { %conn });
    my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
    my $diff = $deploy->diff;
    ok $diff->has_changes, "$name: the diff sees the change";
    my $applied = eval { $deploy->apply($diff, allow_destructive => 1); 1 };
    ok $applied, "$name: the server accepts the upgrade" or diag $@ . "\n" . $diff->as_sql;
    $arg{check}->($dbh, $diff) if $applied;
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
}

my $tbl = 'CREATE TABLE t (id BIGINT NOT NULL CONSTRAINT PK_t PRIMARY KEY, a BIGINT NULL, b NVARCHAR(20) NULL)';

# A + B + C1: a new filtered index (hand-declared and canonical), forms read back
scenario('new filtered indexes',
  before  => [ $tbl ],
  declare => {
    hand => { ix_hand => { columns => ['b'], where => 'a IS NOT NULL' } },
    idx  => [ { name => 'ix_canon', columns => ['b'], unique => 1,
                driver => { mssql => { where => 'a = 1 AND b IS NOT NULL' } } },
              { name => 'ix_plain', columns => ['a'], driver => { mssql => {} } } ],
  },
  check => sub {
    my $f = filters($_[0]);
    is $f->{ix_hand}, '([a] IS NOT NULL)', 'the server reports the filter in its own form';
    is $f->{ix_canon}, '([a]=(1) AND [b] IS NOT NULL)', '... an AND of two predicates too';
    is $f->{ix_plain}, undef, 'an index without where has no filter';
    my $m = DBIO::MSSQL::Introspect->new(dbh => $_[0])->model;
    is $m->{indexes}{t}{ix_hand}{filter}, '([a] IS NOT NULL)', 'introspect: filter of a filtered index';
    is $m->{indexes}{t}{ix_plain}{filter}, undef, 'introspect: none for the plain one';
    ok $m->{indexes}{t}{ix_canon}{is_unique}, 'introspect: ... and it is unique';
  });

# C2: the filter changes
scenario('filter changed',
  before  => [ $tbl, 'CREATE INDEX ix_x ON t (b) WHERE a = 1' ],
  declare => { hand => { ix_x => { columns => ['b'], where => 'a = 2' } } },
  check   => sub { is filters($_[0])->{ix_x}, '([a]=(2))', 'the index was replaced, with the new filter' });

# C3: the filter is added
scenario('filter added',
  before  => [ $tbl, 'CREATE INDEX ix_x ON t (b)' ],
  declare => { hand => { ix_x => { columns => ['b'], where => 'a IS NOT NULL' } } },
  check   => sub { is filters($_[0])->{ix_x}, '([a] IS NOT NULL)', 'the filter was added' });

# C4: the filter is removed
scenario('filter removed',
  before  => [ $tbl, 'CREATE INDEX ix_x ON t (b) WHERE a = 1' ],
  declare => { hand => { ix_x => { columns => ['b'] } } },
  check   => sub { is filters($_[0])->{ix_x}, undef, 'the filter was removed' });

# C5: server form and declared form of the same filter: nothing to do. The
# classes declare the same index in another spelling; the diff is empty at once
# (the scenario's first check expects a change, so this is done by hand).
{
  my $db = sprintf 'dbio_mssql_k76_%d_%d', $$, ++$seq;
  my $dsn_db = $dsn;
  $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
    or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;
  $admin->do("CREATE DATABASE [$db]");
  my $ok = eval {
    my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
    $dbh->do($_) for $tbl, q{CREATE INDEX ix_a ON t (b) WHERE a = 1 AND b IS NOT NULL},
      q{CREATE INDEX ix_in ON t (b) WHERE a IN (1, 2, 3)},
      q{CREATE INDEX ix_neg ON t (b) WHERE a >= -1},
      q{CREATE INDEX ix_str ON t (a) WHERE b = N'it''s'};
    my $sc = schema_class('spelling', hand => {
      ix_a   => { columns => ['b'], where => "[a]=1  and  b is NOT null" },
      ix_in  => { columns => ['b'], where => 'a in (1,2,3)' },
      ix_neg => { columns => ['b'], where => '(a>=-1)' },
      ix_str => { columns => ['a'], where => "b = N'it''s'" },
    });
    my $schema = $sc->connect($dsn_db, $user, $pass, { %conn });
    my $diff = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
    ok !$diff->has_changes, 'spelling: another spelling of the same filters is no change'
      or diag $diff->summary . "\n" . $diff->as_sql;
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
}

# D. the server's refusals, and the driver's before them
{
  my $db = sprintf 'dbio_mssql_k76_%d_%d', $$, ++$seq;
  my $dsn_db = $dsn;
  $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
    or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;
  $admin->do("CREATE DATABASE [$db]");
  my $ok = eval {
    my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
    $dbh->do('CREATE TABLE h (id INT NOT NULL, a INT NULL)');
    my $e = eval { $dbh->do('CREATE CLUSTERED INDEX ixc ON h (id) WHERE a = 1'); 1 } ? '' : "$@";
    like $e, qr/Incorrect syntax near 'WHERE'|WHERE/, 'server: a filter on a clustered index is a syntax error';
    $e = eval { $dbh->do('ALTER TABLE h ADD CONSTRAINT uq UNIQUE (id) WHERE a = 1'); 1 } ? '' : "$@";
    like $e, qr/WHERE/, 'server: a filter on a unique constraint is a syntax error';
    $e = eval { $dbh->do('CREATE INDEX ixo ON h (id) WHERE a = 1 OR a = 2'); 1 } ? '' : "$@";
    like $e, qr/'OR'|\bOR\b/, 'server: OR in a filter is refused (the DDL passes the predicate on)';
    my $sc = schema_class('refused', hand => { ix_c => { columns => ['b'], kind => 'clustered', where => 'a = 1' } });
    my $err = eval { DBIO::MSSQL::DDL->install_ddl($sc); 1 } ? '' : "$@";
    like $err, qr/refus.*filter|filter.*refus/is, 'driver: a filter on a clustered index is refused before the server';
    1;
  };
  my $err = $@;
  eval {
    $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
      . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
    1;
  } or diag "could not drop $db: $@";
  die $err unless $ok;
}

done_testing;
