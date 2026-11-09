use strict;
use warnings;
use Test::More;

# ==========================================================
# Comprehensive DBIO::Cake test — covers the full DSL as
# documented in the SYNOPSIS and POD.
# ==========================================================

# --- Artist: basic types, modifiers, relationships ----------
{
  package TestComp::Result::Artist;
  use DBIO::Cake;

  table 'artist';
  col id           => integer, unsigned, auto_inc;
  col name         => varchar(25), null;
  col formed       => date;
  col disbanded    => date, null;
  col general_info => json, null;
  col last_update  => datetime('UTC');
  primary_key 'id';

  has_many albums => 'TestComp::Result::Album', 'artist_id';
}

# --- Album: FK, belongs_to, idx ---------------------------
{
  package TestComp::Result::Album;
  use DBIO::Cake;

  table 'album';
  col id        => serial;
  col artist_id => integer, unsigned, fk;
  col title     => varchar(100);
  col released  => date, null;
  col rating    => numeric(3, 1), null;
  col price     => decimal(8, 2), default(9.99);
  primary_key 'id';

  belongs_to artist => 'TestComp::Result::Artist', 'artist_id';
  idx album_title => ['title'];
}

# --- Track: bigint, text, boolean, enum --------------------
{
  package TestComp::Result::Track;
  use DBIO::Cake;

  table 'track';
  col id       => bigint, auto_inc;
  col album_id => integer, fk;
  col title    => text;
  col position => smallint;
  col bonus    => boolean, default(0);
  col format   => enum('cd', 'vinyl', 'digital');
  primary_key 'id';

  belongs_to album => 'TestComp::Result::Album', 'album_id';
}

# --- PgAdvanced: PostgreSQL-specific types -----------------
{
  package TestComp::Result::PgAdvanced;
  use DBIO::Cake;

  table 'pg_advanced';
  col id         => serial;
  col embedding  => vector(1536);
  col half_emb   => halfvec(768);
  col sparse_emb => sparsevec(3000);
  col ip_addr    => inet;
  col network    => cidr;
  col hw_addr    => macaddr;
  col hw_addr8   => macaddr8;
  col search_vec => tsvector;
  col search_q   => tsquery;
  col tags       => hstore;
  col doc        => xml;
  col loc        => point;
  col route      => path;
  col area       => polygon;
  col bounds     => box;
  col segment    => lseg;
  col ring       => circle;
  col track_line => line;
  col ages       => int4range;
  col big_ages   => int8range;
  col amounts    => numrange;
  col period     => tsrange;
  col tz_period  => tstzrange;
  col date_range => daterange;
  col created    => timestamptz;
  col duration   => interval;
  col wake_time  => timetz;
  col raw_flags  => bit(8);
  col var_flags  => varbit(64);
  col balance    => money;
  col metadata   => jsonb;
  col payload    => bytea;
  col tiny_data  => tinyint;
  col small_ser  => smallserial;
  col big_ser    => bigserial;
  col precise    => float(53);
  col single     => real;
  col dbl        => double;
  col items      => array('text');
  col ukey       => uuid;
  primary_key 'id';
}

# --- UniqueTest: unique constraints -----------------------
{
  package TestComp::Result::UniqueTest;
  use DBIO::Cake;

  table 'unique_test';
  col id    => integer, auto_inc;
  col email => varchar(255);
  col code  => varchar(10);
  primary_key 'id';

  unique ['email'];
  unique code_uniq => ['code'];
}

# --- Versioned: idx with options + pg (partial index) -----
{
  package TestComp::Result::Versioned;
  use DBIO::Cake;

  table 'versioned';
  col id         => serial;
  col key        => varchar(50);
  col version    => integer, null;
  primary_key 'id';

  # Two partial unique indexes via both pipelines:
  #   options => SQL::Translator producer
  #   pg      => DBIO::PostgreSQL::DDL native
  idx versioned_published => ['key', 'version'],
      type    => 'unique',
      options => [{ where => 'version IS NOT NULL' }],
      pg      => { where => 'version IS NOT NULL' };
  idx versioned_draft => ['key'],
      type    => 'unique',
      options => [{ where => 'version IS NULL' }],
      pg      => { where => 'version IS NULL' };
}

