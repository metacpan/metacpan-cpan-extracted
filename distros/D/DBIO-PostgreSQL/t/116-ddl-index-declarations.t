use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::DDL;

# The index declaration is canonical on the result source (ADR 0061 in core,
# karr k124): Cake idx and indices() write it, and install_ddl reads it
# itself. The DDL comes from index_declarations of the source, next to the
# indexes declared by hand through pg_index; nothing here depends on how, or
# whether, the core derives a pg_indexes method from the declarations.

# --- A Result class whose indexes exist only as declarations on its source,
# beside two declared by hand.
{
  package IdxDecl::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
{
  package IdxDecl::Schema::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'text' },
    body  => { data_type => 'text' },
    state => { data_type => 'text' },
    tags  => { data_type => 'text[]' },
    emb   => { data_type => 'vector(3)' },
  );
  __PACKAGE__->set_primary_key('id');

  my $src = __PACKAGE__->result_source_instance;

  # name, columns, unique only
  $src->add_index_declaration({ name => 'plain_idx', columns => ['title'] });
  $src->add_index_declaration({
    name => 'multi_uq', columns => ['title', 'state'], unique => 1,
  });
  # the whole pg block
  $src->add_index_declaration({
    name => 'tags_gin', columns => ['tags'],
    driver => { pg => { using => 'gin' } },
  });
  $src->add_index_declaration({
    name => 'lower_title', columns => ['title'],
    driver => { pg => { expression => 'lower(title)' } },
  });
  $src->add_index_declaration({
    name => 'emb_hnsw', columns => ['emb'],
    driver => { pg => {
      using => 'hnsw', opclasses => { emb => 'vector_l2_ops' },
      with => { m => 16, ef_construction => 64 },
    } },
  });
  $src->add_index_declaration({
    name => 'cover', columns => ['title'], unique => 1,
    driver => { pg => { include => ['body'], where => "state <> 'gone'" } },
  });

  # by hand, through pg_index
  __PACKAGE__->pg_index(hand_idx => { columns => ['state'], using => 'brin' });
  # by hand, and a canonical one of the same name that wins over it
  __PACKAGE__->pg_index(plain_idx => { columns => ['body'] });
}
IdxDecl::Schema->register_class(Doc => 'IdxDecl::Schema::Result::Doc');

{
  my $ddl = DBIO::PostgreSQL::DDL->install_ddl('IdxDecl::Schema');

  like $ddl, qr/^CREATE INDEX plain_idx ON doc \(title\);$/m,
    'declaration: name and columns';
  unlike $ddl, qr/plain_idx ON doc \(body\)/,
    'same name: the canonical declaration wins over pg_index';
  is scalar(() = $ddl =~ /INDEX plain_idx /g), 1, 'same name: written once';
  like $ddl, qr/^CREATE UNIQUE INDEX multi_uq ON doc \(title, state\);$/m,
    'declaration: unique, several columns';
  like $ddl, qr/^CREATE INDEX tags_gin ON doc USING gin \(tags\);$/m,
    'pg block: using';
  like $ddl, qr/^CREATE INDEX lower_title ON doc \(lower\(title\)\);$/m,
    'pg block: expression replaces columns';
  like $ddl, qr/^CREATE INDEX emb_hnsw ON doc USING hnsw \(emb vector_l2_ops\) WITH \(ef_construction = 64, m = 16\);$/m,
    'pg block: opclasses and with';
  like $ddl, qr/^CREATE UNIQUE INDEX cover ON doc \(title\) INCLUDE \(body\) WHERE state <> 'gone';$/m,
    'pg block: include and where, unique from the declaration';
  like $ddl, qr/^CREATE INDEX hand_idx ON doc USING brin \(state\);$/m,
    'an index declared only through pg_index stays';
}

# --- The same kind of declarations through Cake: idx and indices() write
# the canonical declaration, and install_ddl reads it.
{
  package IdxCake::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
{
  package IdxCake::Schema::Result::Item;
  use DBIO::Cake;

  table 'item';
  col id      => integer auto_inc;
  col sku     => varchar(20);
  col version => integer null;
  col tags    => text;
  primary_key 'id';

  idx sku_idx     => ['sku'];
  idx sku_uq      => ['sku', 'version'], type => 'unique';
  idx tags_gin    => ['tags'], pg => { using => 'gin' };
  idx sku_live_uq => ['sku'], type => 'unique',
    pg => { where => 'version IS NULL' };
  __PACKAGE__->indices(version_idx => 'version');
}
IdxCake::Schema->register_class(Item => 'IdxCake::Schema::Result::Item');

my $cake_ddl = DBIO::PostgreSQL::DDL->install_ddl('IdxCake::Schema');
{
  like $cake_ddl, qr/^CREATE INDEX sku_idx ON item \(sku\);$/m, 'cake: idx';
  like $cake_ddl, qr/^CREATE UNIQUE INDEX sku_uq ON item \(sku, version\);$/m,
    'cake: type unique';
  like $cake_ddl, qr/^CREATE INDEX tags_gin ON item USING gin \(tags\);$/m,
    'cake: pg using';
  like $cake_ddl, qr/^CREATE UNIQUE INDEX sku_live_uq ON item \(sku\) WHERE version IS NULL;$/m,
    'cake: unique and pg where';
  like $cake_ddl, qr/^CREATE INDEX version_idx ON item \(version\);$/m,
    'cake: indices()';
}
is(DBIO::PostgreSQL::DDL->install_ddl('IdxCake::Schema'), $cake_ddl,
  'cake: the DDL is the same on a second run');

# --- What the pg driver would not write is refused, not dropped (karr k129;
# the full table of refusals is t/121). Here: the entry that carries a pg
# block beside another driver's is read.
{
  package IdxForeign::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
{
  package IdxForeign::Schema::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('thing');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'mixed_idx', columns => ['name'],
    driver => { sqlite => { where => 'x' }, pg => { using => 'hash' } },
  });
}
IdxForeign::Schema->register_class(Thing => 'IdxForeign::Schema::Result::Thing');

like(DBIO::PostgreSQL::DDL->install_ddl('IdxForeign::Schema'),
  qr/^CREATE INDEX mixed_idx ON thing USING hash \(name\);$/m,
  'a pg block beside another driver is read');

done_testing;
