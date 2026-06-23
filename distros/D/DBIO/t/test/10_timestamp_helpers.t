use strict;
use warnings;
use Test::More;

# --- Vanilla style ---

{
  package Test::Vanilla::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->table('artists');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->cols_updated_created;
  __PACKAGE__->set_primary_key('id');
}

{
  my $info = Test::Vanilla::Artist->columns_info;
  ok $info->{created_at}, 'vanilla: created_at exists';
  is $info->{created_at}{data_type}, 'timestamp', 'vanilla: created_at is timestamp';
  ok $info->{created_at}{_timestamp_on_create}, 'vanilla: created_at has _timestamp_on_create';
  ok !$info->{created_at}{_timestamp_on_update}, 'vanilla: created_at no _timestamp_on_update';

  ok $info->{updated_at}, 'vanilla: updated_at exists';
  is $info->{updated_at}{data_type}, 'timestamp', 'vanilla: updated_at is timestamp';
  ok $info->{updated_at}{_timestamp_on_create}, 'vanilla: updated_at has _timestamp_on_create';
  ok $info->{updated_at}{_timestamp_on_update}, 'vanilla: updated_at has _timestamp_on_update';
}

# --- Vanilla with custom names ---

{
  package Test::Vanilla::Custom;
  use base 'DBIO::Core';
  __PACKAGE__->table('custom');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
  );
  __PACKAGE__->col_created('born_at');
  __PACKAGE__->col_updated('modified_at');
  __PACKAGE__->set_primary_key('id');
}

{
  my $info = Test::Vanilla::Custom->columns_info;
  ok $info->{born_at}, 'vanilla custom: born_at exists';
  ok $info->{born_at}{_timestamp_on_create}, 'vanilla custom: born_at has _timestamp_on_create';
  ok $info->{modified_at}, 'vanilla custom: modified_at exists';
  ok $info->{modified_at}{_timestamp_on_update}, 'vanilla custom: modified_at has _timestamp_on_update';
  ok !exists $info->{created_at}, 'vanilla custom: no default created_at';
}

# --- Candy style ---

{
  package Test::Candy::Artist;
  use DBIO::Candy;
  table 'artists';
  primary_column id => { data_type => 'integer', is_auto_increment => 1 };
  column name => { data_type => 'varchar', size => 100 };
  cols_updated_created;
}

{
  my $info = Test::Candy::Artist->columns_info;
  ok $info->{created_at}, 'candy: created_at exists';
  is $info->{created_at}{data_type}, 'timestamp', 'candy: created_at is timestamp';
  ok $info->{created_at}{_timestamp_on_create}, 'candy: created_at has _timestamp_on_create';

  ok $info->{updated_at}, 'candy: updated_at exists';
  ok $info->{updated_at}{_timestamp_on_create}, 'candy: updated_at has _timestamp_on_create';
  ok $info->{updated_at}{_timestamp_on_update}, 'candy: updated_at has _timestamp_on_update';
}

# --- Candy with custom names ---

{
  package Test::Candy::Custom;
  use DBIO::Candy;
  table 'custom';
  primary_column id => { data_type => 'integer', is_auto_increment => 1 };
  col_created 'inception';
  col_updated 'last_touch';
}

{
  my $info = Test::Candy::Custom->columns_info;
  ok $info->{inception}, 'candy custom: inception exists';
  ok $info->{inception}{_timestamp_on_create}, 'candy custom: inception has _timestamp_on_create';
  ok $info->{last_touch}, 'candy custom: last_touch exists';
  ok $info->{last_touch}{_timestamp_on_update}, 'candy custom: last_touch has _timestamp_on_update';
}

# --- Cake style ---

{
  package Test::Cake::Artist;
  use DBIO::Cake;
  table 'artists';
  col id   => integer auto_inc;
  col name => varchar(100);
  cols_updated_created;
  primary_key 'id';
}

{
  my $info = Test::Cake::Artist->columns_info;
  ok $info->{created_at}, 'cake: created_at exists';
  is $info->{created_at}{data_type}, 'timestamp', 'cake: created_at is timestamp';
  ok $info->{created_at}{_timestamp_on_create}, 'cake: created_at has _timestamp_on_create';

  ok $info->{updated_at}, 'cake: updated_at exists';
  ok $info->{updated_at}{_timestamp_on_create}, 'cake: updated_at has _timestamp_on_create';
  ok $info->{updated_at}{_timestamp_on_update}, 'cake: updated_at has _timestamp_on_update';
}

# --- Cake smart timestamp logic ---

