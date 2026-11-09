use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Oracle::DDL;

# The index declaration is canonical on the result source (ADR 0061 in core,
# karr k51): Cake idx and indices() write it, and install_ddl reads it.
# Before, a Cake class got no CREATE INDEX at all. Offline: the DDL only.
#
# Claims: idx/indices() become CREATE [UNIQUE] INDEX after the table; the
# oracle block takes only 'expression'; where is refused
# (Oracle has no partial index); type other than unique and options are
# refused loudly, never written as a plainer index; a declaration of the
# same name as a unique constraint, or over its columns, is refused (karr k46).

{
  package IdxOra::Schema;
  use base 'DBIO::Schema';
}
{
  package IdxOra::Schema::Result::Person;
  use DBIO::Cake;

  table 'person';
  col id    => integer auto_inc;
  col name  => varchar(100);
  col city  => varchar(100);
  col state => varchar(10);

  primary_key 'id';

  idx name_idx     => ['name'];
  idx name_city_uq => ['name', 'city'], type => 'unique';

  __PACKAGE__->indices(state_idx => 'state');
}
IdxOra::Schema->register_class(Person => 'IdxOra::Schema::Result::Person');

{
  my $ddl = DBIO::Oracle::DDL->install_ddl('IdxOra::Schema');
  like $ddl, qr/^CREATE INDEX "name_idx" ON "person" \("name"\);$/m,
    'idx: simple index';
  like $ddl, qr/^CREATE UNIQUE INDEX "name_city_uq" ON "person" \("name", "city"\);$/m,
    'idx: unique, several columns';
  like $ddl, qr/^CREATE INDEX "state_idx" ON "person" \("state"\);$/m,
    'indices(): index';
}

# --- own oracle block: expression, and the collision
{
  package IdxOra::Own::Schema;
  use base 'DBIO::Schema';
}
{
  package IdxOra::Own::Schema::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 100 },
    code  => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->set_primary_key('id');
  my $src = __PACKAGE__->result_source_instance;
  $src->add_index_declaration({
    name => 'doc_title_lower', columns => ['title'],
    driver => { oracle => { expression => 'LOWER(title)' } },
  });
  $src->add_index_declaration({
    name => 'doc_title_idx', columns => ['title'], unique => 1,
    driver => { oracle => {} },
  });
}
IdxOra::Own::Schema->register_class(Doc => 'IdxOra::Own::Schema::Result::Doc');

{
  my $ddl = DBIO::Oracle::DDL->install_ddl('IdxOra::Own::Schema');
  like $ddl, qr/^CREATE INDEX "doc_title_lower" ON "doc" \(LOWER\(title\)\);$/m,
    'expression: the text stands in the parentheses';
  like $ddl, qr/^CREATE UNIQUE INDEX "doc_title_idx" ON "doc" \("title"\);$/m,
    'unique declaration, empty oracle block';
}

# --- refusals
my $refuse_count = 0;
sub refused_ddl {
  my ($decl) = @_;
  my $n = ++$refuse_count;
  my $schema = "IdxOra::Refuse$n";
  my $class  = "$schema\::Result::T";
  eval qq{
    package $schema; use base 'DBIO::Schema';
    package $class; use base 'DBIO::Core';
    $class->table('t');
    $class->add_columns(id => { data_type => 'integer' }, a => { data_type => 'integer' });
    $class->set_primary_key('id');
    1;
  } or die $@;
  $class->result_source_instance->add_index_declaration($decl);
  $schema->register_class(T => $class);
  return sub { DBIO::Oracle::DDL->install_ddl($schema) };
}

throws_ok { refused_ddl({
    name => 'p_idx', columns => ['a'], driver => { oracle => { where => 'a > 1' } },
  })->() } qr/'p_idx'.*unknown key 'where'/s,
  'where is refused: Oracle has no partial index';

throws_ok { refused_ddl({
    name => 'h_idx', columns => ['a'], type => 'hash',
  })->() } qr/t: index 'h_idx': type 'hash'/,
  'type other than unique is refused, naming table and index';

throws_ok { refused_ddl({
    name => 'o_idx', columns => ['a'], options => { fillfactor => 70 },
  })->() } qr/t: index 'o_idx': options/,
  'options are refused, naming table and index';

throws_ok { refused_ddl({
    name => 'f_idx', columns => ['a'], driver => { pg => {} },
  })->() } qr/'f_idx'.*'pg'.*none for 'oracle'/s,
  'a foreign block alone is refused by the helper';

done_testing;
