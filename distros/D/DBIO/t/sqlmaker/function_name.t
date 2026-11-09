use strict;
use warnings;
use Test::More;

use DBIO::Test ':DiffSQL';

# A function name in select / +select / func / func_rs is an identifier
# (optionally schema-qualified); anything else is written as a literal.

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $sm     = $schema->storage->sql_maker;
sub rf { my ($s) = $sm->_recurse_fields(@_); $s }

my @bad = (
  'count(1) FROM artist UNION SELECT 1 --',
  'max (',
  'max)',
  'max;',
  'ma-x',
  "max\nx",
  "max\n",
  'pg_catalog.',
  '.max',
  '1max',
  '',
);

for my $name (@bad) {
  (my $label = $name) =~ s/\n/\\n/g;

  eval { $sm->_recurse_fields({ $name => 'me.id' }) };
  like $@, qr/not a plain identifier/, "_recurse_fields refuses '$label'";

  my $col = $schema->resultset('Artist')->get_column('name');

  eval { $col->func($name) };
  like $@, qr/func.*not a plain identifier/s, "func refuses '$label'";

  eval { $col->func_rs($name) };
  like $@, qr/func_rs.*not a plain identifier/s, "func_rs refuses '$label'";
}

eval { $schema->resultset('Artist')->search({}, { select => [ { 'max)' => 'name' } ], as => ['x'] })->as_query };
like $@, qr/not a plain identifier/, 'select attribute refuses a malformed function name';

like $@, qr/literal/, 'message points to the literal forms';

is_same_sql(
  rf({ max => 'me.id' }),
  'MAX( "me"."id" )',
  'plain function name',
);

is_same_sql(
  rf({ 'pg_catalog.max' => 'me.id' }),
  'PG_CATALOG.MAX( "me"."id" )',
  'schema-qualified function name',
);

is_same_sql(
  rf({ count => 'me.id', -as => 'n' }),
  'COUNT( "me"."id" ) AS "n"',
  '-as alias is accepted and quoted',
);

my $sql = $schema->resultset('Artist')->get_column('name')->func_rs('pg_catalog.max')->as_query;
like $$sql->[0], qr/PG_CATALOG\.MAX\(/, 'func_rs builds the query with a qualified name';

{
  my $rs = $schema->resultset('Artist')->search({}, {
    select => [ { count => 'me.artistid', -as => 'n' } ], as => ['n'],
  });
  like ${$rs->as_query}->[0], qr/COUNT\( .me.\..artistid. \) AS .n./, 'select attribute with -as';
}

# an -as alias is an identifier: a quote character inside it is doubled
is_same_sql(
  rf({ count => 'me.id', -as => 'n" FROM x --' }),
  'COUNT( "me"."id" ) AS "n"" FROM x --"',
  '-as alias doubles a quote character',
);

done_testing;
