use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Diff::Op ();
use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Extension;
use DBIO::PostgreSQL::Diff::Schema;

# karr k106, k107, k108, k109 -- the diff orders its operations by dependency.
#
# WHY it exists: the diff used to walk its sections in one fixed order and
# write whatever each section returned, creating and dropping mixed. Creating
# needs the order of dependency -- the schema before its table, the type
# before the column of that type. Dropping needs the reverse, and that the
# old order did not give: it dropped the schema before the table in it
# (k109), the extension before what hung on it (k108), the function before
# the trigger calling it, the type -- with CASCADE -- before the column of
# that type, the column before its index. Each of those is a statement naming
# an object the statement before it has just removed; apply died on it.
#
# What is held here, without a database (t/93 holds it against a server):
#
#  1. what is created or changed comes first, in the order of dependency;
#     what goes away comes after all of it, in the reverse order;
#  2. the drop that is half of a drop-and-recreate (a changed index, a
#     changed trigger) stays with its create;
#  3. a schema comes before the extension that is installed into it (k106);
#  4. between extensions the order is the dependency the model carries, not
#     the name (k108);
#  5. a class registered by another distribution gets both halves;
#  6. a DROP SCHEMA ... CASCADE that would take an extension the diff keeps
#     is refused.

# "Kind action" of every op, e.g. "Extension drop".
sub op_kinds {
  my ($diff) = @_;
  return [ map { (ref($_) =~ /::(\w+)\z/)[0] . ' ' . $_->action } @{ $diff->operations } ];
}

# The position of the one statement matching $re among the statements of
# $diff, or undef.
sub stmt_pos {
  my ($diff, $re) = @_;
  my @stmts = map { $_->as_sql } @{ $diff->operations };
  my @at = grep { $stmts[$_] =~ $re } 0 .. $#stmts;
  return @at == 1 ? $at[0] : undef;
}

sub comes_before {
  my ($diff, $first, $then, $why) = @_;
  my ($a, $b) = map { stmt_pos($diff, $_) } $first, $then;
  ok(defined $a && defined $b && $a < $b, $why)
    or diag "wanted $first before $then in:\n" . $diff->as_sql;
}

sub table {
  my ($schema, $name, %more) = @_;
  return ("$schema.$name" => { schema_name => $schema, table_name => $name, kind => 'r', %more });
}

sub index_on {
  my ($schema, $table, $name, $column) = @_;
  return ($name => {
    schema_name => $schema,
    table_name  => $table,
    index_name  => $name,
    definition  => "CREATE INDEX $name ON $schema.$table USING btree ($column)",
    columns     => [$column],
  });
}

sub trigger_on {
  my ($schema, $table, $name, $function) = @_;
  return ($name => {
    schema_name  => $schema,
    table_name   => $table,
    trigger_name => $name,
    definition   => "CREATE TRIGGER $name BEFORE UPDATE ON $schema.$table FOR EACH ROW EXECUTE FUNCTION $function()",
  });
}

sub function {
  my ($schema, $name) = @_;
  return ("$schema.$name()" => {
    schema_name   => $schema,
    function_name => $name,
    identity_args => '',
    definition    => "CREATE OR REPLACE FUNCTION $schema.$name() RETURNS trigger LANGUAGE plpgsql AS \$\$BEGIN RETURN NEW; END\$\$",
  });
}

sub enum {
  my ($schema, $name) = @_;
  return ("$schema.$name" => {
    schema_name => $schema, type_name => $name, type_kind => 'enum', values => [qw(a b)],
  });
}

# ---------------------------------------------------------------------------
# 1. One model that creates and drops in every section
# ---------------------------------------------------------------------------