# --- VersionedMerge: Cake idx beside a hand-written pg_indexes ---
{
  package TestComp::Result::VersionedMerge;
  use DBIO::Cake;

  table 'versioned_merge';
  col id  => serial;
  col key => varchar(50);
  primary_key 'id';

  # Hand-written pg_indexes BEFORE any idx() call — Cake must leave it alone.
  sub pg_indexes {
    return {
      manual_idx => { columns => ['key'], using => 'hash' },
    };
  }

  idx cake_idx => ['key'],
      type => 'unique',
      pg   => { where => 'key IS NOT NULL' };
}

# --- ManyToMany: link table test --------------------------
{
  package TestComp::Result::Tag;
  use DBIO::Cake;

  table 'tag';
  col id   => integer, auto_inc;
  col name => varchar(50);
  primary_key 'id';
}

{
  package TestComp::Result::AlbumTag;
  use DBIO::Cake;

  table 'album_tag';
  col album_id => integer, fk;
  col tag_id   => integer, fk;
  primary_key 'album_id', 'tag_id';

  belongs_to album => 'TestComp::Result::Album', 'album_id';
  belongs_to tag   => 'TestComp::Result::Tag', 'tag_id';
}

# ==========================================================
# Tests
# ==========================================================

# --- Artist ---
{
  my $id = TestComp::Result::Artist->column_info('id');
  is($id->{data_type}, 'integer', 'Artist.id: integer');
  is($id->{extra}{unsigned}, 1, 'Artist.id: unsigned');
  is($id->{is_auto_increment}, 1, 'Artist.id: auto_inc');
  is($id->{is_nullable}, 0, 'Artist.id: not null by default');

  my $name = TestComp::Result::Artist->column_info('name');
  is($name->{data_type}, 'varchar', 'Artist.name: varchar');
  is($name->{size}, 25, 'Artist.name: size 25');
  is($name->{is_nullable}, 1, 'Artist.name: null');

  my $formed = TestComp::Result::Artist->column_info('formed');
  is($formed->{data_type}, 'date', 'Artist.formed: date');
  is($formed->{is_nullable}, 0, 'Artist.formed: not null');

  my $info = TestComp::Result::Artist->column_info('general_info');
  is($info->{data_type}, 'json', 'Artist.general_info: json');
  is($info->{is_nullable}, 1, 'Artist.general_info: null');

  my $upd = TestComp::Result::Artist->column_info('last_update');
  is($upd->{data_type}, 'datetime', 'Artist.last_update: datetime');
  is($upd->{timezone}, 'UTC', 'Artist.last_update: timezone UTC');

  is_deeply(
    [TestComp::Result::Artist->primary_columns],
    ['id'],
    'Artist: primary key'
  );

  ok(TestComp::Result::Artist->has_relationship('albums'), 'Artist: has_many albums');
}

# --- Album ---
{
  my $id = TestComp::Result::Album->column_info('id');
  is($id->{data_type}, 'serial', 'Album.id: serial');
  is($id->{is_auto_increment}, 1, 'Album.id: serial implies auto_inc');

  my $aid = TestComp::Result::Album->column_info('artist_id');
  is($aid->{is_foreign_key}, 1, 'Album.artist_id: fk');
  is($aid->{extra}{unsigned}, 1, 'Album.artist_id: unsigned');

  my $rating = TestComp::Result::Album->column_info('rating');
  is($rating->{data_type}, 'numeric', 'Album.rating: numeric');
  is_deeply($rating->{size}, [3, 1], 'Album.rating: size [3,1]');
  is($rating->{is_nullable}, 1, 'Album.rating: null');

  my $price = TestComp::Result::Album->column_info('price');
  is($price->{data_type}, 'decimal', 'Album.price: decimal');
  is_deeply($price->{size}, [8, 2], 'Album.price: size [8,2]');
  is($price->{default_value}, 9.99, 'Album.price: default 9.99');

  ok(TestComp::Result::Album->has_relationship('artist'), 'Album: belongs_to artist');
}

# --- Track ---
{
  my $id = TestComp::Result::Track->column_info('id');
  is($id->{data_type}, 'bigint', 'Track.id: bigint');

  my $pos = TestComp::Result::Track->column_info('position');
  is($pos->{data_type}, 'smallint', 'Track.position: smallint');

  my $bonus = TestComp::Result::Track->column_info('bonus');
  is($bonus->{data_type}, 'boolean', 'Track.bonus: boolean');
  is($bonus->{default_value}, 0, 'Track.bonus: default 0');

  my $fmt = TestComp::Result::Track->column_info('format');
  is($fmt->{data_type}, 'enum', 'Track.format: enum');
  is_deeply($fmt->{extra}{list}, ['cd', 'vinyl', 'digital'], 'Track.format: enum values');
}

