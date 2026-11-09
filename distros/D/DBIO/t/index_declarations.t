use strict;
use warnings;
use Test::More;
use Test::Exception;

# The canonical index declaration lives on the ResultSource, one namespace.
# Cake idx and ResultSourceProxy indices fill it; every driver reads it.

{
  package IdxDecl::Result::Artist;
  use DBIO::Cake;

  table 'artists';
  col id    => integer auto_inc;
  col name  => varchar(100);
  col city  => varchar(100);
  col tags  => text null;
  col state => varchar(10);

  primary_key 'id';

  idx plain_idx  => ['name'];
  idx uniq_idx   => ['name', 'city'], type => 'unique';
  idx tags_idx   => ['tags'], pg => { using => 'gin', where => 'tags IS NOT NULL' };
  idx part_uniq  => ['name'], type => 'unique',
    pg => { where => 'state = 1', with => { fillfactor => 70 },
            expression => 'lower(name)', using => 'btree' };

  __PACKAGE__->indices(
    state_idx => 'state',
    city_idx  => ['city', 'state'],
  );
}

my $source = IdxDecl::Result::Artist->result_source_instance;

# (a) order and canonical shape
{
  my @decl = $source->index_declarations;
  is_deeply [ map $_->{name}, @decl ],
    [qw(plain_idx uniq_idx tags_idx part_uniq city_idx state_idx)],
    'declarations in declaration order (indices() sorts its own names)'
    or diag explain [ map $_->{name}, @decl ];

  my %by = map { $_->{name} => $_ } @decl;
  is_deeply $by{plain_idx},
    { name => 'plain_idx', columns => ['name'], unique => 0,
      type => undef, options => undef, driver => {} },
    'plain idx: canonical entry';
  is $by{uniq_idx}{unique}, 1, 'type => unique sets unique';
  is $by{uniq_idx}{type}, 'unique', 'raw type kept';
  is_deeply $by{tags_idx}{driver},
    { pg => { using => 'gin', where => 'tags IS NOT NULL' } },
    'pg block lands under driver.pg';
  is_deeply $by{state_idx}{columns}, ['state'],
    'scalar column of indices() promoted';
  is_deeply $by{city_idx}{driver}, {}, 'indices() carries no driver block';
}

# (b) a driver-style reader that knows no pg namespace
{
  package IdxDecl::MockReader;
  sub create_index_sql {
    my ($class, $result_class) = @_;
    my $src = $result_class->result_source_instance;
    return [
      map {
        sprintf 'CREATE %sINDEX %s ON %s (%s)',
          ($_->{unique} ? 'UNIQUE ' : ''), $_->{name}, $src->name,
          join(', ', @{ $_->{columns} })
      } $src->index_declarations
    ];
  }
}
{
  my $sql = IdxDecl::MockReader->create_index_sql('IdxDecl::Result::Artist');
  is_deeply $sql, [
    'CREATE INDEX plain_idx ON artists (name)',
    'CREATE UNIQUE INDEX uniq_idx ON artists (name, city)',
    'CREATE INDEX tags_idx ON artists (tags)',
    'CREATE UNIQUE INDEX part_uniq ON artists (name)',
    'CREATE INDEX city_idx ON artists (city, state)',
    'CREATE INDEX state_idx ON artists (state)',
  ], 'a reader of index_declarations sees every Cake and indices() index';
}

# (c) same name replaces in place
{
  package IdxDecl::Result::Dup;
  use DBIO::Cake;
  table 'dup';
  col id => integer; col a => varchar(10); col b => varchar(10);
  primary_key 'id';
  idx first  => ['a'];
  idx second => ['b'];
  idx first  => ['a', 'b'], type => 'unique';
}
{
  my @decl = IdxDecl::Result::Dup->result_source_instance->index_declarations;
  is_deeply [ map $_->{name}, @decl ], [qw(first second)],
    'redeclared name keeps its position, no duplicate';
  is_deeply $decl[0]{columns}, ['a', 'b'], 'later declaration wins';
  is $decl[0]{unique}, 1, 'later declaration wins (unique)';
}