# The database has a schema old_ns with everything in it, an extension, and
# on the table that stays a column with its index and a trigger. The target
# has none of that and one of each in new_ns instead.
my %source = (
  schemas    => { public => {}, old_ns => {} },
  extensions => { old_ext => { extension_name => 'old_ext', version => '1.0', schema_name => 'public' } },
  types      => { enum(old_ns => 'old_type') },
  functions  => { function(old_ns => 'old_fn') },
  tables     => { table(old_ns => 'gone'), table(public => 'keep') },
  columns    => {
    'old_ns.gone' => [ { column_name => 'id', data_type => 'integer' } ],
    'public.keep' => [
      { column_name => 'id',      data_type => 'integer' },
      { column_name => 'old_col', data_type => 'old_ns.old_type' },
    ],
  },
  indexes    => {
    'old_ns.gone' => { index_on(old_ns => 'gone', 'gone_idx', 'id') },
    'public.keep' => { index_on(public => 'keep', 'keep_old_idx', 'old_col') },
  },
  triggers   => {
    'old_ns.gone' => { trigger_on(old_ns => 'gone', 'gone_trg', 'old_ns.old_fn') },
    'public.keep' => { trigger_on(public => 'keep', 'keep_old_trg', 'old_ns.old_fn') },
  },
  policies   => {
    'old_ns.gone' => { gone_pol => {
      schema_name => 'old_ns', table_name => 'gone', policy_name => 'gone_pol', using_expr => 'id > 0',
    } },
  },
);

my %target = (
  schemas    => { public => {}, new_ns => {} },
  extensions => { new_ext => { extension_name => 'new_ext', version => '1.0', schema_name => 'new_ns' } },
  types      => { enum(new_ns => 'new_type') },
  functions  => { function(new_ns => 'new_fn') },
  tables     => { table(new_ns => 'fresh'), table(public => 'keep') },
  columns    => {
    'new_ns.fresh' => [ { column_name => 'id', data_type => 'integer' } ],
    'public.keep'  => [
      { column_name => 'id',      data_type => 'integer' },
      { column_name => 'new_col', data_type => 'new_ns.new_type' },
    ],
  },
  indexes    => {
    'public.keep' => { index_on(public => 'keep', 'keep_new_idx', 'new_col') },
  },
  triggers   => {
    'public.keep' => { trigger_on(public => 'keep', 'keep_new_trg', 'new_ns.new_fn') },
  },
  policies   => {
    'public.keep' => { keep_new_pol => {
      schema_name => 'public', table_name => 'keep', policy_name => 'keep_new_pol', using_expr => 'id > 0',
    } },
  },
);

{
  my $diff = DBIO::PostgreSQL::Diff->new(source => \%source, target => \%target);

  is_deeply(op_kinds($diff), [
    # created, in the order of dependency
    'Schema create',
    'Extension create',
    'Type create',
    'Function create',
    'Table create',
    'Column add',
    'Index create',
    'Trigger create',
    'Policy create',
    # dropped, in the reverse order
    'Policy drop',
    'Trigger drop',
    'Trigger drop',
    'Index drop',
    'Column drop',
    'Table drop',
    'Function drop',
    'Type drop',
    'Extension drop',
    'Schema drop',
  ], 'what is created comes first in the order of dependency, what is dropped after it in the reverse order')
    or diag $diff->as_sql;

  # The claims one by one, each for the failure it stands against.
  comes_before($diff, qr/^DROP TABLE old_ns\.gone;/, qr/^DROP SCHEMA old_ns;/,
    'k109: the table is dropped before the schema it is in');
  comes_before($diff, qr/^DROP TRIGGER gone_trg ON old_ns\.gone;/, qr/^DROP TABLE old_ns\.gone;/,
    'k109: a trigger is dropped before its table');
  comes_before($diff, qr/^DROP POLICY gone_pol ON old_ns\.gone;/, qr/^DROP TABLE old_ns\.gone;/,
    'a policy is dropped before its table');
  comes_before($diff, qr/^DROP TRIGGER keep_old_trg ON public\.keep;/, qr/^DROP FUNCTION old_ns\.old_fn\(\);/,
    'a trigger is dropped before the function it calls');
  comes_before($diff, qr/^DROP INDEX public\.keep_old_idx;/, qr/^ALTER TABLE public\.keep DROP COLUMN old_col;/,
    'an index is dropped before the column it is on');
  comes_before($diff, qr/^ALTER TABLE public\.keep DROP COLUMN old_col;/, qr/^DROP TYPE old_ns\.old_type;/,
    'a column is dropped before the type it has');
  comes_before($diff, qr/^DROP FUNCTION old_ns\.old_fn\(\);/, qr/^DROP EXTENSION old_ext;/,
    'k108: an extension is dropped after whatever may hang on it');
  comes_before($diff, qr/^DROP EXTENSION old_ext;/, qr/^DROP SCHEMA old_ns;/,
    'k106: an extension is dropped before a schema');
  comes_before($diff, qr/^CREATE SCHEMA new_ns;/, qr/^CREATE EXTENSION IF NOT EXISTS new_ext;/,
    'k106: a schema is created before the extension that is installed into it');
  comes_before($diff, qr/^CREATE EXTENSION IF NOT EXISTS new_ext;/, qr/^CREATE TYPE new_ns\.new_type/,
    'an extension is created before the types, functions and tables that may use what it brings');
  comes_before($diff, qr/^CREATE POLICY keep_new_pol/, qr/^DROP POLICY gone_pol/,
    'the last thing created comes before the first thing dropped');

  unlike($diff->as_sql, qr/DROP INDEX old_ns\.gone_idx/,
    'k32 still holds: the index of a dropped table is left to DROP TABLE ... CASCADE');

  # summary and as_sql are the same operations in the same order.
  my @sql     = split /\n/, $diff->as_sql;
  my @summary = split /\n/, $diff->summary;
  is($sql[0],      'CREATE SCHEMA new_ns;',       'as_sql begins with the schema that is created');
  like($summary[0], qr/^\s*\+schema: new_ns\z/,   'and so does summary');
  is($sql[-1],     'DROP SCHEMA old_ns;', 'as_sql ends with the schema that is dropped');
  like($summary[-1], qr/^\s*-schema: old_ns\z/,   'and so does summary');
}

