use strict;
use warnings;
use Test::More;

use DBIO::SQL::Util ();

# _split_statements is a pure function (no dbh). It splits a DDL blob into
# individual statements on semicolons outside $$ dollar-quoting, trimming
# whitespace and dropping empty fragments. DBIO::Oracle::Deploy inherits
# it from DBIO::Deploy::Base; the function lives in DBIO::SQL::Util.
#
# Note: the trailing `;` is the statement separator and is consumed -- the
# emitted fragments are statements without their terminator (standard SQL:
# $dbh->do() does not need a `;`). The Oracle storage layer relied on this
# shared implementation.

sub split_ddl { DBIO::SQL::Util::_split_statements($_[0]) }

{
  my @s = split_ddl("CREATE TABLE a (id NUMBER);\nCREATE TABLE b (id NUMBER);\n");
  is_deeply(\@s,
    ['CREATE TABLE a (id NUMBER)', 'CREATE TABLE b (id NUMBER)'],
    'two single-line statements');
}

{
  my $ddl = "CREATE TABLE a (\n  id NUMBER,\n  name VARCHAR2(50)\n);\nCREATE SEQUENCE a_seq;";
  my @s = split_ddl($ddl);
  is(scalar @s, 2, 'multi-line statement kept whole');
  like($s[0], qr/^CREATE TABLE a \(/, 'first stmt starts correctly');
  like($s[0], qr/VARCHAR2\(50\)\n\)$/, 'first stmt ends at its own semicolon');
  is($s[1], 'CREATE SEQUENCE a_seq', 'second stmt intact');
}

{
  # no trailing semicolon on the final statement is still emitted
  my @s = split_ddl("CREATE TABLE a (id NUMBER);\nALTER TABLE a ADD (x NUMBER)");
  is(scalar @s, 2, 'final statement without trailing semicolon still captured');
  is($s[1], 'ALTER TABLE a ADD (x NUMBER)', 'trailing statement intact');
}

{
  # blank lines / empty fragments produce no spurious statements
  my @s = split_ddl("\n\nCREATE TABLE a (id NUMBER);\n\n\n");
  is_deeply(\@s, ['CREATE TABLE a (id NUMBER)'], 'blank lines dropped');
}

{
  my @s = split_ddl('');
  is_deeply(\@s, [], 'empty input yields no statements');
}

done_testing;
