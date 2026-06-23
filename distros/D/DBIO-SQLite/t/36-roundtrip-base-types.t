use strict; use warnings;
use Test::More;
use DBIO::Schema::ModelCompiler ();
use DBIO::SQLite::Adapter ();
use DBIO::SQLite::Introspect ();
use DBIO::SQLite::Diff ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# Schema covering all 8 base types.
{
  package RT::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('things');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'char', size => 32 },
    bio  => { data_type => 'text', is_nullable => 1 },
    ok   => { data_type => 'boolean' },
    amt  => { data_type => 'numeric', size => [10,2] },
    rate => { data_type => 'double' },
    data => { data_type => 'blob', is_nullable => 1 },
    seen => { data_type => 'timestamp' },
  );
  __PACKAGE__->set_primary_key('id');
  package RT::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Thing => 'RT::Result::Thing');
}

my $schema = RT::Schema->connect('dbi:SQLite:dbname=:memory:');
my $compiled = DBIO::Schema::ModelCompiler
  ->new(adapter => DBIO::SQLite::Adapter->new)->compile($schema);

# Deploy the compiled native target (use the SAME in-memory connection).
$schema->storage->dbh_do(sub {
  my ($s, $dbh) = @_;
  $dbh->do('CREATE TABLE things ('
    . 'id INTEGER PRIMARY KEY AUTOINCREMENT, name CHAR(32) NOT NULL, '
    . 'bio TEXT, ok BOOLEAN NOT NULL, amt NUMERIC(10,2) NOT NULL, '
    . 'rate REAL NOT NULL, data BLOB, seen TEXT NOT NULL)');
});

my $source = DBIO::SQLite::Introspect->new(dbh => $schema->storage->dbh)->model;
my $target = DBIO::SQLite::Diff->target_from_compiled($compiled);

my $diff = DBIO::SQLite::Diff->new(source => $source, target => $target);
ok !$diff->has_changes, 'second diff is empty (no phantom changes)'
  or diag $diff->summary;

done_testing;