# ---------------------------------------------------------------------------
# 2. A drop that is half of a drop-and-recreate stays with its create
# ---------------------------------------------------------------------------

# A changed index and a changed trigger are dropped and created again. That
# drop is no removal: put with the removals, behind everything created, it
# would come after its own CREATE -- which then finds the name taken.
{
  my $source = {
    tables   => { table(public => 'keep') },
    columns  => { 'public.keep' => [
      { column_name => 'id', data_type => 'integer' },
      { column_name => 'a',  data_type => 'integer' },
      { column_name => 'b',  data_type => 'integer' },
    ] },
    indexes  => { 'public.keep' => { index_on(public => 'keep', 'keep_idx', 'b') } },
    triggers => { 'public.keep' => { trigger_on(public => 'keep', 'keep_trg', 'public.old_fn') } },
    functions => { function(public => 'old_fn') },
  };
  my $target = {
    tables   => { table(public => 'keep') },
    columns  => { 'public.keep' => [
      { column_name => 'id', data_type => 'integer' },
      { column_name => 'a',  data_type => 'integer' },
    ] },
    indexes  => { 'public.keep' => { index_on(public => 'keep', 'keep_idx', 'a') } },
    triggers => { 'public.keep' => { trigger_on(public => 'keep', 'keep_trg', 'public.new_fn') } },
    functions => { function(public => 'new_fn') },
  };
  my $diff = DBIO::PostgreSQL::Diff->new(source => $source, target => $target);

  is_deeply(op_kinds($diff), [
    'Function create',
    'Index drop', 'Index create',
    'Trigger drop', 'Trigger create',
    'Column drop',
    'Function drop',
  ], 'a changed index and a changed trigger are dropped and recreated in place, ahead of the removals')
    or diag $diff->as_sql;

  comes_before($diff, qr/^DROP INDEX public\.keep_idx;/, qr/^CREATE INDEX keep_idx /,
    'the index is dropped before it is created again');
  comes_before($diff, qr/^CREATE INDEX keep_idx /, qr/^ALTER TABLE public\.keep DROP COLUMN b;/,
    'and is off the column before the column is dropped');
  comes_before($diff, qr/^CREATE TRIGGER keep_trg /, qr/^DROP FUNCTION public\.old_fn\(\);/,
    'the trigger calls the new function before the old one is dropped');

  my ($index_drop) = grep { $_->isa('DBIO::PostgreSQL::Diff::Index') && $_->action eq 'drop' }
    @{ $diff->operations };
  ok(eval { $index_drop->replaced }, 'the drop of a changed index says that the index is replaced')
    or diag $@;
}

# A table that goes while another one takes over its index name: the two
# index entries are one index by schema and name, with a changed definition.
# Its drop belongs to the recreate, ahead of DROP TABLE ... CASCADE -- left
# for after it, the index would be gone already.
{
  my $source = {
    tables  => { table(public => 'old_tab') },
    columns => { 'public.old_tab' => [ { column_name => 'n', data_type => 'integer' } ] },
    indexes => { 'public.old_tab' => { index_on(public => 'old_tab', 'n_idx', 'n') } },
  };
  my $target = {
    tables  => { table(public => 'new_tab') },
    columns => { 'public.new_tab' => [ { column_name => 'n', data_type => 'integer' } ] },
    indexes => { 'public.new_tab' => { index_on(public => 'new_tab', 'n_idx', 'n') } },
  };
  my $diff = DBIO::PostgreSQL::Diff->new(source => $source, target => $target);

  is_deeply(op_kinds($diff), [ 'Table create', 'Index drop', 'Index create', 'Table drop' ],
    'an index name that moves to a new table is freed before the old table is dropped')
    or diag $diff->as_sql;
}

