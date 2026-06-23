#!/usr/bin/env perl
# t/35-ddl-emit.t — DBIO::DuckDB::DDL::Emit, the single source of DDL
# statement shape shared by DDL.pm and the Diff/* renderers. Pure string
# functions, no database.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::DDL::Emit qw(
  column_def pk_clause unique_clause fk_clause
  create_table create_index create_sequence
);

# column_def — NOT NULL, verbatim DEFAULT, undef default.
# _quote_ident leaves simple identifiers unquoted; a name with a space
# exercises the quoting path.
is column_def(name => 'name', type => 'VARCHAR'),
  'name VARCHAR', 'plain column';
is column_def(name => 'id', type => 'INTEGER', not_null => 1),
  'id INTEGER NOT NULL', 'not null';
is column_def(name => 'rank', type => 'INTEGER', not_null => 1, default => '0'),
  'rank INTEGER NOT NULL DEFAULT 0', 'default emitted verbatim';
is column_def(name => 'id', type => 'INTEGER', default => q{nextval('s')}),
  q{id INTEGER DEFAULT nextval('s')}, 'nextval default verbatim';
is column_def(name => 'x'),
  'x VARCHAR', 'type defaults to VARCHAR';
is column_def(name => 'odd name', type => 'INTEGER'),
  '"odd name" INTEGER', 'identifier with space quoted';

# clauses are unindented; create_table indents uniformly
is pk_clause('a', 'b'), 'PRIMARY KEY (a, b)', 'pk clause';
is unique_clause('title'), 'UNIQUE (title)', 'unique clause';
is fk_clause(from => ['artist'], to_table => 'artist', to => ['id']),
  'FOREIGN KEY (artist) REFERENCES artist(id)', 'fk clause';

is create_table('cd', column_def(name => 'id', type => 'INTEGER'), pk_clause('id')),
  qq{CREATE TABLE cd (\n  id INTEGER,\n  PRIMARY KEY (id)\n);},
  'create_table wraps + indents body';

is create_index(name => 'idx', table => 'cd', columns => ['title']),
  'CREATE INDEX idx ON cd (title);', 'create_index';
is create_index(name => 'u', table => 'cd', columns => ['a', 'b'], unique => 1),
  'CREATE UNIQUE INDEX u ON cd (a, b);', 'create_index unique';

is create_sequence(name => 'cd_id_seq'),
  'CREATE SEQUENCE IF NOT EXISTS cd_id_seq;', 'create_sequence';
is create_sequence(name => 'cd_id_seq', start => 1000000),
  'CREATE SEQUENCE IF NOT EXISTS cd_id_seq START 1000000;', 'create_sequence start';

done_testing;
