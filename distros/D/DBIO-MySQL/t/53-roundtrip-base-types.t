use strict;
use warnings;
use Test::More;

use DBIO::Schema::ModelCompiler ();
use DBIO::MySQL::Adapter ();
use DBIO::MySQL::Introspect ();
use DBIO::MySQL::Diff ();

plan skip_all => 'DBIO_TEST_MYSQL_DSN not set'
  unless $ENV{DBIO_TEST_MYSQL_DSN};

# Inline base-type schema covering all 8 portable base types.
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

my $schema = RT::Schema->connect(
  $ENV{DBIO_TEST_MYSQL_DSN},
  $ENV{DBIO_TEST_MYSQL_USER},
  $ENV{DBIO_TEST_MYSQL_PASS},
);

# Compile the neutral model into MySQL native types.
my $compiled = DBIO::Schema::ModelCompiler
  ->new(adapter => DBIO::MySQL::Adapter->new)
  ->compile($schema);

# Deploy the table using MySQL-native types matching the adapter mapping:
#   integer  → BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY
#   char(32) → CHAR(32) NOT NULL
#   text     → LONGTEXT (nullable)
#   boolean  → TINYINT(1) NOT NULL
#   numeric(10,2) → DECIMAL(10,2) NOT NULL
#   double   → DOUBLE NOT NULL
#   blob     → LONGBLOB (nullable)
#   timestamp → DATETIME NOT NULL
$schema->storage->dbh_do(sub {
  my ($storage, $dbh) = @_;
  $dbh->do('DROP TABLE IF EXISTS things');
  $dbh->do(q{
    CREATE TABLE things (
      id    BIGINT        NOT NULL AUTO_INCREMENT,
      name  CHAR(32)      NOT NULL,
      bio   LONGTEXT,
      ok    TINYINT(1)    NOT NULL,
      amt   DECIMAL(10,2) NOT NULL,
      rate  DOUBLE        NOT NULL,
      data  LONGBLOB,
      seen  DATETIME      NOT NULL,
      PRIMARY KEY (id)
    )
  });
});

# Introspect live DB.
my $dbh    = $schema->storage->dbh;
my $source = DBIO::MySQL::Introspect->new(dbh => $dbh)->model;

# Translate compiled model into MySQL introspect shape.
my $target = DBIO::MySQL::Diff->target_from_compiled($compiled);

my $diff = DBIO::MySQL::Diff->new(source => $source, target => $target);

if ($diff->has_changes) {
  diag "diff summary:\n" . $diff->summary;

  # Diagnostic dump of source vs target for the 'things' table columns.
  use Data::Dumper;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Indent   = 1;
  diag "SOURCE columns for 'things':";
  diag Dumper($source->{columns}{things});
  diag "TARGET columns for 'things':";
  diag Dumper($target->{columns}{things});
}

ok !$diff->has_changes, 'round-trip diff is empty (no phantom changes)'
  or diag $diff->summary;

# Cleanup.
$schema->storage->dbh_do(sub {
  my ($storage, $dbh) = @_;
  $dbh->do('DROP TABLE IF EXISTS things');
});

done_testing;