# A column that changes to a new type while its old type goes: the ALTER must
# have run before DROP TYPE ... CASCADE, which would otherwise take the column.
{
  my $column = sub { { 'public.keep' => [ { column_name => 'state', data_type => $_[0] } ] } };
  my $diff = DBIO::PostgreSQL::Diff->new(
    source => {
      tables => { table(public => 'keep') }, columns => $column->('public.old_state'),
      types  => { enum(public => 'old_state') },
    },
    target => {
      tables => { table(public => 'keep') }, columns => $column->('public.new_state'),
      types  => { enum(public => 'new_state') },
    },
  );

  is_deeply(op_kinds($diff), [ 'Type create', 'Column alter', 'Type drop' ],
    'a column is moved to its new type before the old type is dropped with CASCADE')
    or diag $diff->as_sql;
}

# ---------------------------------------------------------------------------
# 3. Between extensions, the dependency decides (k108)
# ---------------------------------------------------------------------------

# mid requires both "aaa" and "zzz". By name, mid would be created before zzz
# and dropped after aaa; both fail on the server ('required extension "zzz"
# is not installed', 'cannot drop extension aaa because other objects depend
# on it').
{
  my %ext = (
    aaa   => { extension_name => 'aaa',   version => '1', requires => [] },
    mid   => { extension_name => 'mid',   version => '1', requires => [qw( aaa zzz )] },
    zzz   => { extension_name => 'zzz',   version => '1', requires => [] },
    other => { extension_name => 'other', version => '1', requires => ['plpgsql_is_not_here'] },
  );
  my $names = sub { [ map { $_->action . ' ' . $_->extension_name } @_ ] };

  is_deeply($names->(DBIO::PostgreSQL::Diff::Extension->diff({}, \%ext)),
    [ 'create aaa', 'create zzz', 'create mid', 'create other' ],
    'an extension is created after every extension it requires');

  is_deeply($names->(DBIO::PostgreSQL::Diff::Extension->diff(\%ext, {})),
    [ 'drop mid', 'drop aaa', 'drop other', 'drop zzz' ],
    'an extension is dropped before every extension it requires');

  # Through the whole diff as well -- the order is the class's own and must
  # survive the arranging of the sections.
  my $diff = DBIO::PostgreSQL::Diff->new(source => { extensions => \%ext }, target => { extensions => {} });
  is_deeply($names->(@{ $diff->operations }),
    [ 'drop mid', 'drop aaa', 'drop other', 'drop zzz' ],
    'the full diff keeps the order of the extensions');

  # An update is a change, in the order of dependency like a create.
  my %newer = map { $_ => { %{ $ext{$_} }, version => '2' } } qw( aaa mid zzz );
  is_deeply($names->(DBIO::PostgreSQL::Diff::Extension->diff({ map { $_ => $ext{$_} } qw( aaa mid zzz ) }, \%newer)),
    [ 'update aaa', 'update zzz', 'update mid' ],
    'updates follow the dependency too');

  # A model without the dependency -- built by hand, or by an older
  # introspection -- is ordered by name, as before.
  my %plain = map { $_ => { extension_name => $_, version => '1' } } qw( b a c );
  is_deeply($names->(DBIO::PostgreSQL::Diff::Extension->diff({}, \%plain)),
    [ 'create a', 'create b', 'create c' ], 'without a dependency the name decides: creates');
  is_deeply($names->(DBIO::PostgreSQL::Diff::Extension->diff(\%plain, {})),
    [ 'drop a', 'drop b', 'drop c' ], 'without a dependency the name decides: drops');

  # PostgreSQL allows no cycle between extensions; a model that has one must
  # still come back with every extension, once.
  my %cycle = (
    x => { extension_name => 'x', version => '1', requires => ['y'] },
    y => { extension_name => 'y', version => '1', requires => ['x'] },
  );
  is_deeply([ sort @{ $names->(DBIO::PostgreSQL::Diff::Extension->diff({}, \%cycle)) } ],
    [ 'create x', 'create y' ], 'a cycle in the model does not lose or repeat an extension');
}

