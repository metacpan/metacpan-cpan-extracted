use strict;
use warnings;
use Test::More;
use DBI;

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::SQLite::Introspect ();
use DBIO::SQLite::Deploy ();

# karr k79 -- the shared case ddl-auto-increment found that Introspect never
# reported is_auto_increment, although the column assigns its own keys.
#
# The invariant, checked per table against this libsqlite: if an INSERT that
# leaves the key out leaves the engine with a key, introspection reports
# is_auto_increment for that column -- and for no column whose key stays NULL.
# The AUTOINCREMENT keyword is not what is reported (ADR 0004: the DDL does not
# write it), so it is one case among the others.

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
  { RaiseError => 1, PrintError => 0 });

my @cases = (
  { table => 'alias_inline',  col => 'id',
    ddl => 'CREATE TABLE alias_inline (id INTEGER PRIMARY KEY, n TEXT)',
    why => 'INTEGER PRIMARY KEY, the rowid alias' },
  { table => 'alias_keyword', col => 'id',
    ddl => 'CREATE TABLE alias_keyword (id INTEGER PRIMARY KEY AUTOINCREMENT, n TEXT)',
    why => 'the alias written with AUTOINCREMENT' },
  { table => 'alias_table_constraint', col => 'id',
    ddl => 'CREATE TABLE alias_table_constraint (id INTEGER NOT NULL, n TEXT, PRIMARY KEY (id))',
    why => 'the alias written as a table constraint, as the DDL of this driver does' },
  { table => 'int_pk', col => 'id',
    ddl => 'CREATE TABLE int_pk (id INT PRIMARY KEY, n TEXT)',
    why => 'INT is not the alias; the key stays NULL' },
  { table => 'composite_pk', col => 'a',
    ddl => 'CREATE TABLE composite_pk (a INTEGER, b INTEGER, n TEXT, PRIMARY KEY (a, b))',
    why => 'a composite key is no alias' },
  { table => 'without_rowid', col => 'id',
    ddl => 'CREATE TABLE without_rowid (id INTEGER PRIMARY KEY, n TEXT) WITHOUT ROWID',
    why => 'WITHOUT ROWID has no rowid to alias' },
  { table => 'text_pk', col => 'id',
    ddl => 'CREATE TABLE text_pk (id TEXT PRIMARY KEY, n TEXT)',
    why => 'a text key is not assigned' },
);

for my $c (@cases) {
  $dbh->do($c->{ddl});
}

my $introspect = DBIO::SQLite::Introspect->new(dbh => $dbh);
my %info;
$info{ $_->{table} } = $introspect->table_columns_info($_->{table}) for @cases;
my $info = \%info;

for my $c (@cases) {
  my ($t, $col) = @$c{qw(table col)};

  # without_rowid and the NOT NULL key: the engine refuses the insert, which
  # is "no key assigned" as well.
  my $assigned = eval {
    $dbh->do("INSERT INTO $t (n) VALUES ('x')");
    my ($k) = $dbh->selectrow_array("SELECT $col FROM $t");
    defined $k ? 1 : 0;
  } || 0;

  my $reported = $info->{$t}{$col}{is_auto_increment} ? 1 : 0;
  is $reported, $assigned,
    "$t.$col: is_auto_increment is " . ($assigned ? 'reported' : 'absent')
    . " -- $c->{why}";
}

# What the fix must not do: change the diff. A single integer key declared
# with and without is_auto_increment installs to the same database as before
# and diffs empty against its own declaration.
for my $declared (0, 1) {
  my $pkg = "T68::Auto$declared";
  {
    no strict 'refs';
    @{"${pkg}::Result::ISA"} = ('DBIO::Core');
    @{"${pkg}::ISA"}         = ('DBIO::Schema');
  }
  "${pkg}::Result"->table("thing$declared");
  "${pkg}::Result"->add_columns(
    id   => { data_type => 'integer', is_nullable => 0,
              ($declared ? (is_auto_increment => 1) : ()) },
    name => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  "${pkg}::Result"->set_primary_key('id');
  $pkg->load_components('SQLite');
  $pkg->register_class(Thing => "${pkg}::Result");

  my $schema = $pkg->connect('dbi:SQLite::memory:');
  $schema->deploy;
  my $diff = DBIO::SQLite::Deploy->new(schema => $schema)->diff;
  ok !$diff->has_changes,
    "install then diff is empty, key declared "
    . ($declared ? 'with' : 'without') . ' is_auto_increment'
    or diag $diff->summary;
}

done_testing;