{
  package Test::Cake::Timestamps;
  use DBIO::Cake;
  table 'ts';
  col created_at => timestamp;                  # NOT NULL → _timestamp_on_create
  col updated_at => timestamp on_update;        # NOT NULL → _timestamp_on_create + _timestamp_on_update
  col deleted_at => timestamp null;             # nullable → no auto-set
  col last_login => timestamp null, on_update;  # nullable → only _timestamp_on_update
}

{
  my $info = Test::Cake::Timestamps->columns_info;

  ok $info->{created_at}{_timestamp_on_create}, 'cake smart: NOT NULL → _timestamp_on_create';
  ok !$info->{created_at}{_timestamp_on_update}, 'cake smart: NOT NULL without on_update → no _timestamp_on_update';
  ok !$info->{created_at}{is_nullable}, 'cake smart: created_at is NOT NULL';

  ok $info->{updated_at}{_timestamp_on_create}, 'cake smart: NOT NULL + on_update → _timestamp_on_create';
  ok $info->{updated_at}{_timestamp_on_update}, 'cake smart: NOT NULL + on_update → _timestamp_on_update';

  ok !$info->{deleted_at}{_timestamp_on_create}, 'cake smart: nullable → no _timestamp_on_create';
  ok !$info->{deleted_at}{_timestamp_on_update}, 'cake smart: nullable → no _timestamp_on_update';
  ok $info->{deleted_at}{is_nullable}, 'cake smart: deleted_at is nullable';

  ok !$info->{last_login}{_timestamp_on_create}, 'cake smart: nullable + on_update → no _timestamp_on_create';
  ok $info->{last_login}{_timestamp_on_update}, 'cake smart: nullable + on_update → _timestamp_on_update';
  ok $info->{last_login}{is_nullable}, 'cake smart: last_login is nullable';
}

# --- Cake comma-free syntax ---

{
  package Test::Cake::CommaFree;
  use DBIO::Cake;
  table 'cf';
  col id     => integer auto_inc;
  col bio    => text null;
  col active => boolean default(1);
  col meta   => jsonb null;
}

{
  my $info = Test::Cake::CommaFree->columns_info;

  is $info->{id}{data_type}, 'integer', 'comma-free: integer';
  ok $info->{id}{is_auto_increment}, 'comma-free: auto_inc passed through';

  is $info->{bio}{data_type}, 'text', 'comma-free: text';
  ok $info->{bio}{is_nullable}, 'comma-free: null passed through';

  is $info->{active}{data_type}, 'boolean', 'comma-free: boolean';
  is $info->{active}{default_value}, 1, 'comma-free: default passed through';

  is $info->{meta}{data_type}, 'jsonb', 'comma-free: jsonb';
  ok $info->{meta}{is_nullable}, 'comma-free: null on jsonb';
}

# --- Cake scalar ref defaults ---

{
  package Test::Cake::ScalarRef;
  use DBIO::Cake;
  table 'sr';
  col id   => uuid, \"gen_random_uuid()";
  col flag => boolean, \1;
}

{
  my $info = Test::Cake::ScalarRef->columns_info;

  is ref $info->{id}{default_value}, 'SCALAR', 'scalarref: uuid default is scalar ref';
  is ${$info->{id}{default_value}}, 'gen_random_uuid()', 'scalarref: uuid default value';

  is ref $info->{flag}{default_value}, 'SCALAR', 'scalarref: boolean default is scalar ref';
  is ${$info->{flag}{default_value}}, 1, 'scalarref: boolean default value';
}

# --- Cake UUID auto retrieve_on_insert ---

{
  package Test::Cake::UUID;
  use DBIO::Cake;
  table 'uu';
  col id       => uuid;
  col optional => uuid null;
}

{
  my $info = Test::Cake::UUID->columns_info;
  ok $info->{id}{retrieve_on_insert}, 'uuid: NOT NULL → retrieve_on_insert';
  ok !$info->{optional}{retrieve_on_insert}, 'uuid: nullable → no retrieve_on_insert';
}

# --- Cake PostgreSQL types ---

{
  package Test::Cake::PgTypes;
  use DBIO::Cake;
  table 'pg';
  col embed  => vector(1536);
  col tags   => array(text), null;
  col search => tsvector null;
  col addr   => inet null;
  col range  => int4range null;
}

{
  my $info = Test::Cake::PgTypes->columns_info;
  is $info->{embed}{data_type}, 'vector', 'pg: vector type';
  is $info->{embed}{size}, 1536, 'pg: vector size';
  is $info->{tags}{data_type}, 'text[]', 'pg: array(text) → text[]';
  is $info->{search}{data_type}, 'tsvector', 'pg: tsvector';
  is $info->{addr}{data_type}, 'inet', 'pg: inet';
  is $info->{range}{data_type}, 'int4range', 'pg: int4range';
}

done_testing;
