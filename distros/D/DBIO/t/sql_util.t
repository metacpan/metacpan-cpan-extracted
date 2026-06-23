use strict;
use warnings;

use Test::More;
use DBIO::SQL::Util '_quote_ident', '_split_statements';

# _quote_ident tests
# Pattern: /^[a-z_][a-z0-9_]*$/i - simple identifiers returned as-is
subtest '_quote_ident simple (no quoting needed)' => sub {
  is(_quote_ident('foo'), 'foo', 'simple lowercase');
  is(_quote_ident('bar'), 'bar', 'simple with numbers');
  is(_quote_ident('foo_bar'), 'foo_bar', 'with underscore');
  is(_quote_ident('FOO'), 'FOO', 'uppercase');
  is(_quote_ident('_foo'), '_foo', 'starts with underscore');
  is(_quote_ident('FooBar'), 'FooBar', 'mixed case');
  is(_quote_ident('bar123'), 'bar123', 'alphanumeric');
};

# Identifiers that need quoting
subtest '_quote_ident needs quoting' => sub {
  is(_quote_ident('foo bar'), '"foo bar"', 'space');
  is(_quote_ident('foo"bar'), '"foo""bar"', 'embedded double quote');
  is(_quote_ident('1foo'), '"1foo"', 'starts with digit');
  is(_quote_ident(''), '""', 'empty string');
};

subtest '_quote_ident embedded quotes' => sub {
  is(_quote_ident('foo""bar'), '"foo""""bar"', 'embedded escaped quotes');
  is(_quote_ident('a"b"c'), '"a""b""c"', 'multiple embedded quotes');
};

# _split_statements tests
subtest '_split_statements basic' => sub {
  is_deeply([_split_statements("SELECT 1; SELECT 2;")],
    ["SELECT 1", "SELECT 2"], 'basic semicolon split');
  is_deeply([_split_statements("SELECT 1;")], ["SELECT 1"], 'single statement');
  is_deeply([_split_statements("SELECT 1; SELECT 2")],
    ["SELECT 1", "SELECT 2"], 'no trailing semicolon');
};

subtest '_split_statements dollar quoting' => sub {
  # $$ toggles dollar quoting state - semicolons inside are not split
  my $sql1 = "SELECT \$\$; SELECT 1;";
  my @r1 = _split_statements($sql1);
  is($r1[0], 'SELECT $$', '$$ does not split - first stmt');
  is($r1[1], 'SELECT 1', '$$ does not split - second stmt');

  # Tagged dollar quotes ($a$)
  my $sql2 = "SELECT \$a\$; SELECT 2;";
  my @r2 = _split_statements($sql2);
  is($r2[0], 'SELECT $a$', 'tagged dollar quotes - first stmt');
  is($r2[1], 'SELECT 2', 'tagged dollar quotes - second stmt');

  # Single quotes do NOT protect semicolons (only $$ does)
  my @r3 = _split_statements("SELECT 'foo;bar'; SELECT 1;");
  is($r3[0], "SELECT 'foo", 'single quotes do not protect - first part');
  is($r3[1], "bar'", 'single quotes do not protect - second part');
  is($r3[2], 'SELECT 1', 'single quotes do not protect - third stmt');
};

subtest '_split_statements whitespace and blanks' => sub {
  is_deeply([_split_statements("   SELECT 1;   SELECT 2;   ")],
    ["SELECT 1", "SELECT 2"], 'trim whitespace');
  is_deeply([_split_statements(";SELECT 1;;SELECT 2;;")],
    ["SELECT 1", "SELECT 2"], 'blank statements discarded');
};

subtest '_split_statements empty' => sub {
  is_deeply([_split_statements("")], [], 'empty string');
  is_deeply([_split_statements("   ")], [], 'whitespace only');
  is_deeply([_split_statements(";;;")], [], 'semicolons only');
};

subtest '_split_statements real world' => sub {
  is_deeply([_split_statements("CREATE TABLE foo (id INT); INSERT INTO foo VALUES (1);")],
    ["CREATE TABLE foo (id INT)", "INSERT INTO foo VALUES (1)"], 'DDL + DML');
  # Note: does NOT handle SQL comments - splits on semicolons even in comments
  my @r = _split_statements("SELECT 1 -- comment; not a real semicolon\n; SELECT 2");
  is($r[0], "SELECT 1 -- comment", 'comment semicolon - first stmt');
  is($r[1], "not a real semicolon", 'comment semicolon - second stmt');
  is($r[2], "SELECT 2", 'comment semicolon - third stmt');
};

subtest '_split_statements dollar quotes across lines' => sub {
  my $sql = "CREATE FUNCTION foo() RETURNS TEXT AS \$\$\nSELECT 'hello';\n\$\$ LANGUAGE SQL;";
  my @r = _split_statements($sql);
  is(scalar(@r), 1, 'dollar quote spans lines - single stmt');
  is($r[0], "CREATE FUNCTION foo() RETURNS TEXT AS \$\$\nSELECT 'hello';\n\$\$ LANGUAGE SQL", 'dollar quote spans lines - content');
};

done_testing;