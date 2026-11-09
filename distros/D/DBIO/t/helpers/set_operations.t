use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';

# The SQL set operations (folded in from
# DBIx::Class::Helper::ResultSet::SetOperations). Fake storage only.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $rs = $schema->resultset('Artist');

my $id_name  = $rs->search(undef, { columns => [qw( artistid name )] });
my $swapped  = $rs->search(undef, { columns => [qw( name artistid )] });
my $shorter  = $rs->search(undef, { columns => [qw( artistid )] });
my $renamed  = $rs->search(undef, { columns => [ 'artistid', { moniker => 'me.name' } ] });

# --- A) matching operands still build the query ----------------------

is_same_sql_bind(
  $id_name->union($id_name)->as_query,
  '(SELECT "me"."artistid", "me"."name" FROM ('
    . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me"'
    . ' UNION '
    . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me") "me")',
  [],
  'union of two identically projected ResultSets builds the subselect',
);

for my $case (
  [ union_all     => 'UNION ALL' ],
  [ intersect     => 'INTERSECT' ],
  [ intersect_all => 'INTERSECT ALL' ],
  [ except        => 'EXCEPT' ],
  [ except_all    => 'EXCEPT ALL' ],
) {
  my ($method, $keyword) = @$case;
  is_same_sql_bind(
    $id_name->$method($id_name)->as_query,
    '(SELECT "me"."artistid", "me"."name" FROM ('
      . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me"'
      . " $keyword "
      . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me") "me")',
    [],
    "$method builds a $keyword subselect",
  );
}

is_same_sql_bind(
  $id_name->union([ $id_name, $id_name ])->as_query,
  '(SELECT "me"."artistid", "me"."name" FROM ('
    . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me"'
    . ' UNION '
    . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me"'
    . ' UNION '
    . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me") "me")',
  [],
  'an arrayref of operands is folded into one statement',
);

# --- B) mismatched column specs throw --------------------------------
#
# The column check and its _compare_arrays helper were dropped in the fork
# while the POD kept promising them. A set operation over differently ordered
# selects is valid SQL on most engines, so this used to build silently and
# hand back rows with the values in the wrong fields.

throws_ok { my $q = $id_name->union($swapped); $q->as_query }
  qr/do not all have the same selected columns/,
  'union with the same columns in a different order throws';

throws_ok { my $q = $id_name->union($shorter); $q->as_query }
  qr/do not all have the same selected columns/,
  'union with a different number of columns throws';

throws_ok { my $q = $id_name->union($renamed); $q->as_query }
  qr/do not all have the same selected columns/,
  'union where only the output name differs throws - {as} is what must match';

throws_ok { my $q = $id_name->union([ $id_name, $swapped ]); $q->as_query }
  qr/do not all have the same selected columns/,
  'a single bad operand in an arrayref is enough to throw';

throws_ok { my $q = $id_name->union($swapped); $q->as_query } 'DBIO::Exception',
  'the column mismatch is a typed DBIO exception';

for my $method (qw( union_all intersect intersect_all except except_all )) {
  throws_ok { my $q = $id_name->$method($swapped); $q->as_query }
    qr/do not all have the same selected columns/,
    "$method checks the column spec too";
}

# --- C) the result_class check is unaffected -------------------------

throws_ok { my $q = $id_name->hri->union($id_name); $q->as_query }
  qr/ResultClass of ResultSets do not match/,
  'mismatched result_class still throws first';

# --- D) all six keywords come from the storage hook --------------------
#
# ADR 0039: one seam, _set_operation_keyword($op), asked with the canonical
# operation name -- the ResultSet method's own name. It replaced
# _except_operator (ADR 0037 section 3), which could only answer for except:
# no engine SPELLS the ... ALL family differently, but several do not HAVE
# them, so what they need is a refusal, and refusal belongs where rendering
# already is.
#
# What the hook replaced originally was a driver-name match: except() compared
# sqlt_type to 'Oracle', and sqlt_type is $dbh->{Driver}{Name} reached through
# _get_dbh, so building the query OPENED A CONNECTION purely to choose a
# keyword, on every call.

# D1) the default hook answers ANSI for all six, and that is byte-for-byte
# the SQL the hard-coded keywords produced before the routing change.

my %ansi = (
  union         => 'UNION',
  union_all     => 'UNION ALL',
  intersect     => 'INTERSECT',
  intersect_all => 'INTERSECT ALL',
  except        => 'EXCEPT',
  except_all    => 'EXCEPT ALL',
);

for my $op (sort keys %ansi) {
  is $schema->storage->_set_operation_keyword($op), $ansi{$op},
    "_set_operation_keyword('$op') is the ANSI $ansi{$op}";
}

# Byte-identical, not merely equivalent: is_same_sql_bind above normalises
# whitespace, and the point of this block is that routing the keyword through
# the storage changed no character of the emitted statement.
for my $op (sort keys %ansi) {
  my ($sql) = @{ ${ $id_name->$op($id_name)->as_query } };
  is $sql,
    '(SELECT "me"."artistid", "me"."name" FROM ('
      . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me"'
      . " $ansi{$op} "
      . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me") "me")',
    "$op emits the exact string the hard-coded keyword emitted";
}

# D2) a driver that spells ONE of them differently changes only that one.
# This is the dbio-oracle shape.

