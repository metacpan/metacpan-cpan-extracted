use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test ':DiffSQL';

# The order_by() shortcut helper (folded in from
# DBIx::Class::Helper::ResultSet::Shortcut::OrderBy + ::OrderByMagic).
# Everything here runs against the fake storage - no database involved.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $rs = $schema->resultset('Artist');

my $select = '"me"."artistid", "me"."name", "me"."rank", "me"."charfield"';

sub order_sql {
  my ($order) = @_;
  return "(SELECT $select FROM \"artist\" \"me\" ORDER BY $order)";
}

# --- A) magic strings ------------------------------------------------

is_same_sql_bind(
  $rs->order_by('name')->as_query,
  order_sql('"me"."name" ASC'),
  [],
  'bare column is ASC and gets qualified',
);

is_same_sql_bind(
  $rs->order_by('!name')->as_query,
  order_sql('"me"."name" DESC'),
  [],
  '! prefix means DESC',
);

is_same_sql_bind(
  $rs->order_by('name,!rank')->as_query,
  order_sql('"me"."name" ASC, "me"."rank" DESC'),
  [],
  'comma separated magic string splits into one clause per column',
);

is_same_sql_bind(
  $rs->order_by(qw(name !rank))->as_query,
  order_sql('"me"."name" ASC, "me"."rank" DESC'),
  [],
  'several magic strings keep their argument order',
);

is_same_sql_bind(
  $rs->order_by('cds.year')->as_query,
  order_sql('"cds"."year" ASC'),
  [],
  'an already qualified column is not qualified again',
);

# A column that really is named 'desc' must stay a column - the direction
# tokens are only recognised with a leading dash.
is_same_sql_bind(
  $rs->order_by('desc')->as_query,
  order_sql('"me"."desc" ASC'),
  [],
  q{a column named 'desc' is a column, not a direction},
);

is_same_sql_bind(
  $rs->order_by(qw(desc asc))->as_query,
  order_sql('"me"."desc" ASC, "me"."asc" ASC'),
  [],
  q{columns named 'desc'/'asc' do not swallow their neighbours},
);

# --- B) flat direction pairs -----------------------------------------

is_same_sql_bind(
  $rs->order_by(-desc => 'name')->as_query,
  order_sql('"me"."name" DESC'),
  [],
  '-desc => $col orders descending (was silently two ASC columns)',
);

is_same_sql_bind(
  $rs->order_by(-asc => 'name')->as_query,
  order_sql('"me"."name" ASC'),
  [],
  '-asc => $col orders ascending',
);

is_same_sql_bind(
  $rs->order_by(-DESC => 'name')->as_query,
  order_sql('"me"."name" DESC'),
  [],
  'the direction token is case insensitive',
);

is_same_sql_bind(
  $rs->order_by(-desc => 'name,rank')->as_query,
  order_sql('"me"."name" DESC, "me"."rank" DESC'),
  [],
  'comma separated pair value applies the direction to every column',
);

# Deliberate asymmetry: an arrayref as a *pair value* is our own sugar and
# gets qualified, while an arrayref as an *argument* is native SQL::Abstract
# and stays untouched (see the arrayref tests further down).
is_same_sql_bind(
  $rs->order_by(-desc => [qw(name rank)])->as_query,
  order_sql('"me"."name" DESC, "me"."rank" DESC'),
  [],
  'arrayref pair value gives one clause per element, qualified',
);

is_same_sql_bind(
  $rs->order_by(-desc => 'cds.year')->as_query,
  order_sql('"cds"."year" DESC'),
  [],
  'pair value that is already qualified is left alone',
);

is_same_sql_bind(
  $rs->order_by(-asc => 'name', -desc => 'rank')->as_query,
  order_sql('"me"."name" ASC, "me"."rank" DESC'),
  [],
  'several pairs keep their argument order',
);

is_same_sql_bind(
  $rs->order_by(-desc => \'name')->as_query,
  order_sql('name DESC'),
  [],
  'a ref as pair value is handed to the direction untouched',
);

throws_ok {
  $rs->order_by('name', '-desc')->as_query
} qr/Missing value after '-desc'/,
  'a dangling direction throws instead of producing bogus SQL';

throws_ok {
  $rs->order_by('-asc')->as_query
} qr/Missing value after '-asc'/,
  'a lone direction throws as well';

throws_ok {
  $rs->order_by(-desc => undef)->as_query
} qr/Missing value after '-desc'/,
  'an undefined pair value throws instead of silently vanishing';

# --- C) refs at any position -----------------------------------------

# A ref means "the caller speaks native SQL::Abstract", so order_by() keeps
# its hands off it. These four characterise that a lone ref reaches the query
# exactly as if it had been passed as the order_by attribute directly.
is_same_sql_bind(
  $rs->order_by({ -desc => 'name' })->as_query,
  $rs->search(undef, { order_by => { -desc => 'name' } })->as_query,
  'single hashref is passed straight through as the order_by attribute',
);