# (d) copies
{
  my @a = $source->index_declarations;
  $a[0]{name} = 'mutated';
  push @{ $a[0]{columns} }, 'zzz';
  $a[2]{driver}{pg}{using} = 'hash';
  my @b = $source->index_declarations;
  is $b[0]{name}, 'plain_idx', 'mutating a returned entry leaves the store';
  is_deeply $b[0]{columns}, ['name'], 'columns are copied too';
  is $b[2]{driver}{pg}{using}, 'gin', 'driver blocks are copied too';
}

# (e) the declaration derives no class method; hand-written ones stay as they are
{
  for my $class (qw(IdxDecl::Result::Artist IdxDecl::Result::Vanilla)) {
    ok !$class->can('pg_indexes'), "$class: no pg_indexes derived";
    ok !$class->can('sqlt_deploy_hook'), "$class: no sqlt_deploy_hook derived";
  }
}

{
  package IdxDecl::Result::Hand;
  use base 'DBIO::Core';
  __PACKAGE__->table('hand');
  __PACKAGE__->add_columns(id => { data_type => 'integer' },
                           a  => { data_type => 'text' });
  __PACKAGE__->set_primary_key('id');
  sub pg_indexes { return { hand_idx => { columns => ['a'], include => ['id'] } } }
  sub sqlt_deploy_hook { return 'hand-hook' }
  __PACKAGE__->indices(a_idx => 'a');
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'wide_idx', columns => 'a',
    driver => { pg => { include => ['id'], opclasses => { a => 'text_pattern_ops' } } },
  });
}
{
  is_deeply(IdxDecl::Result::Hand->pg_indexes,
    { hand_idx => { columns => ['a'], include => ['id'] } },
    'handwritten pg_indexes is left exactly as written');
  is(IdxDecl::Result::Hand->sqlt_deploy_hook, 'hand-hook',
    'handwritten sqlt_deploy_hook is not wrapped');
  my %decl = map { $_->{name} => $_ }
    IdxDecl::Result::Hand->result_source_instance->index_declarations;
  is_deeply [ sort keys %decl ], [qw(a_idx wide_idx)],
    'declared indexes are in index_declarations, not in the hand method';
  is_deeply $decl{wide_idx}{driver}{pg},
    { include => ['id'], opclasses => { a => 'text_pattern_ops' } },
    'every key of the driver.pg block is kept';
}

# (f) vanilla class lands canonically
{
  package IdxDecl::Result::Vanilla;
  use base 'DBIO::Core';
  __PACKAGE__->table('vanilla');
  __PACKAGE__->add_columns(id => { data_type => 'integer' },
                           n  => { data_type => 'text' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->indices(n_idx => 'n');
}
is_deeply [ IdxDecl::Result::Vanilla->result_source_instance->index_declarations ],
  [ { name => 'n_idx', columns => ['n'], unique => 0, type => undef,
      options => undef, driver => {} } ],
  'vanilla indices() lands as canonical declaration';

# source copies carry the declarations and do not share the list
{
  my $copy = $source->new($source);
  $copy->add_index_declaration({ name => 'only_on_copy', columns => 'name' });
  is scalar($source->index_declarations), 6, 'copy does not write back';
  is scalar($copy->index_declarations), 7, 'copy carries the declarations';
}

# (g) refusals
{
  my $s = $source->new($source);
  throws_ok { $s->add_index_declaration({ columns => ['a'] }) }
    qr/name/, 'missing name refused';
  throws_ok { $s->add_index_declaration({ name => '', columns => ['a'] }) }
    qr/name/, 'empty name refused';
  throws_ok { $s->add_index_declaration({ name => 'x' }) }
    qr/columns/, 'missing columns refused';
  throws_ok { $s->add_index_declaration({ name => 'x', columns => { a => 1 } }) }
    qr/columns/, 'hashref columns refused';
  throws_ok { $s->add_index_declaration({ name => 'x', columns => [] }) }
    qr/columns/, 'empty columns refused';
  throws_ok { $s->add_index_declaration({ name => 'x', columns => 'a', driver => 'pg' }) }
    qr/driver/, 'non-hashref driver refused';
  throws_ok { $s->add_index_declaration({ name => 'x', columns => 'a', driver => { pg => 'gin' } }) }
    qr/driver.*pg|pg.*hashref/i, 'non-hashref driver block refused';
  throws_ok { $s->add_index_declaration('x') }
    qr/hashref/i, 'non-hashref argument refused';
}

done_testing;
