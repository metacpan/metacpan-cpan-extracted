use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff::Column;
use DBIO::PostgreSQL::Diff::Type;

# karr k121 (11) -- an operation built by hand with a gap in what it says.
#
# WHY it exists: as_sql wrote SQL the server cannot read where the operation
# lacked a part the statement needs:
#
#   ALTER TABLE public.t ADD COLUMN c;                  (no data_type)
#   CREATE TYPE public.r AS RANGE (SUBTYPE = );         (no subtype)
#
# The family line is one rule (DBIO::PostgreSQL::Diff::NoStatement): an
# operation that has no statement dies in as_sql and returns nothing, never
# SQL that only the server would refuse. A complete operation is not touched
# by it; the first two subtests below hold that.

my %ON = (schema_name => 'public', table_name => 't');

sub no_statement_ok {
  my ($label, $op, @like) = @_;
  my @sql = eval { $op->as_sql };
  my $error = $@;
  subtest $label => sub {
    is_deeply \@sql, [], 'as_sql returns nothing'
      or diag "it returned: [@{[ map { $_ // 'undef' } @sql ]}]";
    like $error, qr/no statement for/, 'it dies by the NoStatement rule';
    like $error, qr/\Q@{[ ref $op ]}\E/, 'naming the class of the operation';
    like $error, $_, "the message matches $_" for @like;
  };
}

# --- what stays as it was ---------------------------------------------------

is(
  DBIO::PostgreSQL::Diff::Column->new(action => 'add', table_key => 'public.t', %ON,
    column_name => 'c', new_info => { data_type => 'text' })->as_sql,
  'ALTER TABLE public.t ADD COLUMN c text;',
  'a column with its type is written',
);

is(
  DBIO::PostgreSQL::Diff::Type->new(action => 'create', type_key => 'public.r',
    type_info => { schema_name => 'public', type_name => 'r', type_kind => 'range', subtype => 'integer' })->as_sql,
  'CREATE TYPE public.r AS RANGE (SUBTYPE = integer);',
  'a range type with its subtype is written',
);

# --- the gaps ---------------------------------------------------------------

for my $missing (undef, '', ' ') {
  my $shown = defined $missing ? "'$missing'" : 'undef';
  no_statement_ok "an add of a column whose data_type is $shown",
    DBIO::PostgreSQL::Diff::Column->new(action => 'add', table_key => 'public.t', %ON,
      column_name => 'c', new_info => { data_type => $missing }),
    qr/column public\.t\.c/, qr/data_type/;

  no_statement_ok "a create of a range type whose subtype is $shown",
    DBIO::PostgreSQL::Diff::Type->new(action => 'create', type_key => 'public.r',
      type_info => { schema_name => 'public', type_name => 'r', type_kind => 'range', subtype => $missing }),
    qr/type public\.r/, qr/subtype/;
}

no_statement_ok 'an add of a column whose new_info has no data_type key at all',
  DBIO::PostgreSQL::Diff::Column->new(action => 'add', table_key => 'public.t', %ON,
    column_name => 'c', new_info => { not_null => 1 }),
  qr/data_type/;

# An enum column names its type by pg_enum_type; data_type 'enum' is there.
is(
  DBIO::PostgreSQL::Diff::Column->new(action => 'add', table_key => 'public.t', %ON,
    column_name => 'c', new_info => { data_type => 'enum', pg_enum_type => 'public.e' })->as_sql,
  'ALTER TABLE public.t ADD COLUMN c public.e;',
  'an enum column is still written',
);

done_testing;
