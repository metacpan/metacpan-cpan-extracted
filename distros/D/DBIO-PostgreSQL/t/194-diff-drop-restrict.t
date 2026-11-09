use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff;

# karr k152 -- a drop stops at the edge of the model.
#
# WHY it exists: DROP TABLE, DROP TYPE and DROP SCHEMA were written with
# CASCADE on the ground that the order of the operations has dropped what the
# model holds by then. That holds when the model is the whole database. With
# pg_schemas the model is the declared schemas only, and CASCADE took with it
# what stands outside: a materialized view of another schema that reads the
# table, the foreign key of another schema's table that points at it, the
# column of another schema's table that is of the type -- with its data, and
# without a word in the summary.
#
# The claims, without a server (t/194-diff-drop-restrict-live.t has each
# against one):
#
#  1. no drop of a table, type or schema is written with CASCADE;
#  2. a drop that meets an object of the outside_dependents section (what
#     OutsideDependents reads from pg_depend) is refused by name, with no
#     statement and no operation, and the message holds names, no values;
#  3. what the model does hold is dropped ahead of the drop that would meet it,
#     in an order any set of drops takes: keys between dropped tables, a table
#     that inherits ahead of its parent, a type ahead of the types built on it,
#     the sequences no column owns ahead of their schema;
#  4. a model without the section asks nothing.

sub table {
  my ($schema, $name, %more) = @_;
  return ("$schema.$name" => { schema_name => $schema, table_name => $name, kind => 'r', %more });
}

sub fk {
  my ($name, $schema, $table) = @_;
  return {
    constraint_name => $name, remote_schema => $schema, remote_table => $table,
    local_columns => ['ref_id'], remote_columns => ['id'],
    on_delete => 'NO ACTION', on_update => 'NO ACTION', is_deferrable => 0,
  };
}

sub diff {
  my ($source, $target) = @_;
  return DBIO::PostgreSQL::Diff->new(source => $source, target => $target);
}

