use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Sybase::DDL;

# The index declaration is canonical on the result source (ADR 0061 in core,
# karr k88): Cake idx and indices() write it, and the DDL reads it. Before,
# only unique columns and unique constraints became an index, and a Cake class
# declaring idx got no CREATE INDEX at all.

{
  package IdxDdl::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}
{
  package IdxDdl::Schema::Result::Person;
  use DBIO::Cake;

  table 'person';
  col id    => integer auto_inc;
  col name  => varchar(100);
  col city  => varchar(100);
  col state => varchar(10);
  col email => varchar(100), is_unique => 1;

  primary_key 'id';

  idx name_idx      => ['name'];
  idx name_city_uq  => ['name', 'city'], type => 'unique';

  __PACKAGE__->indices(state_idx => 'state');
}
IdxDdl::Schema->register_class(Person => 'IdxDdl::Schema::Result::Person');

# --- install_ddl carries the canonical declarations
{
  my $ddl = DBIO::Sybase::DDL->install_ddl('IdxDdl::Schema');
  like $ddl, qr/^CREATE INDEX name_idx ON person \(name\);$/m,
    'idx: simple index';
  like $ddl, qr/^CREATE UNIQUE INDEX name_city_uq ON person \(name, city\);$/m,
    'idx: unique, several columns';
  like $ddl, qr/^CREATE INDEX state_idx ON person \(state\);$/m,
    'indices(): index';
  like $ddl, qr/CREATE TABLE person.*CREATE INDEX name_idx/s,
    'the index comes after its CREATE TABLE';
}

# --- duplicates: the same columns in the same order as an index already written
# Claim: a declared index over exactly the columns of a unique index (column
# flag, unique constraint, primary key) is a second index for the same lookups
# and is not written; another order is another index.
{
  package IdxDdl::Dup::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}
{
  package IdxDdl::Dup::Schema::Result::Thing;
  use DBIO::Cake;

  table 'thing';
  col id    => integer auto_inc;
  col a     => varchar(20);
  col b     => varchar(20);
  col code  => varchar(20), is_unique => 1;

  primary_key 'id';
  unique ab_uq => ['a', 'b'];

  idx code_idx => ['code'];          # the column flag already has it
  idx pk_idx   => ['id'];            # the primary key has it
  idx ab_idx   => ['a', 'b'];        # the constraint has it
  idx ab_uq    => ['a', 'b'];        # same name, same columns
  idx ba_idx   => ['b', 'a'];        # another order: written
}
IdxDdl::Dup::Schema->register_class(Thing => 'IdxDdl::Dup::Schema::Result::Thing');

{
  my $ddl = DBIO::Sybase::DDL->install_ddl('IdxDdl::Dup::Schema');
  unlike $ddl, qr/\bcode_idx/, 'dedupe: index over a unique column is not written';
  unlike $ddl, qr/\bpk_idx/, 'dedupe: index over the primary key is not written';
  unlike $ddl, qr/\bab_idx/, 'dedupe: index over a unique constraint is not written';
  is scalar(() = $ddl =~ /INDEX ab_uq\b/g), 1, 'same name: one CREATE only';
  like $ddl, qr/^CREATE INDEX ba_idx ON thing \(b, a\);$/m,
    'dedupe: other column order is another index and is written';
}

# --- same name, other columns: refused, not silently dropped
{
  package IdxDdl::Clash::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}
{
  package IdxDdl::Clash::Schema::Result::Thing;
  use DBIO::Cake;
  table 'thing';
  col id => integer auto_inc;
  col a  => varchar(20);
  col b  => varchar(20);
  primary_key 'id';
  unique ab_uq => ['a'];
  idx ab_uq => ['b'];
}
IdxDdl::Clash::Schema->register_class(Thing => 'IdxDdl::Clash::Schema::Result::Thing');

throws_ok { DBIO::Sybase::DDL->install_ddl('IdxDdl::Clash::Schema') }
  qr/index 'ab_uq'.*already/s,
  'same name over other columns than a written index: refused, naming the index';

# --- what ASE cannot do is refused, naming the index
my $n = 0;
sub refused {
  my ($decl, $re, $label) = @_;
  my $schema = 'IdxDdl::Ref' . ++$n;
  my $result = "${schema}::Result::T";
  {
    no strict 'refs';
    @{"${schema}::ISA"} = ('DBIO::Schema');
    @{"${result}::ISA"} = ('DBIO::Core');
  }
  $schema->load_components('Sybase');
  $result->table('t');
  $result->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    (map { ("c$_" => { data_type => 'varchar', size => 10 }) } 1 .. 32),
  );
  $result->set_primary_key('id');
  $result->result_source_instance->add_index_declaration($decl);
  $schema->register_class(T => $result);
  throws_ok { DBIO::Sybase::DDL->install_ddl($schema) } $re, $label;
}

refused({ name => 'p_idx', columns => ['c1'], driver => { sybase => { where => 'c1 > 1' } } },
  qr/index 'p_idx': unknown key 'where' in its 'sybase' block/,
  'where (partial index): refused, naming the index');
refused({ name => 'e_idx', columns => ['c1'], driver => { sybase => { expression => 'lower(c1)' } } },
  qr/index 'e_idx': unknown key 'expression' in its 'sybase' block/,
  'expression (function index): refused, naming the index');
refused({ name => 'f_idx', columns => ['c1'], driver => { pg => { where => 'c1 > 1' } } },
  qr/index 'f_idx' carries only the 'pg' block and none for 'sybase'/,
  'only another driver block: refused, naming the index');
refused({ name => 'ft_idx', columns => ['c1'], type => 'fulltext' },
  qr/index 'ft_idx'.*type 'fulltext'/s,
  'type other than unique: refused, naming the index');
refused({ name => 'o_idx', columns => ['c1'], options => { fillfactor => 70 } },
  qr/index 'o_idx'.*options/s,
  'options: refused, naming the index');
refused({ name => 'w_idx', columns => [ map "c$_", 1 .. 32 ] },
  qr/index 'w_idx'.*32 columns.*31/s,
  'more than 31 key columns: refused, naming the index');

# --- the empty own block is the plain index; type => unique is unique
{
  package IdxDdl::Own::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}
{
  package IdxDdl::Own::Schema::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 50 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'title_idx', columns => ['title'], type => 'UNIQUE',
    driver => { sybase => {}, pg => { using => 'gin' } },
  });
}
IdxDdl::Own::Schema->register_class(Doc => 'IdxDdl::Own::Schema::Result::Doc');

{
  my $ddl;
  lives_ok { $ddl = DBIO::Sybase::DDL->install_ddl('IdxDdl::Own::Schema') }
    'an empty sybase block does not refuse';
  like $ddl, qr/^CREATE UNIQUE INDEX title_idx ON doc \(title\);$/m,
    'empty own block: the plain (here unique) index, the pg block ignored';
}

done_testing;
