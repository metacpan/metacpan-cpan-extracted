use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';
}

use DBIO::SQLite::DDL;
use DBIO::SQLite::Deploy;

# The index declaration is canonical on the result source (ADR 0061 in core,
# karr k77): Cake idx and indices() write it, and the DDL reads it. Before,
# only sqlite_index was read, and a Cake class got no CREATE INDEX at all.

{
  package IdxDdl::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package IdxDdl::Schema::Result::Person;
  use DBIO::Cake;

  table 'person';
  col id    => integer auto_inc;
  col name  => varchar(100);
  col city  => varchar(100);
  col state => varchar(10);

  primary_key 'id';

  idx name_idx      => ['name'];
  idx name_city_uq  => ['name', 'city'], type => 'unique';

  __PACKAGE__->indices(state_idx => 'state');
}
IdxDdl::Schema->register_class(Person => 'IdxDdl::Schema::Result::Person');

# The same table without any index: the state a database is in before the
# class declared them.
{
  package IdxDdl::Bare;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package IdxDdl::Bare::Result::Person;
  use DBIO::Cake;

  table 'person';
  col id    => integer auto_inc;
  col name  => varchar(100);
  col city  => varchar(100);
  col state => varchar(10);

  primary_key 'id';
}
IdxDdl::Bare->register_class(Person => 'IdxDdl::Bare::Result::Person');

sub index_names {
  my ($dbh) = @_;
  return { map { $_->[0] => $_->[1] } @{ $dbh->selectall_arrayref(
    q{SELECT name, sql FROM sqlite_master WHERE type = 'index' AND sql IS NOT NULL}
  ) } };
}

# --- install_ddl carries the canonical declarations
{
  my $ddl = DBIO::SQLite::DDL->install_ddl('IdxDdl::Schema');
  like $ddl, qr/^CREATE INDEX "name_idx" ON "person" \("name"\);$/m,
    'idx: simple index';
  like $ddl, qr/^CREATE UNIQUE INDEX "name_city_uq" ON "person" \("name", "city"\);$/m,
    'idx: unique, several columns';
  like $ddl, qr/^CREATE INDEX "state_idx" ON "person" \("state"\);$/m,
    'indices(): index';
}

# --- deploy creates them
{
  my $schema = IdxDdl::Schema->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
  DBIO::SQLite::Deploy->new(schema => $schema)->install;
  my $idx = index_names($schema->storage->dbh);
  is_deeply [ sort keys %$idx ], [qw(name_city_uq name_idx state_idx)],
    'deploy: the three indexes are in sqlite_master';
  like $idx->{name_city_uq}, qr/^CREATE UNIQUE INDEX/, 'deploy: unique one is unique';
}

# --- upgrade from a table without them creates them, a second diff is empty
{
  my $old = IdxDdl::Bare->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
  DBIO::SQLite::Deploy->new(schema => $old)->install;
  is_deeply index_names($old->storage->dbh), {}, 'upgrade: the table starts without indexes';

  my $new = IdxDdl::Schema->connect(sub { $old->storage->dbh });
  my $deploy = DBIO::SQLite::Deploy->new(schema => $new);

  my $diff = $deploy->diff;
  ok $diff->has_changes, 'upgrade: the diff sees the missing indexes';
  like $diff->as_sql, qr/CREATE INDEX "name_idx"/, 'upgrade: diff creates name_idx';

  $deploy->apply($diff);
  is_deeply [ sort keys %{ index_names($old->storage->dbh) } ],
    [qw(name_city_uq name_idx state_idx)], 'upgrade: indexes exist after apply';

  ok !$deploy->diff->has_changes, 'upgrade: a second diff is empty';
}

# --- the own sqlite block of a canonical entry, and the name collision
{
  package IdxDdl::Own::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package IdxDdl::Own::Schema::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('SQLite::Result');
  __PACKAGE__->table('doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'text' },
    state => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  # by hand, and a canonical declaration of the same name that wins over it
  __PACKAGE__->sqlite_index(title_idx => { columns => ['state'] });
  __PACKAGE__->sqlite_index(hand_idx  => { columns => ['state'] });
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'title_idx', columns => ['title'],
  });
  # idx takes only pg => {...} (ADR 0061 question 1), so the own block is
  # set on the source directly
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'live_idx', columns => ['title'], unique => 1,
    driver => { sqlite => { where => "state = 'live'" } },
  });
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'lower_idx', columns => ['title'],
    driver => { sqlite => { expression => 'lower(title)' } },
  });
}
IdxDdl::Own::Schema->register_class(Doc => 'IdxDdl::Own::Schema::Result::Doc');

