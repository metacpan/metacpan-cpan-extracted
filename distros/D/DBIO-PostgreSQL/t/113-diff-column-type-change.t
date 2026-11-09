use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Column;

# karr k121, point U3: the type of a column changes between two enum or
# composite types.
#
# WHY it exists: the model the diff reads (the catalog row, as
# Introspect::Columns gives it) names a column's type in data_type
# ('role_old') and tells its kind in type_category ('e' enum, 'c'
# composite). The diff wrote USING only for a target whose data_type is the
# literal 'enum' -- a shape no introspected model has -- so ALTER COLUMN ...
# TYPE between two enums or two composites went to the server without it and
# died with 'column "v" cannot be cast automatically to type ...'. These
# tests build the operations from the introspected shape and read what the
# statements say; t/113-diff-column-type-change-live.t runs them on a server.

my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

sub col {
  my (%c) = @_;
  my %kind = (
    e => 'enum_type', c => 'composite_type',
  );
  my $category = $c{category} // 'b';
  return {
    column_name   => 'v',
    data_type     => $c{type},
    not_null      => $c{not_null} // 0,
    default_value => $c{default},
    type_category => $category,
    type_schema   => 'public',
    ( $kind{$category} ? ($kind{$category} => $c{type}) : () ),
  };
}

sub types {
  return +{ map { ("public.$_->[0]" => {
    schema_name => 'public', type_name => $_->[0], type_kind => 'composite',
    attributes => [ map { +{ name => $_->[0], type => $_->[1], ordinal => $_->[2] } } @{ $_->[1] } ],
  }) } @_ };
}

sub ops {
  my ($from, $to, @types) = @_;
  return DBIO::PostgreSQL::Diff::Column->diff(
    { 'public.t' => [ $from ] }, { 'public.t' => [ $to ] }, $tables, $tables, @types,
  );
}

sub sql { join "\n", map { $_->as_sql } @_ }

# enum -> another enum
{
  my @ops = ops(col(type => 'e_old', category => 'e'), col(type => 'e_new', category => 'e'));
  is(scalar @ops, 1, 'enum to enum: one operation');
  is(sql(@ops), 'ALTER TABLE public.t ALTER COLUMN v TYPE e_new USING v::text::e_new;',
    'enum to enum: the value goes through text');
}

# enum -> another enum, with a default of the old type
{
  my @ops = ops(
    col(type => 'e_old', category => 'e', default => "'a'::e_old"),
    col(type => 'e_new', category => 'e', default => "'a'::e_new"),
  );
  is(sql(@ops), join("\n",
    'ALTER TABLE public.t ALTER COLUMN v DROP DEFAULT;',
    'ALTER TABLE public.t ALTER COLUMN v TYPE e_new USING v::text::e_new;',
    "ALTER TABLE public.t ALTER COLUMN v SET DEFAULT 'a'::e_new;",
  ), 'enum to enum with a default: it goes before the type and comes back behind it');
}

# enum -> another enum, the default the same text in both (an integer-like
# literal would be): it is dropped for the type, so it is set again
{
  my @ops = ops(
    col(type => 'e_old', category => 'e', default => "'a'"),
    col(type => 'e_new', category => 'e', default => "'a'"),
  );
  my $sql = sql(@ops);
  like($sql, qr/DROP DEFAULT;\nALTER TABLE public\.t ALTER COLUMN v TYPE e_new USING .*\nALTER TABLE public\.t ALTER COLUMN v SET DEFAULT 'a';\z/,
    'a default of the same text is set again behind the type');
}

# enum -> text and back
{
  is(sql(ops(col(type => 'e_old', category => 'e'), col(type => 'text'))),
    'ALTER TABLE public.t ALTER COLUMN v TYPE text;',
    'enum to text: the server converts on its own, no USING');
  is(sql(ops(col(type => 'text'), col(type => 'e_new', category => 'e'))),
    'ALTER TABLE public.t ALTER COLUMN v TYPE e_new USING v::text::e_new;',
    'text to enum: USING through text');
}

# the normalized shape (data_type enum + pg_enum_type) keeps working
{
  my @ops = ops(
    { column_name => 'v', data_type => 'enum', pg_enum_type => 'a.x', not_null => 0 },
    { column_name => 'v', data_type => 'enum', pg_enum_type => 'a.y', not_null => 0 },
  );
  is(sql(@ops), 'ALTER TABLE public.t ALTER COLUMN v TYPE a.y USING v::text::a.y;',
    'the normalized enum shape is written as before');
}

# composite -> composite of the same attributes
{
  my $attrs = [ [ x => 'integer', 1 ], [ y => 'text', 2 ] ];
  my @t = (types([ c_old => $attrs ], [ c_new => $attrs ]));
  my @ops = ops(col(type => 'c_old', category => 'c'), col(type => 'c_new', category => 'c'), $t[0], $t[0]);
  is(sql(@ops), 'ALTER TABLE public.t ALTER COLUMN v TYPE c_new USING v::text::c_new;',
    'composite to composite of the same attributes: USING through text');
}

# composite -> composite of other attributes: refused
{
  my @t = (types(
    [ c_old   => [ [ x => 'integer', 1 ], [ y => 'text', 2 ] ] ],
    [ c_other => [ [ y => 'text', 1 ], [ x => 'integer', 2 ] ] ],
    [ c_few   => [ [ x => 'integer', 1 ] ] ],
  ));
  for my $to (qw( c_other c_few )) {
    my @ops = eval { ops(col(type => 'c_old', category => 'c'), col(type => $to, category => 'c'), $t[0], $t[0]) };
    my $error = $@;
    ok(!@ops, "composite to $to: no operations");
    like($error, qr/\Arefusing to diff: column public\.t\.v changes from composite type c_old to $to,/,
      "composite to $to: refused, naming both");
    like($error, qr/No statement was generated\./, "composite to $to: and says no statement was written");
  }
}

# composite -> text / text -> composite
{
  is(sql(ops(col(type => 'c_old', category => 'c'), col(type => 'text'))),
    'ALTER TABLE public.t ALTER COLUMN v TYPE text;',
    'composite to text: no USING');
  is(sql(ops(col(type => 'text'), col(type => 'c_new', category => 'c'))),
    'ALTER TABLE public.t ALTER COLUMN v TYPE c_new USING v::text::c_new;',
    'text to composite: USING through text');
}

# the types of a model that has none are not asked: the statement is written
{
  is(sql(ops(col(type => 'c_old', category => 'c'), col(type => 'c_new', category => 'c'))),
    'ALTER TABLE public.t ALTER COLUMN v TYPE c_new USING v::text::c_new;',
    'composite to composite, the model giving no types: written, the server is the judge');
}

# a plain type change stays as it was
{
  is(sql(ops(col(type => 'varchar(50)'), col(type => 'text'))),
    'ALTER TABLE public.t ALTER COLUMN v TYPE text;', 'a plain type change has no USING');
  is(sql(ops(col(type => 'integer', default => '1'), col(type => 'bigint', default => '1'))),
    'ALTER TABLE public.t ALTER COLUMN v TYPE bigint;', 'and keeps its default');
}

done_testing;
