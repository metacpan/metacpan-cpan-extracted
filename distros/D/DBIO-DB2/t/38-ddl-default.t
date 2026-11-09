use strict;
use warnings;
use Test::More;

# Offline. How a column default becomes the SQL text of a DEFAULT clause -- on
# the two paths that write one, which start from two different things.
#
# install_ddl starts from a RESULT CLASS, whose default_value is a Perl value.
# It used to write every non-ref default as an unescaped string literal: an
# apostrophe broke out of the quotes (SQL injection / syntax error), a
# semicolon split _split_statements, and DEFAULT '13' on an INTEGER column was
# rejected by DB2 with SQL0574N. It goes through
# DBIO::DB2::DDL::_db2_default_literal (karr k32): numeric -> bare literal,
# NULL / DB2 special registers (CURRENT DATE, CURRENT TIMESTAMP, ...) -> bare
# function call, everything else -> single-quoted string literal with embedded
# single-quotes doubled ('').
#
# The diff op classes start from an INTROSPECTED MODEL, whose default_value is
# SYSCAT.COLUMNS.DEFAULT: the SQL text of the default, as the server keeps it.
# They write it back as it is.
#
# A CLAIM OF THIS FILE WAS REPLACED HERE (karr k41), and not quietly: until
# then it asserted that Diff::Table renders a default "through the same shared
# renderer" as install_ddl, and proved it by feeding the diff a model with
# default_value => "O'Brien" -- the result class shape. No diff ever sees that:
# measured on Db2 12.1.5, a default declared as 'it''s' comes back out of the
# catalog as 'it''s', quotes and doubled apostrophe included, on the live side
# and on the compare side alike. Run through the shared renderer, that text was
# quoted a second time (DEFAULT '''it''''s'''); the server accepted it, an
# insert then stored the text 'it''s' with its quotes, and every later diff
# asked to set the default again. The assertion was green the whole time
# because it sampled a shape that does not occur. What stands now: one renderer for install_ddl, and for the diff the
# catalog text unchanged -- t/12-db2-upgrade.t holds both ends against a server.
#
# Also the karr k32 undef guard: _db2_quote_ident(undef) (e.g. constraint_name
# from an incomplete FK hash) used to silently emit a warning-level empty ""
# -- it now croaks naming the caller.

use_ok 'DBIO::DB2::DDL';
use_ok 'DBIO::DB2::Diff::Table';
use_ok 'DBIO::DB2::Diff::Column';
use_ok 'DBIO::SQL::Util';

# ---------------------------------------------------------------------------
# Shared renderer: _db2_default_literal
# ---------------------------------------------------------------------------
is(DBIO::DB2::DDL::_db2_default_literal("O'Brien"), "'O''Brien'",
  'embedded single-quote is doubled (no SQL injection)');
is(DBIO::DB2::DDL::_db2_default_literal('a;b'), "'a;b'",
  'embedded semicolon stays inside the quoted literal');
is(DBIO::DB2::DDL::_db2_default_literal('13'), '13',
  'numeric default stays bare (no quotes)');
is(DBIO::DB2::DDL::_db2_default_literal('-13.5'), '-13.5',
  'signed decimal default stays bare');
is(DBIO::DB2::DDL::_db2_default_literal('NULL'), 'NULL',
  'NULL default stays bare');
is(DBIO::DB2::DDL::_db2_default_literal('CURRENT TIMESTAMP'), 'CURRENT TIMESTAMP',
  'CURRENT TIMESTAMP default stays bare');
is(DBIO::DB2::DDL::_db2_default_literal('CURRENT_DATE'), 'CURRENT_DATE',
  'underscore CURRENT_DATE default stays bare');
is(DBIO::DB2::DDL::_db2_default_literal(\'CURRENT TIMESTAMP'), 'CURRENT TIMESTAMP',
  'SCALAR-ref raw SQL expression stays bare');
is(DBIO::DB2::DDL::_db2_default_literal('hello'), "'hello'",
  'plain string default is single-quoted');
is(DBIO::DB2::DDL::_db2_default_literal(''), "''",
  'empty string default is an empty quoted literal');

# With the column's type (karr k46): a character column takes every non-ref
# value as text, the type map's aliases included; other types and no type at
# all behave as above.
is(DBIO::DB2::DDL::_db2_default_literal('00000', 'char'), "'00000'",
  'digits on a CHAR column keep their zeros as a string literal');
is(DBIO::DB2::DDL::_db2_default_literal('00000', 'CHAR(5)'), "'00000'",
  '... also with the length in the type');
is(DBIO::DB2::DDL::_db2_default_literal('USER', 'varchar'), "'USER'",
  'USER on a VARCHAR column is the text, not the special register');
is(DBIO::DB2::DDL::_db2_default_literal('NULL', 'VARCHAR'), "'NULL'",
  'NULL on a VARCHAR column is the text, not NULL');
