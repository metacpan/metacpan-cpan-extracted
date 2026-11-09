use strict;
use warnings;
use Test::More;

# t/34-ddl-skipping-index-live.t -- does the server accept the inline INDEX
# the DDL renders from a canonical declaration, and report it back as declared.
# Companion of the offline t/34-ddl-skipping-index.t, which cannot know what
# the ClickHouse parser says. DSN-gated: needs a real server.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::Schema;
use DBIO::ClickHouse::DDL;
use DBIO::ClickHouse::Test;

{
  package My::CH::LiveIdx::Result::Event;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_idx_live');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer' },
    score => { data_type => 'integer' },
    tag   => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'score_idx', columns => ['score'],
    driver => { clickhouse => { type => 'minmax', granularity => 4 } },
  });
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'tag_set', columns => ['tag'],
    driver => { clickhouse => { type => 'set(100)', granularity => 2 } },
  });

  package My::CH::LiveIdx;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Event => 'My::CH::LiveIdx::Result::Event');
}

my $schema = DBIO::ClickHouse::Test->init_schema(no_deploy => 1);
my $dbh    = $schema->storage->dbh;

my $ddl = DBIO::ClickHouse::DDL->install_ddl('My::CH::LiveIdx');
$dbh->do('DROP TABLE IF EXISTS `dbio_idx_live`');
(my $stmt = $ddl) =~ s/;\s*\z//;
ok eval { $dbh->do($stmt); 1 }, 'server accepts the rendered CREATE TABLE'
  or diag "server said: $@\nstatement: $ddl";

my $rows = $dbh->selectall_hashref(
  'SELECT name, type_full, granularity FROM system.data_skipping_indices '
. 'WHERE database = currentDatabase() AND table = ?', 'name', undef, 'dbio_idx_live');
is $rows->{score_idx}{type_full}, 'minmax',   'score_idx type';
is $rows->{score_idx}{granularity}, 4,        'score_idx granularity';
is $rows->{tag_set}{type_full}, 'set(100)',   'tag_set type';
is $rows->{tag_set}{granularity}, 2,          'tag_set granularity';

$dbh->do('DROP TABLE IF EXISTS `dbio_idx_live`');
done_testing;