{
  package DBIO::Test::Storage::MinusEngine;
  our @ISA = ('DBIO::Test::Storage');
  use mro 'c3';

  our $ENGINE_PROBES = 0;

  sub _set_operation_keyword {
    my ($self, $op) = @_;
    return 'MINUS' if $op eq 'except';
    return $self->next::method($op);
  }

  # Everything the old name match went through, counted. Neither may be
  # touched while a query is being built.
  sub sqlt_type { $ENGINE_PROBES++; 'NULL' }
  sub _get_dbh  { $ENGINE_PROBES++; undef }
}

{
  my $minus_schema = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = DBIO::Test::Storage::MinusEngine->new($minus_schema);
  $minus_schema->storage($storage);

  my $minus_rs = $minus_schema->resultset('Artist')
    ->search(undef, { columns => [qw( artistid name )] });

  $DBIO::Test::Storage::MinusEngine::ENGINE_PROBES = 0;
  my $query = $minus_rs->except($minus_rs)->as_query;

  is_same_sql_bind(
    $query,
    '(SELECT "me"."artistid", "me"."name" FROM ('
      . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me"'
      . ' MINUS '
      . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me") "me")',
    [],
    'except() uses the keyword the storage hook returns',
  );

  is $DBIO::Test::Storage::MinusEngine::ENGINE_PROBES, 0,
    'building the query consulted neither sqlt_type nor _get_dbh -- '
  . '$rs->except($other)->as_query no longer opens a connection';

  # next::method composition: the override named one operation, so the other
  # five must still arrive from the base. Without the delegation an override
  # would have to restate the whole map to change a single word.
  for my $op (grep { $_ ne 'except' } sort keys %ansi) {
    is $storage->_set_operation_keyword($op), $ansi{$op},
      "$op still gets the base keyword through next::method";
    like ${ $minus_rs->$op($minus_rs)->as_query }->[0],
      qr/\Q $ansi{$op} \E/,
      "... and $op still renders it";
  }

  unlike ${ $minus_rs->union($minus_rs)->as_query }->[0], qr/MINUS/,
    'the override changed exactly one operation, not the family';
}

# D3) an engine that does not HAVE an operation refuses, in the same hook.
#
# The refusal is the second job of the seam (ADR 0039): the driver knows the
# engine and the version, so it writes a message core could not. Two things
# are pinned here -- the message reaches the caller unmangled, and it arrives
# BEFORE any operand SQL exists, so a refused operation can never leave behind
# a fragment to embed in a larger query.

{
  package DBIO::Test::Storage::NoExceptAll;
  our @ISA = ('DBIO::Test::Storage');
  use mro 'c3';

  sub _set_operation_keyword {
    my ($self, $op) = @_;
    $self->throw_exception(
      "Frobnitz 4.2 has no $op: MINUS ALL was only added in Frobnitz 21c"
    ) if $op eq 'except_all' or $op eq 'intersect_all';
    return $self->next::method($op);
  }
}

{
  my $refusing_schema = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = DBIO::Test::Storage::NoExceptAll->new($refusing_schema);
  $refusing_schema->storage($storage);

  my $refusing_rs = $refusing_schema->resultset('Artist')
    ->search(undef, { columns => [qw( artistid name )] });

  $storage->reset_captured;

  throws_ok { $refusing_rs->except_all($refusing_rs) }
    qr/\QFrobnitz 4.2 has no except_all: MINUS ALL was only added in Frobnitz 21c\E/,
    'the driver\'s own refusal message reaches the caller unmangled';

  throws_ok { $refusing_rs->except_all($refusing_rs) } 'DBIO::Exception',
    'and it is a typed DBIO exception (F21), not a bare croak';

  throws_ok { $refusing_rs->intersect_all($refusing_rs) }
    qr/has no intersect_all/,
    'a driver can refuse more than one operation from the one hook';

  is scalar($storage->captured_queries), 0,
    'a refused operation issued no SQL at all';

  # The refusal happens before the operands are rendered, so there is never a
  # half-built query object to hand on. throws_ok already proves nothing was
  # returned; this proves the operations the engine DOES have are untouched.
  is_same_sql_bind(
    $refusing_rs->except($refusing_rs)->as_query,
    '(SELECT "me"."artistid", "me"."name" FROM ('
      . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me"'
      . ' EXCEPT '
      . 'SELECT "me"."artistid", "me"."name" FROM "artist" "me") "me")',
    [],
    'refusing except_all leaves except itself working',
  );
}

# D4) an unknown operation is a CORE programming error, not an engine fact.
#
# It must never fall through as a bare token into the SQL, and the message is
# core's, not a driver's: a driver that does not recognise an op delegates to
# next::method and lands exactly here.

throws_ok { $schema->storage->_set_operation_keyword('symmetric_difference') }
  qr/Unknown set operation 'symmetric_difference'/,
  'an unknown operation names itself';

throws_ok { $schema->storage->_set_operation_keyword('symmetric_difference') }
  qr/valid operations are: except, except_all, intersect, intersect_all, union, union_all/,
  '... and lists the six valid ones';

throws_ok { $schema->storage->_set_operation_keyword(undef) }
  qr/Unknown set operation '\(undef\)'/,
  'undef is reported rather than silently rendered as an empty keyword';

throws_ok { $schema->storage->_set_operation_keyword('UNION') }
  qr/Unknown set operation 'UNION'/,
  'the hook takes the canonical op name, not the rendered keyword -- passing '
. 'the keyword back in is the mistake the routing change could have hidden';

throws_ok { $schema->storage->_set_operation_keyword('symmetric_difference') }
  'DBIO::Exception',
  'the programming error is a typed exception too';

done_testing;
