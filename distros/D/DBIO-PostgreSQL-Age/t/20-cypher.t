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
  like   $sql, qr/\$\$\nMATCH \(n\) RETURN n\n\$\$/, 'query is wrapped in dollar-quotes';
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
  like $sql, qr/\$\$, \?\) AS \(/, 'param slot appended as AGE third argument';
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