# Characterisation only - both paths are equivalent since every top level ref
# goes through untouched, so this no longer pins the single-ref short circuit.
is_same_sql_bind(
  $rs->order_by([qw(name rank)])->as_query,
  $rs->search(undef, { order_by => [qw(name rank)] })->as_query,
  'single arrayref is passed straight through as the order_by attribute',
);

is_same_sql_bind(
  $rs->order_by(\'name DESC')->as_query,
  $rs->search(undef, { order_by => \'name DESC' })->as_query,
  'single literal is passed straight through as the order_by attribute',
);

is_same_sql_bind(
  $rs->order_by(\['position(? in name)', 'x'])->as_query,
  $rs->search(undef, { order_by => \['position(? in name)', 'x'] })->as_query,
  'single literal with bind is passed straight through',
);

# Refs beyond position 0 used to be swallowed silently.
is_same_sql_bind(
  $rs->order_by({ -desc => 'name' }, 'rank')->as_query,
  order_sql('"name" DESC, "me"."rank" ASC'),
  [],
  'a trailing argument after a hashref is no longer dropped',
);

is_same_sql_bind(
  $rs->order_by('name', { -desc => 'rank' })->as_query,
  order_sql('"me"."name" ASC, "rank" DESC'),
  [],
  'a hashref after a string is taken over instead of string parsed',
);

is_same_sql_bind(
  $rs->order_by(\'name DESC', 'rank')->as_query,
  order_sql('name DESC, "me"."rank" ASC'),
  [],
  'a literal in a list is passed through untouched',
);

is_same_sql_bind(
  $rs->order_by(\['position(? in name)', 'x'], 'rank')->as_query,
  order_sql('position(? in name), "me"."rank" ASC'),
  [ [ {} => 'x' ] ],
  'a literal with bind in a list is passed through untouched',
);

is_same_sql_bind(
  $rs->order_by(['name', { -desc => 'rank' }], 'charfield')->as_query,
  order_sql('"name", "rank" DESC, "me"."charfield" ASC'),
  [],
  'an arrayref is flattened so following arguments append, contents verbatim',
);

# The seam: the arrayref part must come out identically whether or not
# something follows it. Flattening is a plumbing detail, not a parsing switch.
{
  my $alone   = $rs->order_by([qw(name rank)])->as_query;
  my $trailed = $rs->order_by([qw(name rank)], 'charfield')->as_query;

  is_same_sql_bind(
    $alone,
    order_sql('"name", "rank"'),
    [],
    'arrayref alone stays unqualified native SQL::Abstract',
  );

  is_same_sql_bind(
    $trailed,
    order_sql('"name", "rank", "me"."charfield" ASC'),
    [],
    'arrayref plus trailing argument: arrayref part unqualified, argument parsed',
  );
}

# Nothing inside a ref is parsed: no magic string ...
is_same_sql_bind(
  $rs->order_by(['!name'], 'rank')->as_query,
  order_sql('"!name", "me"."rank" ASC'),
  [],
  'a ! prefix inside an arrayref stays part of the column name',
);

# ... and no direction detection either. Same as what SQL::Abstract makes of
# that arrayref on its own - which is the whole point of passing it through.
is_same_sql_bind(
  $rs->order_by([-desc => 'name'])->as_query,
  $rs->search(undef, { order_by => [-desc => 'name'] })->as_query,
  'a direction token inside an arrayref is not a direction, just a list element',
);

# The escape hatch documented in the qualification rule: a hashref is never
# qualified, so ordering by an output alias from +select/-as keeps working.
is_same_sql_bind(
  $rs->search(undef, {
    '+select' => \'LENGTH(me.name)',
    '+as'     => 'name_length',
  })->order_by({ -desc => 'name_length' })->as_query,
  "(SELECT $select, LENGTH(me.name) FROM \"artist\" \"me\""
    . ' ORDER BY "name_length" DESC)',
  [],
  'hashref stays unqualified - ordering by an output alias is possible',
);

# --- mixed lists keep the argument order ------------------------------

is_same_sql_bind(
  $rs->order_by('name', -desc => 'rank', { -asc => 'charfield' })->as_query,
  order_sql('"me"."name" ASC, "me"."rank" DESC, "charfield" ASC'),
  [],
  'magic string, flat pair and hashref keep their argument order',
);

is_same_sql_bind(
  $rs->order_by({ -asc => 'charfield' }, -desc => 'rank', 'name')->as_query,
  order_sql('"charfield" ASC, "me"."rank" DESC, "me"."name" ASC'),
  [],
  'the same elements in reverse order produce the reverse clause order',
);

# --- degenerate input -------------------------------------------------

is_same_sql_bind(
  $rs->order_by->as_query,
  "(SELECT $select FROM \"artist\" \"me\")",
  [],
  'no arguments produces no ORDER BY',
);

done_testing;