is(DBIO::DB2::DDL::_db2_default_literal('CURRENT DATE', 'text'), "'CURRENT DATE'",
  'the alias text (VARCHAR) counts as a character type');
is(DBIO::DB2::DDL::_db2_default_literal('1', $_), "'1'", "$_ is a character type")
  for 'clob', 'graphic', 'vargraphic', 'dbclob', 'long varchar';
is(DBIO::DB2::DDL::_db2_default_literal(\'USER', 'varchar'), 'USER',
  'a SCALAR ref stays raw on a character column');
is(DBIO::DB2::DDL::_db2_default_literal('13', 'integer'), '13',
  'numeric default on INTEGER stays bare');
is(DBIO::DB2::DDL::_db2_default_literal('USER', 'integer'), 'USER',
  'USER on a non-character column stays the register');
is(DBIO::DB2::DDL::_db2_default_literal('13', undef), '13',
  'no type: unchanged behaviour');

# ---------------------------------------------------------------------------
# install_ddl must render defaults through the shared renderer.
# ---------------------------------------------------------------------------
{
  package My::DF::Schema::Thing;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('thing');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    # is_nullable => 1 on every default column: these tests are about the
    # DEFAULT rendering, not the ADR 0043 NOT NULL fold -- keep the DDL shape
    # free of NOT NULL so the assertions below match the type directly.
    label   => { data_type => 'varchar', size => 64, is_nullable => 1,
                 default_value => "O'Brien" },
    note    => { data_type => 'varchar', size => 64, is_nullable => 1,
                 default_value => 'a;b' },
    count   => { data_type => 'integer', is_nullable => 1, default_value => '13' },
    flag    => { data_type => 'integer', is_nullable => 1, default_value => 'NULL' },
    created => { data_type => 'timestamp', is_nullable => 1,
                 default_value => \'CURRENT TIMESTAMP' },
    plz     => { data_type => 'char', size => 5, is_nullable => 1,
                 default_value => '00000' },
    who     => { data_type => 'varchar', size => 32, is_nullable => 1,
                 default_value => 'USER' },
    nothing => { data_type => 'varchar', size => 32, is_nullable => 1,
                 default_value => 'NULL' },
    rawuser => { data_type => 'varchar', size => 32, is_nullable => 1,
                 default_value => \'USER' },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package My::DF::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Thing => 'My::DF::Schema::Thing');
}

my $ddl = DBIO::DB2::DDL->install_ddl('My::DF::Schema');
ok length $ddl, 'DDL generated';

like($ddl, qr/"label"\s+VARCHAR\(64\) DEFAULT 'O''Brien'/,
  'install_ddl escapes an embedded single-quote in a default');
like($ddl, qr/"note"\s+VARCHAR\(64\) DEFAULT 'a;b'/,
  'install_ddl keeps an embedded semicolon inside the quoted default');
like($ddl, qr/"count"\s+INTEGER DEFAULT 13/,
  'install_ddl emits a numeric default bare (no quotes)');
like($ddl, qr/"flag"\s+INTEGER DEFAULT NULL/,
  'install_ddl emits a NULL default bare');
like($ddl, qr/"created"\s+TIMESTAMP DEFAULT CURRENT TIMESTAMP/,
  'install_ddl emits a SCALAR-ref CURRENT TIMESTAMP default bare');

like($ddl, qr/"plz"\s+CHAR\(5\) DEFAULT '00000'/,
  'install_ddl quotes digits on a CHAR column (karr k46)');
like($ddl, qr/"who"\s+VARCHAR\(32\) DEFAULT 'USER'/,
  'install_ddl quotes USER on a VARCHAR column');
like($ddl, qr/"nothing"\s+VARCHAR\(32\) DEFAULT 'NULL'/,
  'install_ddl quotes NULL on a VARCHAR column');
like($ddl, qr/"rawuser"\s+VARCHAR\(32\) DEFAULT USER[,\n]/,
  'install_ddl leaves a SCALAR ref raw on a VARCHAR column');

# ---------------------------------------------------------------------------
# The diff path writes the catalog's DEFAULT text as it is (karr k41; the
# replaced claim is at the head of this file). The columns below are in the
# shape DBIO::DB2::Introspect::Columns returns, and each default is a form
# SYSCAT.COLUMNS.DEFAULT was seen to hold on Db2 12.1.5: a string literal with
# its quotes (an apostrophe in it doubled, a semicolon, digits, nothing at
# all), a bare number, NULL, and a special register.
# ---------------------------------------------------------------------------
my @CATALOG_COLUMNS = (
  # column,  data_type,   size, default_value,          the clause it must become
  [ 'label',   'VARCHAR',   64, q{'O''Brien'},          q{DEFAULT 'O''Brien'} ],
  [ 'note',    'VARCHAR',   64, q{'a;b'},               q{DEFAULT 'a;b'} ],
  [ 'digits',  'VARCHAR',   64, q{'13'},                q{DEFAULT '13'} ],
  [ 'empty',   'VARCHAR',   64, q{''},                  q{DEFAULT ''} ],
  [ 'count',   'INTEGER',    4, q{13},                  q{DEFAULT 13} ],
  [ 'flag',    'INTEGER',    4, q{NULL},                q{DEFAULT NULL} ],
  [ 'price',   'DECIMAL', '10,2', q{1.50},              q{DEFAULT 1.50} ],
  [ 'created', 'TIMESTAMP',  6, q{CURRENT TIMESTAMP},   q{DEFAULT CURRENT TIMESTAMP} ],
  [ 'owner',   'VARCHAR',  128, q{USER},                q{DEFAULT USER} ],
);