# --- PgAdvanced: all PostgreSQL types ----------------------
{
  my $t = 'TestComp::Result::PgAdvanced';

  # Vector types
  my $emb = $t->column_info('embedding');
  is($emb->{data_type}, 'vector', 'PG: vector');
  is($emb->{size}, 1536, 'PG: vector dims');

  my $half = $t->column_info('half_emb');
  is($half->{data_type}, 'halfvec', 'PG: halfvec');
  is($half->{size}, 768, 'PG: halfvec dims');

  my $sparse = $t->column_info('sparse_emb');
  is($sparse->{data_type}, 'sparsevec', 'PG: sparsevec');
  is($sparse->{size}, 3000, 'PG: sparsevec dims');

  # Network
  is($t->column_info('ip_addr')->{data_type}, 'inet', 'PG: inet');
  is($t->column_info('network')->{data_type}, 'cidr', 'PG: cidr');
  is($t->column_info('hw_addr')->{data_type}, 'macaddr', 'PG: macaddr');
  is($t->column_info('hw_addr8')->{data_type}, 'macaddr8', 'PG: macaddr8');

  # Full-text
  is($t->column_info('search_vec')->{data_type}, 'tsvector', 'PG: tsvector');
  is($t->column_info('search_q')->{data_type}, 'tsquery', 'PG: tsquery');

  # Key-value / document
  is($t->column_info('tags')->{data_type}, 'hstore', 'PG: hstore');
  is($t->column_info('doc')->{data_type}, 'xml', 'PG: xml');
  is($t->column_info('metadata')->{data_type}, 'jsonb', 'PG: jsonb');

  # Geometric
  is($t->column_info('loc')->{data_type}, 'point', 'PG: point');
  is($t->column_info('route')->{data_type}, 'path', 'PG: path');
  is($t->column_info('area')->{data_type}, 'polygon', 'PG: polygon');
  is($t->column_info('bounds')->{data_type}, 'box', 'PG: box');
  is($t->column_info('segment')->{data_type}, 'lseg', 'PG: lseg');
  is($t->column_info('ring')->{data_type}, 'circle', 'PG: circle');
  is($t->column_info('track_line')->{data_type}, 'line', 'PG: line');

  # Range types
  is($t->column_info('ages')->{data_type}, 'int4range', 'PG: int4range');
  is($t->column_info('big_ages')->{data_type}, 'int8range', 'PG: int8range');
  is($t->column_info('amounts')->{data_type}, 'numrange', 'PG: numrange');
  is($t->column_info('period')->{data_type}, 'tsrange', 'PG: tsrange');
  is($t->column_info('tz_period')->{data_type}, 'tstzrange', 'PG: tstzrange');
  is($t->column_info('date_range')->{data_type}, 'daterange', 'PG: daterange');

  # Time variants
  is($t->column_info('created')->{data_type}, 'timestamp with time zone', 'PG: timestamptz');
  is($t->column_info('duration')->{data_type}, 'interval', 'PG: interval');
  is($t->column_info('wake_time')->{data_type}, 'time with time zone', 'PG: timetz');

  # Bit
  my $bits = $t->column_info('raw_flags');
  is($bits->{data_type}, 'bit', 'PG: bit');
  is($bits->{size}, 8, 'PG: bit size');
  my $vbits = $t->column_info('var_flags');
  is($vbits->{data_type}, 'varbit', 'PG: varbit');
  is($vbits->{size}, 64, 'PG: varbit size');

  # Misc
  is($t->column_info('balance')->{data_type}, 'money', 'PG: money');
  is($t->column_info('payload')->{data_type}, 'bytea', 'PG: bytea');
  is($t->column_info('ukey')->{data_type}, 'uuid', 'PG: uuid');

  # Serials
  my $ss = $t->column_info('small_ser');
  is($ss->{data_type}, 'smallserial', 'PG: smallserial');
  is($ss->{is_auto_increment}, 1, 'PG: smallserial auto_inc');
  my $bs = $t->column_info('big_ser');
  is($bs->{data_type}, 'bigserial', 'PG: bigserial');
  is($bs->{is_auto_increment}, 1, 'PG: bigserial auto_inc');

  # Float variants
  my $fl = $t->column_info('precise');
  is($fl->{data_type}, 'float', 'PG: float(53)');
  is($fl->{size}, 53, 'PG: float size');
  is($t->column_info('single')->{data_type}, 'real', 'PG: real');
  is($t->column_info('dbl')->{data_type}, 'double precision', 'PG: double');

  # Array
  is($t->column_info('items')->{data_type}, 'text[]', 'PG: array(text)');

  # Tiny int
  is($t->column_info('tiny_data')->{data_type}, 'tinyint', 'tinyint');
}

