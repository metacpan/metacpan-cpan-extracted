use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Age::Storage;

# Offline coverage for the AGE cypher() SQL generation. _cypher_sql_bind is the
# pure (no-DB) half of cypher(); this pins the generated SQL and binds without
# needing a live PostgreSQL+AGE database.
#
# DBIO::PostgreSQL::Age::Storage is a plain storage LAYER now (core karr #70): it
# has no constructor. Compose it over the real PG driver storage to get an
# instance on which _cypher_sql_bind / throw_exception resolve through the
# composed MRO -- exactly the shape a live Age connection reblesses to.
my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $composed = DBIO::Storage::Composed->compose(
  'DBIO::PostgreSQL::Storage', ['DBIO::PostgreSQL::Age::Storage'],
);
my $s = $composed->new($schema);

# --- basic: no params ---
{
  my ($sql, $bind) = $s->_cypher_sql_bind('social', 'MATCH (n) RETURN n', ['node']);
  like   $sql, qr/FROM cypher\('social',/,   'graph name is inlined as a string literal';
  like   $sql, qr/\$dbio_age\$\nMATCH \(n\) RETURN n\n\$dbio_age\$/, 'query is wrapped in a tagged dollar-quote';
  like   $sql, qr/AS \(node agtype\)\z/,      'single result column declared as agtype';
  unlike $sql, qr/\?/,                        'no bind placeholder without params';
  is_deeply $bind, [],                        'no binds without params';
}

# --- multiple columns ---
{
  my ($sql) = $s->_cypher_sql_bind('g', 'RETURN a, b', [qw(person friend)]);
  like $sql, qr/AS \(person agtype, friend agtype\)\z/,
    'each result column declared as agtype';
}

# --- with params ---
{
  my ($sql, $bind) = $s->_cypher_sql_bind(
    'g', 'MATCH (n {name: $name}) RETURN n', ['n'], { name => 'Alice' },
  );
  like $sql, qr/\$dbio_age\$, \?\) AS \(/, 'param slot appended as AGE third argument';
  is   scalar(@$bind), 1,          'one bind value for params';
  like $bind->[0], qr/"name":"Alice"/, 'params are JSON-encoded into the bind';
}

# --- empty params hashref behaves like no params ---
{
  my ($sql, $bind) = $s->_cypher_sql_bind('g', 'RETURN 1', ['x'], {});
  unlike $sql, qr/\?/, 'empty params hashref adds no placeholder';
  is_deeply $bind, [], 'empty params hashref adds no bind';
}

# --- graph name validation ---
{
  throws_ok { $s->_cypher_sql_bind('bad name', 'RETURN 1', ['x']) }
    qr/Invalid AGE graph name/, 'graph name with a space is rejected';
  throws_ok { $s->_cypher_sql_bind('1graph', 'RETURN 1', ['x']) }
    qr/Invalid AGE graph name/, 'graph name starting with a digit is rejected';
  throws_ok { $s->_cypher_sql_bind(q{g'); DROP TABLE x; --}, 'RETURN 1', ['x']) }
    qr/Invalid AGE graph name/, 'injection-shaped graph name is rejected';

  lives_ok { $s->_cypher_sql_bind('_My_graph2', 'RETURN 1', ['x']) }
    'valid identifier (leading underscore, digits) is accepted';
}

# --- dollar-quote tag must not occur in the Cypher text (karr k14) ---
{
  # A bare $$ in a Cypher string literal used to end the dollar-quoting early
  # and hand the rest of the Cypher text to PostgreSQL as SQL.
  my $evil = q{RETURN "a$$b"};
  my ($sql) = $s->_cypher_sql_bind('g', $evil, ['x']);
  my ($tag) = $sql =~ /\Aselect \* from cypher\('g', (\$[A-Za-z_0-9]*\$)\n/i;
  ok defined $tag, 'dollar-quote opening tag found' or diag $sql;
  isnt $tag, '$$', 'tag is not the bare $$ when the query contains $$';
  is index($evil, $tag), -1, 'chosen tag does not occur in the Cypher text';
  like $sql, qr/\Q$tag\E\n\Q$evil\E\n\Q$tag\E\) AS \(x agtype\)\z/,
    'query is enclosed by the same tag on both sides, verbatim';

  # Tag collision: the preferred tag itself appears in the text.
  my $evil2 = q{RETURN "$dbio_age$ x $dbio_age1$ y $$"};
  my ($sql2) = $s->_cypher_sql_bind('g', $evil2, ['x']);
  my ($tag2) = $sql2 =~ /cypher\('g', (\$[A-Za-z_0-9]*\$)\n/;
  is index($evil2, $tag2), -1, 'tag colliding with the text is counted up past every collision';
  like $sql2, qr/\Q$tag2\E\n\Q$evil2\E\n\Q$tag2\E\)/, 'colliding query is enclosed verbatim';
}

# --- result column names are validated like the graph name (karr k14) ---
{
  throws_ok { $s->_cypher_sql_bind('g', 'RETURN 1', ['x agtype); DROP TABLE t; --']) }
    qr/Invalid AGE column name/, 'injection-shaped column name is rejected';
  throws_ok { $s->_cypher_sql_bind('g', 'RETURN 1', ['bad name']) }
    qr/Invalid AGE column name/, 'column name with a space is rejected';
  throws_ok { $s->_cypher_sql_bind('g', 'RETURN 1', ['1col']) }
    qr/Invalid AGE column name/, 'column name starting with a digit is rejected';
  throws_ok { $s->_cypher_sql_bind('g', 'RETURN 1', ['ok', undef]) }
    qr/Invalid AGE column name/, 'undef column name is rejected';
  lives_ok { $s->_cypher_sql_bind('g', 'RETURN 1', [qw(a _b c2)]) }
    'valid identifiers are accepted';
}

# --- auto_decode option is post-fetch; it must not affect SQL generation ---
{
  # With params, so we exercise the bind too.
  my ($sql_base, $bind_base) = $s->_cypher_sql_bind(
    'g', 'MATCH (n {name: $name}) RETURN n', ['n'], { name => 'Alice' },
  );
  my ($sql_opt, $bind_opt) = $s->_cypher_sql_bind(
    'g', 'MATCH (n {name: $name}) RETURN n', ['n'], { name => 'Alice' },
    { auto_decode => 1 },
  );
  is $sql_opt, $sql_base,
    'auto_decode option does not change the generated SQL';
  is_deeply $bind_opt, $bind_base,
    'auto_decode option does not change the generated bind values';

  # Without params.
  my ($sql2) = $s->_cypher_sql_bind('g', 'RETURN n', ['n']);
  my ($sql3) = $s->_cypher_sql_bind('g', 'RETURN n', ['n'], undef, { auto_decode => 1 });
  is $sql3, $sql2,
    'auto_decode option does not change SQL when there are no params';
}

done_testing;