# ---------------------------------------------------------------------------
# 4. A registered class gets both halves
# ---------------------------------------------------------------------------

{
  package T92::Diff::Thing;
  use base 'DBIO::Diff::Op';
  __PACKAGE__->mk_diff_accessors(qw( name replaced ));

  # create what only the target has, drop what only the source has, and drop
  # and recreate what both have with a different value.
  sub diff {
    my ($class, $source, $target) = @_;
    my @ops;
    for my $name (sort keys %$target) {
      if (!exists $source->{$name}) {
        push @ops, $class->new(action => 'create', name => $name);
      }
      elsif ($source->{$name} ne $target->{$name}) {
        push @ops, $class->new(action => 'drop', name => $name, replaced => 1);
        push @ops, $class->new(action => 'create', name => $name);
      }
    }
    push @ops, map { $class->new(action => 'drop', name => $_) }
      grep { !exists $target->{$_} } sort keys %$source;
    return @ops;
  }
  sub as_sql  { uc($_[0]->action) . ' THING ' . $_[0]->name . ';' }
  sub summary { '  thing ' . $_[0]->name }
}

DBIO::PostgreSQL::Diff->register_diff_class(
  model_key => 't92_things',
  class     => 'T92::Diff::Thing',
  position  => 'after:indexes',
);

{
  my $diff = DBIO::PostgreSQL::Diff->new(
    source => { %source, t92_things => { gone => 1, changed => 1 } },
    target => { %target, t92_things => { fresh => 1, changed => 2 } },
  );
  my @kinds = @{ op_kinds($diff) };
  my @things = grep { $kinds[$_] =~ /^Thing / } 0 .. $#kinds;

  is_deeply([ @kinds[ $things[0] - 1 .. $things[2] + 1 ] ],
    [ 'Index create', 'Thing drop', 'Thing create', 'Thing create', 'Trigger create' ],
    'what a registered class creates or replaces is at its position among the creates')
    or diag $diff->as_sql;

  is_deeply([ @kinds[ $things[3] - 1 .. $things[3] + 1 ] ],
    [ 'Trigger drop', 'Thing drop', 'Index drop' ],
    'what it removes is at the mirrored position among the drops')
    or diag $diff->as_sql;

  is(scalar @things, 4, 'and every one of its operations is there once');
}

# ---------------------------------------------------------------------------
# 5. DROP SCHEMA ... CASCADE under an extension that stays is refused
# ---------------------------------------------------------------------------

# An extension depends on the schema it is installed in, so DROP SCHEMA ...
# CASCADE drops the extension -- and with it every column of a type it
# brings. When the extension goes anyway it is dropped first and nothing is
# lost that the diff did not name. When the diff keeps it, the statement
# would destroy what it was not asked to touch.
{
  my $vector_in = sub { { vector => { extension_name => 'vector', version => '0.8', schema_name => $_[0] } } };

  throws_ok {
    DBIO::PostgreSQL::Diff->new(
      source => { schemas => { public => {}, ext => {} }, extensions => $vector_in->('ext') },
      target => { schemas => { public => {} },            extensions => $vector_in->('public') },
    )->operations;
  } qr/\Arefusing to diff: .*schema ext\b.*extension vector\b/s,
    'a schema to be dropped with a kept extension installed in it is refused, naming both';

  my $diff = DBIO::PostgreSQL::Diff->new(
    source => { schemas => { public => {}, ext => {} }, extensions => $vector_in->('ext') },
    target => { schemas => { public => {} },            extensions => {} },
  );
  is_deeply(op_kinds($diff), [ 'Extension drop', 'Schema drop' ],
    'when the extension goes as well, it is dropped ahead of its schema and nothing is refused');

  lives_ok {
    DBIO::PostgreSQL::Diff->new(
      source => { schemas => { public => {}, ext => {} }, extensions => $vector_in->('ext') },
      target => { schemas => { public => {}, ext => {} }, extensions => $vector_in->('public') },
    )->operations;
  } 'a kept extension in a kept schema is nobody\'s business';

  lives_ok { DBIO::PostgreSQL::Diff::Schema->diff({ gone => {} }, {}) }
    'the schema diff on its own, without the extensions, drops as before';
}

done_testing;