sub catalog_column {
  my ($c) = @_;
  return {
    column_name => $c->[0], catalog_type => $c->[1], catalog_size => $c->[2],
    catalog_default => $c->[3], not_null => 0, is_pk => 0, pk_position => 0,
  };
}

{
  my @ops = DBIO::DB2::Diff::Table->diff(
    {},
    { thing => { table_name => 'thing', kind => 'table' } },
    { thing => [ map { catalog_column($_) } @CATALOG_COLUMNS ] },
    { thing => [] },
  );
  my $sql = $ops[0]->as_sql;

  for my $c (@CATALOG_COLUMNS) {
    like $sql, qr/^\s*"$c->[0]" \S+ \Q$c->[4]\E,?$/m,
      "Diff::Table create writes the catalog default of $c->[0] as it is: $c->[4]";
  }
  unlike $sql, qr/'''/,
    '... and no default in it is quoted a second time';
}

for my $c (@CATALOG_COLUMNS) {
  my $col = catalog_column($c);

  my ($add) = DBIO::DB2::Diff::Column->diff(
    { thing => [] }, { thing => [ $col ] }, { thing => {} }, { thing => {} },
  );
  like $add->as_sql, qr/^ALTER TABLE "thing" ADD COLUMN "$c->[0]" \S+ \Q$c->[4]\E;$/,
    "Diff::Column add writes the catalog default of $c->[0] as it is";

  # The same column on both sides, the live one with another default: that is
  # the alter the next diff must not ask for again.
  my ($alter) = DBIO::DB2::Diff::Column->diff(
    { thing => [ { %$col, catalog_default => q{'something else'} } ] },
    { thing => [ $col ] },
    { thing => {} }, { thing => {} },
  );
  is $alter->as_sql, qq{ALTER TABLE "thing" ALTER COLUMN "$c->[0]" SET $c->[4];},
    "Diff::Column alter sets the catalog default of $c->[0] as it is, and nothing else";
}

# ---------------------------------------------------------------------------
# _db2_quote_ident(undef) must croak naming the caller, not silently emit a
# warning-level empty "" (karr k32).
# ---------------------------------------------------------------------------
{
  my $err = eval { DBIO::DB2::DDL::_db2_quote_ident(undef); 1 };
  ok(!$err, '_db2_quote_ident(undef) croaks');
  like($@, qr/undef identifier/, 'croak message names the undef identifier');
  like($@, qr/38-ddl-default\.t/, 'croak message names the caller');
}

# ---------------------------------------------------------------------------
# Semicolon in a default: the renderer's half of karr k32 is that the
# semicolon stays INSIDE a properly-quoted literal (the old install_ddl
# emitted it unescaped) -- pinned above by the _db2_default_literal unit test
# and the install_ddl "note" assertion; on the diff path the catalog text
# 'a;b' carries its own quotes.
# The splitter's half is a core defect, not a db2 one:
# DBIO::SQL::Util::_split_statements only understands $$ dollar-quoting, not
# single-quoted strings, so a semicolon inside ANY single-quoted literal still
# splits there. That needs a core fix (tracked separately); the db2 side
# cannot work around it without emitting non-DB2 SQL.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# BOOLEAN (karr k54, ADR 0004 addendum). The column is a native BOOLEAN now, not
# a SMALLINT. Measured on Db2 12.1.5: it takes DEFAULT 1, 0, TRUE, FALSE, '1' and
# 'true' alike, so a result class's 0/1 needs no mapping -- the numeric rule
# writes it bare -- and a SCALAR reference (TRUE) stays raw. A character default
# stays a string literal (the server converts it).
# ---------------------------------------------------------------------------
{
  require DBIO::DB2::DDL;
  is DBIO::DB2::DDL::_db2_default_literal(1, 'boolean'), '1', 'boolean default 1: bare';
  is DBIO::DB2::DDL::_db2_default_literal(0, 'boolean'), '0', 'boolean default 0: bare';
  is DBIO::DB2::DDL::_db2_default_literal(\'TRUE', 'boolean'), 'TRUE', 'boolean default \'TRUE\': raw';
  is DBIO::DB2::DDL::_db2_default_literal(\'FALSE', 'bool'), 'FALSE', 'bool default \'FALSE\': raw';
  is DBIO::DB2::DDL::_db2_default_literal('true', 'boolean'), q{'true'}, 'a string stays a literal';
}

done_testing;