# --- Unique constraints ---
{
  my @uniq = TestComp::Result::UniqueTest->unique_constraints;
  cmp_ok(scalar @uniq, '>=', 2, 'UniqueTest: has unique constraints');
}

# --- idx with options/pg (partial unique indexes) ---------
{
  my $src = TestComp::Result::Versioned->result_source_instance;
  my $idxs = $src->{_index_declarations} || [];
  is(scalar @$idxs, 2, 'Versioned: two indexes registered');

  my ($published) = grep { $_->{name} eq 'versioned_published' } @$idxs;
  ok($published, 'Versioned: published index present');
  is($published->{type}, 'unique', 'Versioned: published is unique');
  is_deeply($published->{columns}, ['key', 'version'],
    'Versioned: published fields');
  is_deeply($published->{options},
    [{ where => 'version IS NOT NULL' }],
    'Versioned: published options pass through');
  is_deeply($published->{driver}{pg},
    { where => 'version IS NOT NULL' },
    'Versioned: published pg pass through');

  my ($draft) = grep { $_->{name} eq 'versioned_draft' } @$idxs;
  ok($draft, 'Versioned: draft index present');
  is_deeply($draft->{driver}{pg}, { where => 'version IS NULL' },
    'Versioned: draft pg pass through');

  # No class method is derived from the declarations
  ok(!TestComp::Result::Versioned->can('pg_indexes'),
    'Cake installs no pg_indexes on the class');
  ok(!TestComp::Result::Versioned->can('sqlt_deploy_hook'),
    'Cake installs no sqlt_deploy_hook on the class');
}

# --- a hand-written pg_indexes is left alone, declarations stay separate ---
{
  is_deeply(TestComp::Result::VersionedMerge->pg_indexes,
    { manual_idx => { columns => ['key'], using => 'hash' } },
    'pg_indexes: hand-written method unchanged by idx()');
  my @decl = TestComp::Result::VersionedMerge->result_source_instance
    ->index_declarations;
  is_deeply([ map $_->{name}, @decl ], ['cake_idx'],
    'idx() entry is in index_declarations only');
  is_deeply($decl[0]{driver}{pg}, { where => 'key IS NOT NULL' },
    'cake entry: pg block kept');
  is($decl[0]{unique}, 1, 'cake entry: unique');
}

# --- Namespace cleanup ---
{
  # DSL-only functions (not inherited from DBIO::Core) should be cleaned
  ok(!TestComp::Result::Artist->can('col'), 'Cake: col cleaned from namespace');
  ok(!TestComp::Result::Artist->can('integer'), 'Cake: integer cleaned');
  ok(!TestComp::Result::Artist->can('varchar'), 'Cake: varchar cleaned');
  ok(!TestComp::Result::Artist->can('auto_inc'), 'Cake: auto_inc cleaned');
  ok(!TestComp::Result::Artist->can('null'), 'Cake: null cleaned');
  ok(!TestComp::Result::Artist->can('vector'), 'Cake: vector cleaned');
  ok(!TestComp::Result::Artist->can('serial'), 'Cake: serial cleaned');
  ok(!TestComp::Result::Artist->can('idx'), 'Cake: idx cleaned');
  # Note: table, has_many, belongs_to etc. still exist as inherited
  # DBIO::Core methods — namespace::clean only removes the Cake imports
}

# --- Inheritance ---
{
  ok(TestComp::Result::Artist->isa('DBIO::Core'), 'Cake: Artist isa DBIO::Core');
  ok(TestComp::Result::Album->isa('DBIO::Core'), 'Cake: Album isa DBIO::Core');
}

done_testing;
