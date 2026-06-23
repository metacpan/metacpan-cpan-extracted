use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Age::Storage;

# Offline coverage for the AGE cypher() SQL generation. _cypher_sql_bind is the
# pure (no-DB) half of cypher(); this pins the generated SQL and binds without
# needing a live PostgreSQL+AGE database.

my $s = DBIO::PostgreSQL::Age::Storage->new;

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

done_testing;
