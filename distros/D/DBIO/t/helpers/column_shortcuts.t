use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';

# The column/row projection shortcuts (folded in from
# DBIx::Class::Helper::ResultSet::Shortcut::{Columns,AddColumns,RemoveColumns,
# Rows,Limit,LimitedPage} plus ::RemoveColumns). Fake storage only.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $rs = $schema->resultset('Artist');

my $all = '"me"."artistid", "me"."name", "me"."rank", "me"."charfield"';

sub artist_sql {
  my ($select, $tail) = @_;
  return "(SELECT $select FROM \"artist\" \"me\"" . ($tail ? " $tail" : '') . ')';
}

# --- A) remove_columns actually removes ------------------------------
#
# The shortcut only ever set the attribute; the _resolved_attrs overlay that
# reads it was lost in the fork, so remove_columns was a silent no-op and
# ->remove_columns(['password']) still selected password.

is_same_sql_bind(
  $rs->remove_columns(['charfield', 'rank'])->as_query,
  artist_sql('"me"."artistid", "me"."name"'),
  [],
  'remove_columns shrinks the select list',
);

is_same_sql_bind(
  $rs->remove_columns(['artistid'])->as_query,
  artist_sql('"me"."name", "me"."rank", "me"."charfield"'),
  [],
  'remove_columns can drop the primary key too',
);

is_same_sql_bind(
  $rs->remove_columns([])->as_query,
  artist_sql($all),
  [],
  'an empty remove_columns list removes nothing',
);

is_same_sql_bind(
  $rs->remove_columns(['no_such_column'])->as_query,
  artist_sql($all),
  [],
  'removing a column that is not selected is a no-op, not an error',
);

# The shortcut is sugar for the attribute - both must go through the same
# overlay, so that search(undef, { remove_columns => ... }) works as documented.
is_same_sql_bind(
  $rs->search(undef, { remove_columns => ['rank'] })->as_query,
  $rs->remove_columns(['rank'])->as_query,
  'the remove_columns attribute and the shortcut resolve identically',
);

is_deeply(
  [ @{ $rs->remove_columns(['charfield', 'rank'])->_resolved_attrs->{as} } ],
  [qw( artistid name )],
  'the {as} list shrinks with the select list, so inflation matches',
);

# --- B) the lazy rule: an explicit projection always wins -------------
#
# Resolution is deliberately deferred to _resolved_attrs instead of being done
# eagerly in the shortcut. That is what lets a columns/select from anywhere in
# the chain override an earlier remove_columns.

is_same_sql_bind(
  $rs->remove_columns(['charfield', 'rank'])->columns(['name'])->as_query,
  artist_sql('"me"."name"'),
  [],
  'a later columns() wins over an earlier remove_columns',
);

is_same_sql_bind(
  $rs->columns(['name', 'rank'])->remove_columns(['rank'])->as_query,
  artist_sql('"me"."name", "me"."rank"'),
  [],
  'an earlier columns() also wins - remove_columns never fights a projection',
);

is_same_sql_bind(
  $rs->remove_columns(['rank'])->search(undef, { select => ['me.name'], as => ['name'] })->as_query,
  artist_sql('"me"."name"'),
  [],
  'an explicit select wins over remove_columns as well',
);

# +columns is not a projection, so it merges on top of the reduced list.
is_same_sql_bind(
  $rs->remove_columns(['charfield', 'rank'])->add_columns(['rank'])->as_query,
  artist_sql('"me"."artistid", "me"."name", "me"."rank"'),
  [],
  'add_columns merges onto the remove_columns result instead of cancelling it',
);

# --- C) columns() is a chainer, not a getter -------------------------
#
# The no-arg branch reported the *source* columns rather than the ResultSet's
# projection, and returned a list, so it was garbage in scalar context. It is
# gone; columns() is the upstream one-liner.

is_same_sql_bind(
  $rs->columns(['name'])->as_query,
  artist_sql('"me"."name"'),
  [],
  'columns() sets the projection',
);

{
  my $chained = $rs->columns(['name']);
  isa_ok($chained, 'DBIO::ResultSet', 'columns() with an argument returns a ResultSet');

  my $no_arg = $rs->columns;
  isa_ok($no_arg, 'DBIO::ResultSet',
    'columns() without an argument is still a chainer, not a column-name getter');
}

is_same_sql_bind(
  $rs->add_columns([{ upper_name => \'UPPER(me.name)' }])->as_query,
  artist_sql($all . ', UPPER(me.name)'),
  [],
  'add_columns appends to the default selection',
);

# --- D) rows() is a chainer, not a getter ----------------------------
#
# rows() used to try to fall back to a saved "original" rows() that never
# existed, so the no-arg call always returned undef. Now it is the upstream
# one-liner and every call chains.

{
  my $limited = $rs->rows(20);
  is($limited->{attrs}{rows}, 20, 'rows(20) records the rows attribute');
  isa_ok($limited, 'DBIO::ResultSet', 'rows() returns a ResultSet');

  my $no_arg = $rs->rows;
  isa_ok($no_arg, 'DBIO::ResultSet',
    'rows() without an argument is a chainer too, never a getter returning undef');
}

is_same_sql_bind(
  $rs->rows(20)->as_query,
  artist_sql($all, 'LIMIT ?'),
  [ [ { sqlt_datatype => 'integer' } => 20 ] ],
  'rows() produces the expected LIMIT',
);

is_same_sql_bind(
  $rs->limit(5)->as_query,
  $rs->rows(5)->as_query,
  'limit() is an alias for rows()',
);

is_same_sql_bind(
  $rs->limited_page(2, 10)->as_query,
  artist_sql($all, 'LIMIT ? OFFSET ?'),
  [
    [ { sqlt_datatype => 'integer' } => 10 ],
    [ { sqlt_datatype => 'integer' } => 10 ],
  ],
  'limited_page(page, rows) still combines page() and rows()',
);

is_same_sql_bind(
  $rs->limited_page({ page => 2, rows => 10 })->as_query,
  $rs->limited_page(2, 10)->as_query,
  'the hashref form of limited_page is equivalent',
);

is($rs->has_rows ? 1 : 0, 0, 'has_rows still runs through rows(1)->next');

done_testing;