{
  my $ddl = DBIO::SQLite::DDL->install_ddl('IdxDdl::Own::Schema');
  like $ddl, qr/^CREATE INDEX "title_idx" ON "doc" \("title"\);$/m,
    'same name: the canonical declaration wins over sqlite_index';
  unlike $ddl, qr/"title_idx" ON "doc" \("state"\)/, 'same name: written once';
  like $ddl, qr/^CREATE INDEX "hand_idx" ON "doc" \("state"\);$/m,
    'sqlite_index by hand stays valid';
  like $ddl, qr/^CREATE UNIQUE INDEX "live_idx" ON "doc" \("title"\) WHERE state = 'live';$/m,
    'own sqlite block: where';
  like $ddl, qr/^CREATE INDEX "lower_idx" ON "doc" \(lower\(title\)\);$/m,
    'own sqlite block: expression';

  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });
  $dbh->do($_) for grep { /\S/ } split /;\s*\n/, $ddl;
  is_deeply [ sort keys %{ index_names($dbh) } ],
    [qw(hand_idx live_idx lower_idx title_idx)], 'the generated DDL executes';
}

# --- an entry that carries only another driver's block is refused, loudly
# (maintainer decision 2026-10-12, core k333 index_declarations_for). Claim:
# a schema bound to sqlite must not silently lose an index -- nor get a
# plainer one than the pg block declared -- so install_ddl and the diff throw,
# naming the index. {} in the own block is how the plain index is asked for.
{
  package IdxDdl::Foreign::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package IdxDdl::Foreign::Schema::Result::Item;
  use DBIO::Cake;

  table 'item';
  col id      => integer auto_inc;
  col version => integer null;
  col sku     => varchar(20);
  primary_key 'id';

  idx sku_idx      => ['sku'];
  idx sku_live_uq  => ['sku'], type => 'unique',
    pg => { where => 'version IS NULL' };
}
IdxDdl::Foreign::Schema->register_class(Item => 'IdxDdl::Foreign::Schema::Result::Item');

throws_ok { DBIO::SQLite::DDL->install_ddl('IdxDdl::Foreign::Schema') }
  qr/index 'sku_live_uq' carries only the 'pg' block and none for 'sqlite'/,
  'install_ddl: an entry with only a pg block is refused, naming the index';

{
  my $bare = IdxDdl::Foreign::Schema->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
  throws_ok { DBIO::SQLite::Deploy->new(schema => $bare)->diff }
    qr/index 'sku_live_uq' carries only the 'pg' block/,
    'diff: the desired model reads the same declaration and refuses the same entry';
}

# --- unknown key in the own block, and the empty own block
# Claim: a key the sqlite block does not know (a typo, a pg key) is an error
# and not silently dropped, which would deploy a broader index than declared;
# an empty own block is the plain index, explicitly asked for.
{
  package IdxDdl::BadKey::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package IdxDdl::BadKey::Schema::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'title_idx', columns => ['title'],
    driver => { sqlite => { wher => 'id > 1' } },
  });
}
IdxDdl::BadKey::Schema->register_class(Doc => 'IdxDdl::BadKey::Schema::Result::Doc');

throws_ok { DBIO::SQLite::DDL->install_ddl('IdxDdl::BadKey::Schema') }
  qr/index 'title_idx': unknown key 'wher' in its 'sqlite' block/,
  'own block: an unknown key is refused, naming index and key';

{
  package IdxDdl::EmptyOwn::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package IdxDdl::EmptyOwn::Schema::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'title_idx', columns => ['title'],
    driver => { sqlite => {}, pg => { using => 'gin' } },
  });
}
IdxDdl::EmptyOwn::Schema->register_class(Doc => 'IdxDdl::EmptyOwn::Schema::Result::Doc');

{
  my $ddl;
  lives_ok { $ddl = DBIO::SQLite::DDL->install_ddl('IdxDdl::EmptyOwn::Schema') }
    'own block: an empty sqlite block does not refuse';
  like $ddl, qr/^CREATE INDEX "title_idx" ON "doc" \("title"\);$/m,
    'own block: empty means the plain index, the pg block beside it ignored';
}

# --- the diff reads the same source: an own block reaches the upgrade
# Claim: the desired model of the diff is built from the same declaration as
# install_ddl, so a partial index declared in the own block is created by an
# upgrade, and a second diff is empty.
{
  my $old = IdxDdl::Own::Schema->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
  my $dbh = $old->storage->dbh;
  $dbh->do('CREATE TABLE "doc" ("id" INTEGER PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "state" TEXT NOT NULL)');
  my $deploy = DBIO::SQLite::Deploy->new(schema => $old);
  my $diff = $deploy->diff;
  like $diff->as_sql, qr/CREATE UNIQUE INDEX "live_idx" ON "doc" \("title"\) WHERE state = 'live'/,
    'diff: the own sqlite block (unique, where) is in the upgrade';
  $deploy->apply($diff);
  ok !$deploy->diff->has_changes, 'diff: a second diff is empty';
}

done_testing;