sub sql { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

sub refusal {
  my ($source, $target) = @_;
  my $d = diff($source, $target);
  my $ops = eval { $d->operations };
  return ($@, $ops);
}

# --- 1. no CASCADE -------------------------------------------------------------

{
  my $source = {
    schemas => { app => {}, old => {} },
    types   => { 'app.status' => { schema_name => 'app', type_name => 'status', type_kind => 'enum', values => ['a'] } },
    tables  => { table(app => 'orders') },
  };
  my $target = { schemas => { app => {} }, types => {}, tables => {} };
  my $sql = sql(diff($source, $target));
  is_deeply $sql, [ 'DROP TABLE app.orders;', 'DROP TYPE app.status;', 'DROP SCHEMA old;' ],
    'a table, a type and a schema are dropped, in that order';
  unlike join("\n", @$sql), qr/CASCADE/, '... none of them with CASCADE';
}

# --- 2. what stands outside is named -------------------------------------------

my %outside = (
  tables => {
    'app.orders' => [
      { kind => 'materialized view', name => 'reports.monthly' },
      { kind => 'foreign key', name => 'other_orders_fkey', on => 'other.t' },
      { kind => 'partition', name => 'archive.orders_2024' },
    ],
  },
  types => {
    'app.status' => [
      { kind => 'column', name => 'other.t.status' },
      { kind => 'function', name => 'other.f(app.status)' },
      { kind => 'domain', name => 'other.status_d' },
    ],
  },
  schemas => {
    old => [ { kind => 'domain', name => 'old.d' }, { name => 'operator old.===(integer,integer)' } ],
  },
);

{
  my $source = {
    schemas => { app => {}, old => {} },
    types   => { 'app.status' => { schema_name => 'app', type_name => 'status', type_kind => 'enum', values => ['a'] } },
    tables  => { table(app => 'orders') },
    outside_dependents => \%outside,
  };

  my ($err, $ops) = refusal($source, { schemas => { app => {}, old => {} }, types => $source->{types}, tables => {} });
  like $err, qr/\Arefusing to diff: table app\.orders is not in the target and would be dropped, and these objects outside the deploy depend on it:\n/,
    'a table with dependents outside the model is refused';
  like $err, qr/^  materialized view reports\.monthly$/m, '... naming the materialized view';
  like $err, qr/^  foreign key other_orders_fkey on other\.t$/m, '... the foreign key, with the table that holds it';
  like $err, qr/^  partition archive\.orders_2024$/m, '... the partition';
  like $err, qr/without CASCADE.*No statement was generated\./s, '... and says that no statement was written';
  ok !$ops, '... and builds no operation';

  ($err) = refusal($source, { schemas => { app => {}, old => {} }, types => {}, tables => $source->{tables} });
  like $err, qr/\Arefusing to diff: enum type app\.status is not in the target and would be dropped, and these objects outside the deploy depend on it:\n/,
    'a type with dependents outside the model is refused';
  like $err, qr/^  column other\.t\.status$/m, '... naming the column';
  like $err, qr/^  function other\.f\(app\.status\)$/m, '... the function with its argument types';
  like $err, qr/^  domain other\.status_d$/m, '... the domain';

  ($err) = refusal($source, { schemas => { app => {} }, types => $source->{types}, tables => $source->{tables} });
  like $err, qr/\Arefusing to diff: schema old is not in the target and would be dropped, and these objects outside the deploy depend on it:\n/,
    'a schema with objects the model does not hold is refused';
  like $err, qr/^  domain old\.d$/m, '... naming the domain';
  like $err, qr/^  operator old\.===\(integer,integer\)$/m, '... and the operator, as the server describes it';

  $source->{tables}{'app.items'} = { schema_name => 'app', table_name => 'items', kind => 'r' };
  $source->{outside_dependents}{tables}{'app.items'} = [ { kind => 'view', name => 'reports.item_list' } ];
  ($err) = refusal($source, { schemas => { app => {}, old => {} }, types => $source->{types}, tables => {} });
  like $err, qr/refusing to diff: table app\.items .*refusing to diff: table app\.orders /s,
    'several tables that meet dependents are refused in one message, naming each';
  delete $source->{tables}{'app.items'};

  # What stays is no matter.
  ($err, $ops) = refusal($source, { schemas => { app => {}, old => {} }, types => $source->{types}, tables => $source->{tables} });
  is $err, '', 'dependents of objects the target keeps are not asked about';
  is scalar @$ops, 0, '... and no operation';
}

{
  my $source = {
    schemas => { app => {} }, tables => { table(app => 'orders') },
  };
  is_deeply sql(diff($source, { schemas => { app => {} }, tables => {} })), [ 'DROP TABLE app.orders;' ],
    'a model without the section asks nothing: the server has the say';
  $source->{outside_dependents} = { tables => {}, types => {}, schemas => {} };
  is_deeply sql(diff($source, { schemas => { app => {} }, tables => {} })), [ 'DROP TABLE app.orders;' ],
    '... and a section without dependents refuses nothing';
}

# --- 3. what the model holds goes first ----------------------------------------

# keys between tables that are dropped together
{
  my $source = {
    tables => { map { table(app => $_) } qw( a b c keep a_target z_ref ) },
    foreign_keys => {
      'app.a' => [ fk(a_b_fkey => app => 'b'), fk(a_self_fkey => app => 'a'), fk(a_keep_fkey => app => 'keep') ],
      'app.b' => [ fk(b_a_fkey => app => 'a') ],
      'app.c' => [ fk(c_keep_fkey => app => 'keep') ],
      'app.keep' => [ fk(keep_c_fkey => app => 'c') ],
      'app.z_ref' => [ fk(z_ref_fkey => app => 'a_target') ],
    },
  };
  my $target = { tables => { table(app => 'keep') }, foreign_keys => { 'app.keep' => [] } };
  my $d = diff($source, $target);
  is_deeply sql($d), [
      'ALTER TABLE app.keep DROP CONSTRAINT keep_c_fkey;',
      'ALTER TABLE app.a DROP CONSTRAINT a_b_fkey;',
      'ALTER TABLE app.b DROP CONSTRAINT b_a_fkey;',
      'DROP TABLE app.a;', 'DROP TABLE app.b;', 'DROP TABLE app.c;', 'DROP TABLE app.z_ref;', 'DROP TABLE app.a_target;',
    ], 'two tables that reference each other lose their keys first, so that they go in any order; '
     . 'the key of a table that stays is dropped; a key to itself or to a table that stays goes with the table; '
     . 'a table whose key points at a dropped table goes ahead of it, and its key has no statement of its own';
  like $d->summary, qr/-fk: a_b_fkey \(on app\.a -> app\.b\) -- dropped ahead of its table/,
    '... and the summary says why the key is dropped';
  unlike $d->summary, qr/z_ref_fkey/, '... and names no key that goes with its table';
}

# a table that inherits goes ahead of its parent
{
  my $source = {
    tables => { table(app => 'a_parent'), table(app => 'z_child', inherits => ['app.a_parent']), table(app => 'm_other') },
  };
  is_deeply sql(diff($source, { tables => {} })),
    [ 'DROP TABLE app.m_other;', 'DROP TABLE app.z_child;', 'DROP TABLE app.a_parent;' ],
    'a table that inherits from a dropped table is dropped ahead of it, the others by name';
}

# a type goes ahead of the types built on it
{
  my $enum = sub { +{ schema_name => 'app', type_name => $_[0], type_kind => 'enum', values => ['a'] } };
  my $source = { types => {
    'app.a_mood' => $enum->('a_mood'),
    'app.b_box'  => { schema_name => 'app', type_name => 'b_box', type_kind => 'composite',
                      attributes => [ { name => 'm', type => 'app.a_mood[]', ordinal => 1 } ] },
    'app.c_span' => { schema_name => 'app', type_name => 'c_span', type_kind => 'range', subtype => 'a_mood' },
    'app.d_plain' => $enum->('d_plain'),
  } };
  is_deeply sql(diff($source, { types => {} })),
    [ 'DROP TYPE app.b_box;', 'DROP TYPE app.c_span;', 'DROP TYPE app.a_mood;', 'DROP TYPE app.d_plain;' ],
    'a type is dropped ahead of the composite and range types built on it (an array of it too)';
}

# the sequences no column owns go ahead of their schema
{
  my $seq = sub {
    my ($schema, $name, %more) = @_;
    return ("$schema.$name" => { schema_name => $schema, sequence_name => $name, is_identity => 0,
      owned_by_table_name => undef, owned_by_column => undef, %more });
  };
  my $source = {
    schemas   => { public => {}, old => {} },
    tables    => { table(old => 'owner') },
    sequences => {
      $seq->(old => 'loose'),
      $seq->(old => 'owner_id_seq', owned_by_table_name => 'owner', owned_by_column => 'id'),
      $seq->(old => 'owner_pk_seq', owned_by_table_name => 'owner', owned_by_column => 'pk', is_identity => 1),
      $seq->(public => 'stays'),
    },
  };
  my $target = { schemas => { public => {} }, tables => {}, sequences => { $seq->(public => 'stays') } };
  my $d = diff($source, $target);
  is_deeply sql($d), [ 'DROP TABLE old.owner;', 'DROP SEQUENCE old.loose;', 'DROP SCHEMA old;' ],
    'a sequence no column owns is dropped ahead of its schema; the ones a column owns go with the table, '
    . 'and a sequence of a schema that stays is left';
  like $d->summary, qr/^  -sequence: old\.loose$/m, '... and the summary names it';
}

done_testing;
