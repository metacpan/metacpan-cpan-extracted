use strict;
use warnings;
use Test::More;
use DBIO::SQL::Util ();

sub exception(&) { local $@; return eval { $_[0]->(); 1 } ? undef : "$@" }

# Offline/mock coverage for the Sybase Diff triad. No live server: we feed
# introspected-model hashrefs (the shape DBIO::Sybase::Introspect produces)
# straight into the diff classes and assert on as_sql + summary.

use_ok 'DBIO::Sybase::Diff::Table';
use_ok 'DBIO::Sybase::Diff::Column';
use_ok 'DBIO::Sybase::Diff::Index';
use_ok 'DBIO::Sybase::Diff::ForeignKey';
use_ok 'DBIO::Sybase::Diff';

# Model helpers — keys match DBIO::Sybase::Introspect::{Tables,Columns,Indexes}.
sub tbl  { +{ table_name => $_[0], kind => 'table' } }
# `size` is modelled deliberately (karr k32): without it every column in this
# file was sizeless, and a whole bug class -- an emitter that drops the
# length/precision -- could not be seen from here at all.
sub col  {
  my ($name, %o) = @_;
  +{ column_name => $name, data_type => $o{type} // 'integer',
     size => $o{size},
     not_null => $o{not_null} // 0, default_value => $o{default},
     is_pk => $o{is_pk} // 0 };
}
sub idx  {
  my ($name, %o) = @_;
  +{ index_name => $name, is_unique => $o{unique} // 0,
     columns => $o{columns} // [] };
}
# FK entry — keys match DBIO::Sybase::Introspect's _group_fks_by_constraint
# output (per-constraint). This bare form omits constraint_name, as a desired/
# target model does; use fkn() for a source entry that carries the live name.
sub fk   {
  my %o = @_;
  +{ from_columns => $o{from} // [], to_table => $o{to_table},
     to_columns => $o{to} // [],
     on_update => $o{on_update}, on_delete => $o{on_delete} };
}
# FK entry carrying a live, server-assigned constraint_name (as produced for a
# source/introspected model). The desired/target model never carries one.
sub fkn  {
  my ($name, %o) = @_;
  +{ %{ fk(%o) }, constraint_name => $name };
}

# --- Diff::Table create (with columns wired in from target_columns) ---
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    {},
    { author => tbl('author') },
    { author => [ col('id', type => 'integer', not_null => 1, is_pk => 1),
                  col('name', type => 'varchar', not_null => 1) ] },
    {},
  );
  is(scalar @ops, 1, 'one create op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Table::Create');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE "?author"?/,  'create table emitted');
  like($sql, qr/"?id"? INT NOT NULL/,      'id column wired in');
  like($sql, qr/"?name"? VARCHAR\(255\) NOT NULL/, 'name column wired in');
  is($ops[0]->summary, 'CREATE TABLE author', 'create summary');
}

# --- Diff::Table create with identity column (is_identity round-trips) ---
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    {},
    { account => tbl('account') },
    { account => [ { %{ col('id', type => 'integer', not_null => 1, is_pk => 1) },
                    is_auto_increment => 1 } ] },
    {},
  );
  # CLAIM REPLACED (karr k47): this used to assert `INT NOT NULL IDENTITY`,
  # i.e. only "IDENTITY is present somewhere after the type". ASE's grammar
  # makes identity, null and not null ALTERNATIVES -- column_name datatype
  # [default ...] [{identity | null | not null}] -- so the claim now pins the
  # one spelling the grammar allows: the attribute alone, no nullability, no
  # default.
  # The line now ends in a comma (karr k53): the PRIMARY KEY clause follows it.
  like($ops[0]->as_sql, qr/^  "?id"? INT IDENTITY,?$/m, 'identity column is TYPE IDENTITY alone');
}

# --- Diff::Table create: IDENTITY on a numeric column only (karr k52) ---
# The same rule install_ddl carries, because this is the other emitter of the
# same column grammar: ASE takes the identity attribute on a numeric column and
# nowhere else. A model column marked is_auto_increment whose type is known to
# be non-numeric is refused, naming table, column and type; an unknown type
# name (a user-defined datatype) is not known to be non-numeric and renders as
# before.
{
  my $create = sub {
    my (@cols) = @_;
    my ($op) = DBIO::Sybase::Diff::Table->diff(
      {}, { guid_t => tbl('guid_t') }, { guid_t => [@cols] }, {});
    return $op;
  };
  my $autoinc = sub {
    my ($type, %o) = @_;
    +{ %{ col('id', type => $type, not_null => 1, is_pk => 1, %o) },
       is_auto_increment => 1 };
  };

  like($create->($autoinc->('bigint'))->as_sql, qr/^  "?id"? BIGINT IDENTITY,$/m,
    'create table: is_auto_increment on bigint is BIGINT IDENTITY');
  like($create->($autoinc->('numeric', size => [ 10, 0 ]))->as_sql,
    qr/^  "?id"? NUMERIC\(10,0\) IDENTITY,$/m,
    'create table: is_auto_increment on numeric(10,0) is NUMERIC(10,0) IDENTITY');
  like($create->($autoinc->('my_id_type'))->as_sql, qr/^  "?id"? MY_ID_TYPE IDENTITY,$/m,
    'create table: is_auto_increment on an unknown (user-defined) type still renders IDENTITY');

  for my $t ([ varchar => 'VARCHAR' ], [ datetime => 'DATETIME' ],
             [ uniqueidentifier => 'VARCHAR(36)' ]) {
    my ($data_type, $sql) = @$t;
    my $op  = $create->($autoinc->($data_type));
    my $got = eval { $op->as_sql };
    my $err = $@;
    is($got, undef, "create table: is_auto_increment on $data_type renders no DDL");
    like($err, qr/\bguid_t\b.*\bid\b|\bid\b.*\bguid_t\b/s,
      "create table: ... the refusal names table and column ($data_type)");
    like($err, qr/\Q$data_type\E.*\Q$sql\E/s,
      "create table: ... and the type, as declared and as rendered ($data_type)");
    like($err, qr/IDENTITY.*auto_nextval/s,
      "create table: ... and points at auto_nextval ($data_type)");
  }

  # ASE takes IDENTITY on integers and NUMERIC(p,0) only (Msg 2764, live):
  # the rest of the numeric family is refused here too, like install_ddl.
  for my $t ([ numeric => 'NUMERIC(18,6)', undef ], [ decimal => 'NUMERIC(18,6)', undef ],
             [ numeric => 'NUMERIC(10,2)', [ 10, 2 ] ], [ float => 'FLOAT', undef ],
             [ real => 'FLOAT', undef ], [ 'double precision' => 'DOUBLE PRECISION', undef ],
             [ boolean => 'BIT', undef ], [ money => 'MONEY', undef ],
             [ smallmoney => 'SMALLMONEY', undef ]) {
    my ($data_type, $sql, $size) = @$t;
    my $op  = $create->($autoinc->($data_type, size => $size));
    my $got = eval { $op->as_sql };
    my $err = $@;
    is($got, undef, "create table: is_auto_increment on $data_type ($sql) renders no DDL");
    like($err, qr/\bguid_t\b.*\bid\b|\bid\b.*\bguid_t\b/s,
      "create table: ... the refusal names table and column ($data_type $sql)");
    like($err, qr/IDENTITY.*auto_nextval/s,
      "create table: ... and points at auto_nextval ($data_type $sql)");
  }
  like($create->($autoinc->('uint'))->as_sql, qr/^  "?id"? UINT IDENTITY,$/m,
    'create table: is_auto_increment on uint still renders IDENTITY');

  # A GUID column that is not claimed as an identity is an ordinary VARCHAR(36)
  # with the nullability the model gives it.
  is($create->(
      col('id', type => 'uniqueidentifier', not_null => 1, is_pk => 1),
      col('a_guid', type => 'uniqueidentifier'),
    )->as_sql,
    "CREATE TABLE guid_t (\n"
    . "  id VARCHAR(36) NOT NULL,\n"
    . "  a_guid VARCHAR(36) NULL,\n"
    . "  PRIMARY KEY (id)\n"
    . ");",
    'create table: uniqueidentifier is VARCHAR(36) with its own nullability');
}

# --- Diff::Table create: clause order and explicit NULL (karr k47) ---
# Same grammar as install_ddl, same live finding: `NOT NULL DEFAULT 'x'` is
# Msg 156 on ASE 16.0 SP02, `DEFAULT 'x' NOT NULL` is accepted. And a nullable
# column must say NULL -- without it the column takes the database's "allow
# nulls by default" option, which is off in a fresh database.
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    {},
    { t => tbl('t') },
    { t => [ col('id', type => 'integer', not_null => 1, is_pk => 1),
             col('name', type => 'varchar', size => 32, not_null => 1, default => 'old'),
             col('code', type => 'varchar', size => 16) ] },
    {},
  );
  # CLAIM REPLACED (karr k53): the expected text pinned a CREATE TABLE without
  # a PRIMARY KEY for a model whose id is is_pk -- i.e. it pinned the bug that
  # a table created by upgrade() lost its key. The clause-order claim stands.
  is($ops[0]->as_sql, "CREATE TABLE t (\n"
    . "  id INT NOT NULL,\n"
    . "  name VARCHAR(32) DEFAULT 'old' NOT NULL,\n"
    . "  code VARCHAR(16) NULL,\n"
    . "  PRIMARY KEY (id)\n"
    . ");",
    'create table: DEFAULT before NOT NULL, nullable spelled NULL');
}

# --- numeric defaults are rendered unquoted on every emit path (karr k55) ---
# install_ddl, Diff::Table::Create, Column::Add and the REPLACE all route
# through sybase_default_clause, and all four have to hand it the column's
# type -- a path that forgets it falls back to quoting, which on ASE deploys a
# column whose every defaulted INSERT fails with Msg 257.
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    {},
    { t => tbl('t') },
    { t => [ col('price', type => 'numeric', size => [10, 2], default => 0),
             col('flag',  type => 'boolean', not_null => 1, default => 1),
             col('label', type => 'varchar', size => 8, default => '0') ] },
    {},
  );
  is($ops[0]->as_sql, "CREATE TABLE t (\n"
    . "  price NUMERIC(10,2) DEFAULT 0 NULL,\n"
    . "  flag BIT DEFAULT 1 NOT NULL,\n"
    . "  label VARCHAR(8) DEFAULT '0' NULL\n"
    . ");",
    'create table: numeric/bit defaults unquoted, a varchar 0 stays quoted');
}
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id') ] },
    { t => [ col('id'), col('flag', type => 'boolean', not_null => 1, default => 0) ] },
    {}, {},
  );
  is($ops[0]->as_sql, 'ALTER TABLE t ADD flag BIT DEFAULT 0 NOT NULL;',
    'column add: bit default unquoted');
}
{
  # REPLACE carries the rendered target default -- unquoted on a numeric column.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('price', type => 'numeric', size => [10, 2], default => 0) ] },
    { t => [ col('price', type => 'numeric', size => [10, 2], default => '1.50') ] },
    {}, {},
  );
  is($ops[0]->as_sql, 'ALTER TABLE t REPLACE price DEFAULT 1.50;',
    'replace: numeric default unquoted');
}
{
  # The replace decision compares RENDERED clauses, each side under its own
  # type. A varchar column with default '0' retyped to integer keeps the same
  # default_value, but the live clause is DEFAULT '0' -- the VARCHAR constant
  # that breaks every INSERT on an INT column -- and the wanted one DEFAULT 0.
  # The modify alone would leave the broken default in place, so the replace
  # has to follow it.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('n', type => 'varchar', size => 8, default => '0') ] },
    { t => [ col('n', type => 'integer', default => '0') ] },
    {}, {},
  );
  is($ops[0]->as_sql,
    'ALTER TABLE t MODIFY n INT NULL; ALTER TABLE t REPLACE n DEFAULT 0;',
    'retype varchar -> int: the default is re-rendered unquoted by a replace');
}
{
  # A legacy numeric column deployed before k55 reads back from syscomments as
  # DEFAULT '0' -- introspection keeps that as the SQL expression \"'0'" (see
  # t/56) -- and the desired 0 renders DEFAULT 0. That is a real difference
  # and the diff repairs it with a replace, rather than hiding the broken
  # default behind an equal default_value.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('price', type => 'numeric', size => [10, 2], default => \"'0'") ] },
    { t => [ col('price', type => 'numeric', size => [10, 2], default => 0) ] },
    {}, {},
  );
  is(scalar @ops, 1, 'legacy quoted numeric default is drift');
  is($ops[0]->as_sql, 'ALTER TABLE t REPLACE price DEFAULT 0;',
    'legacy quoted numeric default is replaced by the unquoted one');
}
{
  # ... and the two spellings that render the same clause are not drift: a
  # numeric default given as the expression \'0' and the literal 0 both
  # render DEFAULT 0 on a numeric column, and the live catalog reads either
  # one back as the literal '0'.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('n', type => 'integer', default => '0') ] },
    { t => [ col('n', type => 'integer', default => \'0') ] },
    {}, {},
  );
  is(scalar @ops, 0, "\\'0' and '0' on a numeric column are the same default");
}

# --- Diff::Table drop ---
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    { gone => tbl('gone') },
    {},
    {},
    {},
  );
  is(scalar @ops, 1, 'one drop op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Table::Drop');
  is($ops[0]->as_sql,  'DROP TABLE gone;', 'drop SQL');
  is($ops[0]->summary, 'DROP TABLE gone', 'drop summary');
}

# --- Diff::Table: same kind on both sides → no table-level op (GAP2) ---
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    { author => tbl('author') },
    { author => tbl('author') },
    { author => [ col('id') ] },
    {},
  );
  is(scalar @ops, 0, 'unchanged table yields no table-level op');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id') ] },
    { t => [ col('id'), col('extra', type => 'varchar') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'one add op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Column::Add');
  # REPLACED CLAIM (karr k32): this line used to assert
  #   'ALTER TABLE t ADD extra varchar'
  # -- the raw data_type, which is what the emitter emitted. That was not a
  # property worth sampling, it was the bug pinned as the expectation: ASE
  # reads a bare `varchar` in a column definition as VARCHAR(1), and the same
  # column deployed by CREATE TABLE gets the rendered type. The claim now is
  # the one that matters: an ADD renders the column exactly as install_ddl and
  # Diff::Table::Create would, defaults included.
  #
  # EXTENDED CLAIM (karr k39): the trailing ` NULL` is new; the rendered type
  # in the middle is the k32 property above and is asserted unchanged. col()
  # defaults not_null => 0, so this column is nullable, and an ADD that says
  # so is the whole point: a bare add inherits the database's null default
  # (`not null` unless sp_dboption 'allow nulls by default'), which would
  # create this nullable column as NOT NULL on a stock server.
  is($ops[0]->as_sql,  'ALTER TABLE t ADD extra VARCHAR(255) NULL;', 'add SQL');
  is($ops[0]->summary, 'ALTER TABLE t ADD extra',                   'add summary');
}

# --- Diff::Column add: the declared size reaches the statement (karr k32) ---
# The size lives in its own model field, so an emitter reading only data_type
# drops it silently -- and the deploy path hits this on every incremental ADD,
# since Introspect::Columns of the temp DB reports size correctly.
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id') ] },
    { t => [ col('id'),
             col('extra',  type => 'varchar', size => 64),
             col('code',   type => 'char',    size => 3),
             col('amount', type => 'numeric', size => [10, 2]) ] },
    {}, {},
  );
  is(scalar @ops, 3, 'three add ops');
  my %sql = map { $_->col->{column_name} => $_->as_sql } @ops;
  # EXTENDED CLAIM (karr k39): the trailing ` NULL` is new on all three. The
  # property these three exist for -- the declared size reaches the rendered
  # type -- is the substring before it and is asserted unchanged.
  is($sql{extra},  'ALTER TABLE t ADD extra VARCHAR(64) NULL;',    'add keeps varchar length');
  is($sql{code},   'ALTER TABLE t ADD code CHAR(3) NULL;',         'add keeps char length');
  is($sql{amount}, 'ALTER TABLE t ADD amount NUMERIC(10,2) NULL;', 'add keeps numeric precision/scale');
}

# --- Diff::Column add: nullability + default clause (karr k39) ---
# An ADD that says nothing about nullability is not neutral on ASE: the manual
# (Reference Manual: Commands, alter table, parameter `null | not null`) says
# "If you do not specify null or not null, the SAP ASE server uses not null by
# default. However, you can switch this default using sp_dboption". So the
# statement's meaning is a property of the target server, not of the schema --
# and the implied `not null` then trips the second rule, that a not-null add
# requires a default clause. Both outcomes are wrong and which one happens is
# not ours to choose, so the nullability is always written out.
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id') ] },
    { t => [ col('id'),
             col('plain',  type => 'varchar', size => 10),
             col('nn',     type => 'varchar', size => 10, not_null => 1, default => 'x'),
             col('nulled', type => 'integer', default => 0),
             col('expr',   type => 'datetime', default => \'getdate()'),
             col('exprnn', type => 'datetime', not_null => 1, default => \'getdate()') ] },
    {}, {},
  );
  my %sql = map { $_->col->{column_name} => $_->as_sql }
    grep { $_->col->{column_name} ne 'exprnn' } @ops;
  my ($exprnn) = grep { $_->col->{column_name} eq 'exprnn' } @ops;

  # A nullable column says NULL, and carries no DEFAULT when none was declared.
  is($sql{plain}, 'ALTER TABLE t ADD plain VARCHAR(10) NULL;',
    'nullable add spells NULL out');

  # The clause ORDER is the load-bearing claim here, and it is ASE's, not
  # Transact-SQL's: the grammar is
  #   {add column_name datatype} [default {...}] {identity | null | not null}
  # so the default comes BEFORE the nullability. dbio-mssql emits the opposite
  # order for its dialect; copying that shape here would be wrong.
  is($sql{nn}, "ALTER TABLE t ADD nn VARCHAR(10) DEFAULT 'x' NOT NULL;",
    'not-null add renders DEFAULT before NOT NULL');

  # Same order on a nullable column that happens to have a default.
  #
  # CLAIM REPLACED (karr k55), the expected string only: this read
  # "ADD nulled INT DEFAULT '0' NULL". The claim -- DEFAULT before the
  # nullability -- is sampled exactly as before. The quoting was never part of
  # it and was wrong: on an INT column ASE stores '0' as a VARCHAR constant and
  # every INSERT leaving the column out fails with Msg 257 (live, ASE 16.0
  # SP02). A numeric column's numeric default is now rendered unquoted.
  is($sql{nulled}, "ALTER TABLE t ADD nulled INT DEFAULT 0 NULL;",
    'nullable add with a default keeps the same clause order');

  # A SCALAR ref is an SQL expression: emitted verbatim, not quoted. Shared
  # with install_ddl and Diff::Table::Create via sybase_default_clause, so all
  # three spell a default identically.
  # CLAIM KEPT, the column changed (karr k97): the claim is that the expression
  # is written verbatim. It was sampled on a NOT NULL column, which ASE refuses
  # (Msg 13918, "Default cannot be an expression when adding non-NULL
  # column"), so it is sampled on a nullable one and the NOT NULL one is
  # refused below.
  is($sql{expr}, 'ALTER TABLE t ADD expr DATETIME DEFAULT getdate() NULL;',
    'an add renders an expression default unquoted');
  my $refused = eval { $exprnn->as_sql; 1 } ? '' : "$@";
  like($refused, qr/table t, column exprnn: .*is refused: ASE cannot add a NOT NULL column with an expression default \(Msg 13918\)/s,
    'a not-null add with an expression default is refused before the server is asked');
  {
    my @bare = DBIO::Sybase::Diff::Column->diff({ t => [ col('id') ] },
      { t => [ col('id'), col('bare', type => 'integer', not_null => 1) ] }, {}, {});
    my $err = eval { $bare[0]->as_sql; 1 } ? '' : "$@";
    like($err, qr/table t, column bare: .*the add is refused: ASE requires a default clause/s,
      'a not-null add without a default is refused, naming table and column');
  }
}

# --- Diff::Column add: not_null without a usable default is refused (k39) ---
# "If you specify (or imply) not null for the newly added column, a default
# clause is required" -- unconditionally, not merely for a populated table.
# There is no correct statement to emit from this model, so as_sql croaks
# naming the table and column rather than sending one the server rejects with
# an error naming neither. Same call this driver's MSSQL sibling makes for a
# default drop with no default_constraint_name.
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id') ] },
    { t => [ col('id'), col('extra', type => 'varchar', size => 64, not_null => 1) ] },
    {}, {},
  );
  is(scalar @ops, 1, 'the op is still built -- only rendering refuses');
  # summary stays available, so a diff can still report the column as missing
  # even though it cannot render the statement.
  is($ops[0]->summary, 'ALTER TABLE t ADD extra', 'summary survives the refusal');
  my $sql = eval { $ops[0]->as_sql };
  ok(!defined $sql, 'not-null add without a default renders nothing');
  like($@, qr/\bnot-null add\b/, 'croak names the rule it is enforcing');
  like($@, qr/\bADD extra\b/,    'croak names the offending column');
}

# The predicate is the RENDERED default clause, not default_value: 'null' is
# the literal sybase_default_clause deliberately renders as no clause at all,
# so it reaches the server as exactly the statement the rule forbids -- and it
# contradicts itself besides, a column that forbids nulls defaulting to one.
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id') ] },
    { t => [ col('id'),
             col('extra', type => 'varchar', size => 64, not_null => 1,
                 default => 'null') ] },
    {}, {},
  );
  ok(!defined eval { $ops[0]->as_sql },
    "not-null add with a 'null' default is refused too");
  like($@, qr/\bnot-null add\b/, "the 'null' default croaks for the same reason");
}

# --- Diff::Column alter (type change) ---
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id', type => 'integer') ] },
    { t => [ col('id', type => 'bigint', not_null => 1) ] },
    {}, {},
  );
  is(scalar @ops, 1, 'one alter op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Column::Alter');
  # TIGHTENED (karr k32): was a like() on the raw data_type, which could not
  # tell a rendered type from an unrendered one -- qr/... id bigint .../
  # matched only because nothing rendered. is() names the whole statement, so
  # a size or default silently dropped from it fails here.
  # BIGINT is the logical `bigint` rendered at its declared width, which is
  # what makes this case a TYPE-change case at all: until karr k40 fixed the
  # transposed integer mapping, both sides of this integer -> bigint alter
  # rendered INT, so the statement this line pins carried no type change and
  # the widening it exists to sample was invisible in the SQL.
  #
  # RESPELLED (karr k38): the clause keyword is now MODIFY. The property this
  # line was written for -- an alter renders the target's TYPE at its declared
  # width -- is `BIGINT NOT NULL`, byte for byte what it was, and it is still
  # what fails here if the type mapping regresses. Only the frame around it
  # moved, from Transact-SQL's `ALTER COLUMN`, which parses on no ASE, to the
  # `modify` production the Reference Manual actually publishes. The claim is
  # relocated, not weakened: it is now measured against grammar a server could
  # accept, which is the whole point of the exercise.
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY id BIGINT NOT NULL;', 'alter SQL');
  # The summary follows the same keyword, as the ADD and DROP summaries in this
  # file follow theirs ('ALTER TABLE t ADD extra', 'ALTER TABLE t DROP old').
  # It claims what it always claimed -- table, operation, column -- and now
  # names an operation that exists.
  is($ops[0]->summary, 'ALTER TABLE t MODIFY id', 'alter summary');
}

# --- Diff::Column alter: a size-only change renders the new width (karr k32) ---
# The case that made this bug expensive: data_type is `varchar` on both sides,
# so an emitter reading only data_type produced a statement that changed
# nothing, while changed_column_fields kept reporting the size as changed and
# the diff never converged.
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64,  not_null => 1) ] },
    { t => [ col('name', type => 'varchar', size => 128, not_null => 1) ] },
    {}, {},
  );
  is(scalar @ops, 1, 'size-only change yields one alter op');
  # RESPELLED (karr k38), claim unchanged: `VARCHAR(128) NOT NULL` is the new
  # width reaching the statement, which is the only thing this case samples.
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(128) NOT NULL;',
    'alter renders the new width');
}

# --- Diff::Column alter: the desired-state contract, per field (karr k35) ---
# not_null, data_type and size are all desired-state-skippable in core's
# comparator: a target leaving one undef prescribed nothing, so the op exists
# because some OTHER field moved and the live value has to stand. Reading the
# target alone dropped the live value onto the floor.
#
# For not_null that is not a cosmetic difference. ASE's `modify` grammar makes
# the nullability optional, and an omitted one does not preserve the column's
# nullability -- it falls back to a default (the datatype's, or the database's
# `allow nulls by default` setting) that this driver cannot see. So the
# statement always spells it out, and what it spells has to be the live value
# when the target named none.
#
# RESPELLED (karr k38) throughout the group below: every one of these
# assertions used to read `ALTER TABLE t ALTER COLUMN ...`, which is
# Transact-SQL and parses on no ASE. Each one CLAIMS a fallback property --
# which of the two sides supplies the type, the width, the nullability -- and
# each of those properties is byte for byte what it was; only the clause
# keyword around it moved to the `modify` the Reference Manual publishes. No
# claim in this group is weakened or dropped; they are now sampled against
# grammar a server could accept.
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1) ] },
    { t => [ { %{ col('name', type => 'varchar', size => 128) },
               not_null => undef } ] },
    {}, {},
  );
  is(scalar @ops, 1, 'unprescribed not_null still yields one alter op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(128) NOT NULL;',
    'an unprescribed not_null falls back to the live NOT NULL');
}
{
  # An unprescribed size keeps the live width: a bare VARCHAR in an ASE column
  # definition is not "unbounded", so falling through would silently narrow
  # the column while the statement claims to be about the nullability.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 0) ] },
    { t => [ { %{ col('name', type => 'varchar', not_null => 1) },
               size => undef } ] },
    {}, {},
  );
  is(scalar @ops, 1, 'unprescribed size still yields one alter op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(64) NOT NULL;',
    'an unprescribed size falls back to the live width');
}
{
  # An unprescribed data_type keeps the live type, for the same reason.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1) ] },
    { t => [ { %{ col('name', size => 128, not_null => 1) },
               data_type => undef } ] },
    {}, {},
  );
  is(scalar @ops, 1, 'unprescribed data_type still yields one alter op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(128) NOT NULL;',
    'an unprescribed data_type falls back to the live type');
}
{
  # A target that DOES prescribe nullable gets it: the fallback is for an
  # absent field, not a licence to ignore a stated one.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1) ] },
    { t => [ col('name', type => 'varchar', size => 64, not_null => 0) ] },
    {}, {},
  );
  is(scalar @ops, 1, 'a prescribed nullability yields one alter op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(64) NULL;',
    'a target prescribing nullable drops the NOT NULL explicitly');
}
{
  # Unchanged nullability is still written out. There is no "leave it as it
  # is" in this grammar, so a size-only change on a nullable column has to say
  # NULL or the database default decides.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64,  not_null => 0) ] },
    { t => [ col('name', type => 'varchar', size => 128, not_null => 0) ] },
    {}, {},
  );
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(128) NULL;',
    'an unchanged nullability is spelled out anyway');
}
{
  # CLAIM REPLACED (karr k38). This line used to assert
  #   "ALTER TABLE t ALTER COLUMN name VARCHAR(64) NOT NULL DEFAULT 'x'"
  # under the description 'a prescribed default is emitted after the
  # nullability'. Two separable things were being claimed there:
  #
  #   (a) a default the TARGET prescribes reaches the emitted SQL at all;
  #   (b) it reaches it as a trailing clause of the column-changing statement,
  #       positioned after the nullability.
  #
  # (a) is KEPT, and is still the only thing that fails here if the default is
  # dropped on the way out. (b) is REPLACED, because it was never true of this
  # dialect: ASE's `modify` production has no `default` in it, and the default
  # of an existing column is changed by the separate `replace column_name
  # default {...}` subclause -- which cannot even share the statement, since a
  # single alter table may combine only add/drop/modify/lock subclauses and
  # only while no column is named twice. So the default is now a SECOND
  # statement, ';'-separated, which is what the apply path splits on and the
  # shape Diff::Index::Alter already emits for its DROP/CREATE pair.
  #
  # CLAIM REPLACED (karr k42), the expected string only. This case is a
  # default-only change (changed_column_fields reports exactly default_value),
  # and on such an alter the MODIFY restated a type and nullability that did
  # not move -- at the price of a data copy. Live on ASE 16.0 SP02 (karr k42)
  # a REPLACE ... DEFAULT takes effect without any preceding MODIFY, so the
  # MODIFY prefix is gone from the expectation. Claim (a) above is untouched:
  # the prescribed default still reaches the SQL, as a REPLACE statement, and
  # this line still fails if it is dropped on the way out.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1) ] },
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1,
                 default => 'x') ] },
    {}, {},
  );
  is($ops[0]->as_sql,
    "ALTER TABLE t REPLACE name DEFAULT 'x';",
    'a prescribed default becomes a REPLACE statement');
}
{
  # The REPLACE carries the TARGET's value, not the live one. Without this the
  # previous case would still pass if the emitter read the wrong side -- there
  # the live column simply had no default to read.
  #
  # CLAIM REPLACED (karr k42), the expected string only: a default-only change
  # no longer drags a MODIFY in front of it (see the previous case). The claim
  # -- the replace names the target value 'new', not the live 'old' -- is
  # sampled exactly as before.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1,
                 default => 'old') ] },
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1,
                 default => 'new') ] },
    {}, {},
  );
  is($ops[0]->as_sql,
    "ALTER TABLE t REPLACE name DEFAULT 'new';",
    'a changed default replaces with the target value');
}
{
  # A default-only change emits NO modify (karr k42). The modify would restate
  # a type, width and nullability the comparator found unmoved, and it is not
  # free: "A data copy is required ... for most alter table ... modify
  # commands". Live on ASE 16.0 SP02 the replace alone changes the default, so
  # nothing is lost by leaving the modify out. The summary names the statement
  # the migration actually leads with.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1,
                 default => 'old') ] },
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1,
                 default => 'new') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'a default-only change is one alter op');
  unlike($ops[0]->as_sql, qr/\bMODIFY\b/,
    'a default-only change emits no MODIFY');
  is($ops[0]->summary, 'ALTER TABLE t REPLACE name',
    'a default-only summary names the REPLACE it leads with');
}
{
  # The suppression is for default-ONLY changes. A type change beside a
  # default change still needs its modify, followed by the replace as a
  # second statement -- a predicate that looked only at "did the default
  # move" would drop the widening here.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64,  not_null => 1,
                 default => 'old') ] },
    { t => [ col('name', type => 'varchar', size => 128, not_null => 1,
                 default => 'new') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'a size and default change is one alter op');
  # RESPELLED (karr k49): both statements now carry their own terminator, the
  # REPLACE included -- the claim (MODIFY first, then the REPLACE naming the
  # target value, as two statements) is unchanged.
  is($ops[0]->as_sql,
    "ALTER TABLE t MODIFY name VARCHAR(128) NOT NULL;"
      . " ALTER TABLE t REPLACE name DEFAULT 'new';",
    'a size change beside a default change keeps MODIFY, then REPLACE');
  is($ops[0]->summary, 'ALTER TABLE t MODIFY name',
    'and its summary still names the MODIFY it leads with');
}
{
  # And the other way round: a nullability-only change on a defaulted column
  # is a modify with no replace. The default is prescribed on both sides but
  # unchanged, so restating it would risk the sp_bindefault refusal below.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1,
                 default => 'x') ] },
    { t => [ col('name', type => 'varchar', size => 64, not_null => 0,
                 default => 'x') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'a nullability-only change is one alter op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(64) NULL;',
    'a nullability-only change is a MODIFY without REPLACE');
}
{
  # An UNCHANGED default emits no second statement, and that is a correctness
  # requirement rather than tidiness: on a column whose default was bound with
  # sp_bindefault, ASE refuses the replace outright ("You cannot replace a
  # user-defined default bound to the column with sp_bindefault"). A driver
  # that restated every default would turn a migration that had nothing to do
  # on that column into a failing one.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64,  not_null => 1,
                 default => 'x') ] },
    { t => [ col('name', type => 'varchar', size => 128, not_null => 1,
                 default => 'x') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'a size change beside an unchanged default is one op');
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(128) NOT NULL;',
    'an unchanged default emits no REPLACE');
  # RESPELLED (karr k49). This used to read "no ; at all", which sampled the
  # separator as a stand-in for "a second statement". Since every statement
  # ends in ; the character is present on a one-statement op too, so the claim
  # is now asked directly: the op falls apart into exactly one statement on
  # the split the apply path uses.
  is(scalar(my @stmts = DBIO::SQL::Util::_split_statements($ops[0]->as_sql)), 1,
    'and therefore no second statement at all');
}
{
  # CLAIM REPLACED (karr k48). This block used to pin that two SCALAR refs
  # holding the same expression "still compare as changed" -- core's comparator
  # stringifies default_value, so two refs differ by address -- and that the op
  # then fell back to a redundant MODIFY, kept on purpose. That was harmless
  # while no introspected model carried a ref. Since k48 the catalog fetch
  # reads every expression default (`DEFAULT getdate()`) as a SCALAR ref, on
  # the live side and on the temp-database side alike, so the "kept" MODIFY
  # became a change reported for every such column on every diff: a deployment
  # never converged against itself. diff() now compares the SQL behind the ref.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('created', type => 'datetime', not_null => 1,
                 default => \'getdate()') ] },
    { t => [ col('created', type => 'datetime', not_null => 1,
                 default => \'getdate()') ] },
    {}, {},
  );
  is(scalar @ops, 0, 'two equal expression defaults are no change');

  # ... while a different expression is still one, rendered as the REPLACE.
  @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('created', type => 'datetime', not_null => 1,
                 default => \'getdate()') ] },
    { t => [ col('created', type => 'datetime', not_null => 1,
                 default => \'getutcdate()') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'a different expression default is a change');
  is($ops[0]->as_sql, 'ALTER TABLE t REPLACE created DEFAULT getutcdate();',
    'rendered as the REPLACE alone');

  # ... and an expression never equals the literal of the same text where one
  # renders unquoted and the other quoted.
  #
  # CLAIM REPLACED (karr k55): this sampled the claim on an INTEGER column. The
  # claim's own reason -- "one renders unquoted, the other quoted" -- no longer
  # holds there: a numeric column's literal 0 now renders DEFAULT 0, exactly
  # like \'0', and the catalog reads that text back as the literal, so the two
  # are the same default (pinned as no change in the k55 block above). The
  # claim is sampled where its reason still holds, a character column.
  @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('n', type => 'varchar', size => 8, not_null => 1, default => '0') ] },
    { t => [ col('n', type => 'varchar', size => 8, not_null => 1, default => \'0') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'literal 0 vs expression 0 is still a change');
}
{
  # The literal 'null' renders as no clause at all (sybase_default_clause),
  # so it prescribes nothing to replace with -- the same rendered-clause rule
  # the not-null ADD refusal above is built on. Dropping a default is not
  # expressible here in any case: core's comparator skips an undef
  # default_value on the target, so the drift never reaches this class.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1) ] },
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1,
                 default => 'null') ] },
    {}, {},
  );
  # Same karr k42 fallback as the previous case: default-only by the
  # comparator, nothing rendered to replace with, so the modify stays.
  is($ops[0]->as_sql, 'ALTER TABLE t MODIFY name VARCHAR(64) NOT NULL;',
    "a 'null' default renders no clause, so no REPLACE is emitted");
  is($ops[0]->summary, 'ALTER TABLE t MODIFY name',
    "and the summary of that fallback names the MODIFY");
}
{
  # Claim unchanged, keyword respelled (karr k38): the live default is not
  # restated when the target prescribes none. Under the old spelling that
  # meant "no DEFAULT clause on the statement"; it now means the stronger
  # "no second statement", which is the same property read in the new shape.
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('name', type => 'varchar', size => 64, not_null => 1,
                 default => 'live') ] },
    { t => [ col('name', type => 'varchar', size => 128, not_null => 1) ] },
    {}, {},
  );
  # CLAIM REPLACED (karr k97, core karr k367): "the target prescribes none"
  # no longer leaves the live default standing. Core's comparator now reports a
  # default the target dropped, and the op removes it: a second statement,
  # `REPLACE name DEFAULT NULL`. The part of the claim that holds is that the
  # live default is not restated -- 'live' is in no statement.
  is($ops[0]->as_sql,
    'ALTER TABLE t MODIFY name VARCHAR(128) NOT NULL; ALTER TABLE t REPLACE name DEFAULT NULL;',
    'the live default is removed, not restated, when the target prescribes none');
  unlike($ops[0]->as_sql, qr/live/, '... and it is named in no statement');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { t => [ col('id'), col('old', type => 'varchar') ] },
    { t => [ col('id') ] },
    {}, {},
  );
  is(scalar @ops, 1, 'one drop op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Column::Drop');
  # RESPELLED (karr k41): the keyword is gone, the claim is not. This line was
  # written to sample that a drop names the TABLE it alters and the COLUMN it
  # removes -- `t` and `old`, both byte for byte what they were, and both still
  # what fails here if the op stops carrying them. Only the frame moved, from
  # Transact-SQL's DROP COLUMN, which parses on no ASE, to the drop production
  # the Reference Manual publishes, whose column arm carries no keyword at all
  # (the constraint arm does -- see Diff::ForeignKey::Drop). The claim is now
  # measured against grammar a server could accept.
  is($ops[0]->as_sql,  'ALTER TABLE t DROP old;', 'drop column SQL');
  # The two methods now render the same string, and that is the finding, not a
  # weakening: they always described one statement and disagreed on how to
  # spell it. They remain separate assertions on separate methods, so either
  # one regressing still fails here.
  is($ops[0]->summary, 'ALTER TABLE t DROP old', 'drop column summary');
}

# --- Diff::Index create ---
{
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { t => {} },
    { t => { idx_name => idx('idx_name', columns => ['name']) } },
  );
  is(scalar @ops, 1, 'one index create op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Index::Create');
  is($ops[0]->as_sql, 'CREATE INDEX idx_name ON t (name);', 'create index SQL');
}

# --- Diff::Index create unique ---
{
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { t => {} },
    { t => { uq => idx('uq', unique => 1, columns => ['a', 'b']) } },
  );
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX uq ON t (a, b);', 'create unique index SQL');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::Sybase::Diff::Index->diff(
    { t => { stale => idx('stale', columns => ['x']) } },
    { t => {} },
  );
  is(scalar @ops, 1, 'one index drop op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::Index::Drop');
  is($ops[0]->as_sql, 'DROP INDEX t.stale;', 'drop index SQL');
}

# --- Diff::ForeignKey add (constraint new on a retained table) ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
  );
  is(scalar @ops, 1, 'one fk add op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Create');
  like($ops[0]->as_sql,
    qr/ALTER TABLE "?book"? ADD CONSTRAINT "?fk_book_author_id"? FOREIGN KEY \("?author_id"?\) REFERENCES "?author"? \("?id"?\)/,
    'fk add SQL');
  is($ops[0]->summary, 'ADD FK fk_book_author_id ON book', 'fk add summary');
}

# --- Diff::ForeignKey add with ON DELETE/UPDATE actions ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'CASCADE', on_update => 'SET NULL') ] },
  );
  # CLAIM REPLACED (karr k91): this asserted ON UPDATE / ON DELETE written.
  # ASE refuses every such clause (Msg 156), so the op refuses to render it.
  like(exception { $ops[0]->as_sql }, qr/ON UPDATE SET NULL.*no referential actions/s,
    'on update other than NO ACTION is refused, not emitted');
}

# --- Diff::ForeignKey: NO ACTION is the default → not emitted ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'NO ACTION', on_update => 'NO ACTION') ] },
  );
  unlike($ops[0]->as_sql, qr/ON (UPDATE|DELETE)/, 'NO ACTION not emitted');
}

# --- Diff::ForeignKey drop (constraint gone from a retained table) ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
    { book => [] },
  );
  is(scalar @ops, 1, 'one fk drop op');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Drop');
  is($ops[0]->as_sql,
    'ALTER TABLE book DROP CONSTRAINT fk_book_author_id;', 'fk drop SQL');
  is($ops[0]->summary, 'DROP FK fk_book_author_id ON book', 'fk drop summary');
}

# --- Diff::ForeignKey alter (ON DELETE change) → drop+create ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'NO ACTION') ] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'CASCADE') ] },
  );
  is(scalar @ops, 2, 'alter yields drop+create pair');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Drop',   'first is drop');
  isa_ok($ops[1], 'DBIO::Sybase::Diff::ForeignKey::Create', 'second is create');
  like($ops[0]->as_sql, qr/DROP CONSTRAINT "?fk_book_author_id"?/, 'alter drops old');
  # CLAIM REPLACED (karr k91): the create half used to carry ON DELETE CASCADE.
  like(exception { $ops[1]->as_sql }, qr/ON DELETE CASCADE.*no referential actions/s,
    'alter to an action ASE does not have is refused when rendered');
}

# --- Diff::ForeignKey: identical FK on both sides → no op ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
  );
  is(scalar @ops, 0, 'unchanged FK yields no op');
}

# --- Diff::ForeignKey drop uses the live constraint_name when source carries it ---
# The source (introspected) model carries the real server-assigned name; the
# DROP must target that name, not the generated fk_<table>_<cols> form.
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fkn('fk_oddname_xyz',
                    from => ['author_id'], to_table => 'author', to => ['id']) ] },
    { book => [] },
  );
  is(scalar @ops, 1, 'one fk drop op (named source)');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Drop');
  is($ops[0]->as_sql,
    'ALTER TABLE book DROP CONSTRAINT fk_oddname_xyz;',
    'fk drop uses real source constraint name');
  is($ops[0]->summary, 'DROP FK fk_oddname_xyz ON book',
    'fk drop summary uses real source constraint name');
}

# --- Diff::ForeignKey drop falls back to generated name when source unnamed ---
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
    { book => [] },
  );
  is($ops[0]->as_sql,
    'ALTER TABLE book DROP CONSTRAINT fk_book_author_id;',
    'fk drop falls back to generated name when source has no constraint_name');
}

# --- Diff::ForeignKey alter: drop-half uses real source name, create-half generates ---
# Asymmetry: the live source entry carries a real name; the desired/target
# entry (built from a schema definition) does not. The drop must target the
# real name; the recreate uses the deterministic generated name.
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fkn('fk_oddname_xyz',
                    from => ['author_id'], to_table => 'author', to => ['id'],
                    on_delete => 'CASCADE') ] },
    { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id'],
                   on_delete => 'NO ACTION') ] },
  );
  is(scalar @ops, 2, 'named alter yields drop+create pair');
  isa_ok($ops[0], 'DBIO::Sybase::Diff::ForeignKey::Drop',   'first is drop');
  isa_ok($ops[1], 'DBIO::Sybase::Diff::ForeignKey::Create', 'second is create');
  like($ops[0]->as_sql, qr/DROP CONSTRAINT "?fk_oddname_xyz"?/,
    'alter drops the real source constraint name');
  like($ops[1]->as_sql, qr/ADD CONSTRAINT "?fk_book_author_id"?/,
    'alter recreates under the generated name');
  # k91: the old side (a hand-built model; the live one is always NO ACTION)
  # differs, so a pair is made; the create half targets NO ACTION and renders.
}

# --- Diff::ForeignKey: FK on a table absent from source ---
# CLAIM REPLACED (karr k54): this asserted that an FK of a brand-new table is
# not emitted here, on the grounds that "a brand-new table carries its own
# FKs". It never did -- Diff::Table::Create renders no FK -- so upgrade()
# created the table without them. With the table models (as Diff passes them)
# the new table's FKs are ADD CONSTRAINTs, run after every CREATE TABLE.
# Without table models (FK models alone cannot tell a new table from one that
# merely has no FK yet) the old skip stands.
{
  my @ops = DBIO::Sybase::Diff::ForeignKey->diff(
    {},
    { fresh => [ fk(from => ['x'], to_table => 'other', to => ['id']) ] },
    { other => tbl('other') },
    { other => tbl('other'), fresh => tbl('fresh') },
  );
  is(scalar @ops, 1, 'FK on new table is emitted given the table models');
  is($ops[0]->as_sql,
    'ALTER TABLE fresh ADD CONSTRAINT fk_fresh_x FOREIGN KEY (x) REFERENCES other (id);',
    '... as an ADD CONSTRAINT under the generated name');
  is(scalar DBIO::Sybase::Diff::ForeignKey->diff(
    {}, { fresh => [ fk(from => ['x'], to_table => 'other', to => ['id']) ] },
  ), 0, 'without table models a table missing from the source FK model is skipped');
}

# --- Diff::ForeignKey: first FK added / last FK dropped on a retained table ---
# An FK model lists only tables that have FKs; a retained table absent from
# one side has none there (karr k54). Before, both cases diffed empty.
{
  my $tables = { book => tbl('book'), author => tbl('author') };
  my @add = DBIO::Sybase::Diff::ForeignKey->diff(
    {}, { book => [ fk(from => ['author_id'], to_table => 'author', to => ['id']) ] },
    $tables, $tables,
  );
  is(scalar @add, 1, 'first FK on a retained table is added');
  is($add[0]->action, 'create', '... as a create');
  my @drop = DBIO::Sybase::Diff::ForeignKey->diff(
    { book => [ fkn('book_fk_1', from => ['author_id'], to_table => 'author', to => ['id']) ] }, {},
    $tables, $tables,
  );
  is(scalar @drop, 1, 'last FK on a retained table is dropped');
  is($drop[0]->as_sql, 'ALTER TABLE book DROP CONSTRAINT book_fk_1;', '... by its live name');
}

# --- Full Diff orchestrator end-to-end ---
{
  my $source = {
    tables       => { keep => tbl('keep'), drop_me => tbl('drop_me') },
    columns      => { keep => [ col('id'), col('gone', type => 'varchar') ],
                      drop_me => [ col('id') ] },
    indexes      => { keep => {} },
    # keep has a stale FK that must be dropped; drop_me's FK vanishes with it.
    foreign_keys => { keep => [ fk(from => ['gone'], to_table => 'other', to => ['id']) ] },
  };
  my $target = {
    tables       => { keep => tbl('keep'), fresh => tbl('fresh') },
    columns      => { keep => [ col('id'), col('added', type => 'varchar') ],
                      fresh => [ col('id', not_null => 1, is_pk => 1) ] },
    indexes      => { keep => { ix => idx('ix', columns => ['added']) } },
    # keep gains a new FK that must be added after the column it references.
    foreign_keys => { keep => [ fk(from => ['added'], to_table => 'other', to => ['id']) ] },
  };
  my $diff = DBIO::Sybase::Diff->new(source => $source, target => $target);
  ok($diff->has_changes, 'orchestrator sees changes');

  my $sql     = $diff->as_sql;
  my $summary = $diff->summary;

  like($sql, qr/CREATE TABLE "?fresh"?/,    'creates new table');
  like($sql, qr/DROP TABLE drop_me/,        'drops removed table');
  like($sql, qr/ALTER TABLE keep ADD added/, 'adds new column');
  # Same claim as before, respelled for the drop production (karr k41): the
  # end-to-end migration must contain a statement removing `gone` from `keep`.
  # The pattern is anchored on the whole statement rather than shortened to
  # /DROP gone/, so it cannot start matching inside the FK drop that names the
  # same column (ALTER TABLE keep DROP CONSTRAINT "fk_keep_gone").
  like($sql, qr/ALTER TABLE keep DROP gone/, 'drops removed column');
  like($sql, qr/CREATE INDEX ix ON keep/,   'creates new index');
  like($sql, qr/DROP CONSTRAINT "?fk_keep_gone"?/, 'drops stale FK');
  like($sql, qr/ADD CONSTRAINT "?fk_keep_added"?/, 'adds new FK');

  # Dependency ordering: FK drop precedes the table/column drops it could block,
  # and the FK add lands after the tables/columns it references.
  # Claim unchanged (karr k41): the FK drop is emitted before the column drop
  # it would otherwise block. The needle is the full statement -- the same
  # shape the column-add ordering check below uses -- and not the shortened
  # 'DROP gone', which would be a different search string against a migration
  # that mentions `gone` twice.
  ok(index($sql, 'DROP CONSTRAINT') < index($sql, 'ALTER TABLE keep DROP gone'),
    'FK drop precedes column drop');
  ok(index($sql, 'DROP CONSTRAINT') < index($sql, 'DROP TABLE drop_me'),
    'FK drop precedes table drop');
  ok(index($sql, 'ADD CONSTRAINT') > index($sql, 'ALTER TABLE keep ADD added'),
    'FK add follows column add');
  ok(index($sql, 'ADD CONSTRAINT') > index($sql, 'CREATE TABLE'),
    'FK add follows table create');

  # Regression guards against the historical bugs in this triad:
  unlike($sql, qr/TODO/,        'no TODO placeholder leaks into migration');
  unlike($sql, qr/\{UNIQUE|\{\}INDEX|\$unique/, 'no literal-brace index bug');
  unlike($sql, qr/\bHASH\(0x/,  'no stringified hashref leaks (constructor bug)');
  like($summary, qr/CREATE TABLE fresh/,    'summary mentions new table');

  # `fresh` is created by this same diff, so its columns are already inside the
  # CREATE TABLE. Adding them again emitted a duplicate-column statement ASE
  # rejects outright -- and it stayed invisible for as long as an ADD rendered
  # something that merely looked like SQL. Surfaced while preparing the k39
  # add fix: fresh.id is not_null with no default, which is legal in a CREATE
  # TABLE and impossible in an ADD.
  unlike($sql, qr/ALTER \s+ TABLE \s+ fresh \s+ ADD/x,
    'columns of a newly created table are not added a second time');
  like($sql, qr/CREATE \s+ TABLE \s+ "?fresh"? .* \bid\b/xs,
    '... because the CREATE TABLE already carries them');
}

# --- Index drops precede the column drop they would otherwise block (karr k43) ---
# ASE refuses to drop a column while an index still references it, so a diff that
# removes an indexed column of a RETAINED table must emit DROP INDEX before the
# ALTER TABLE ... DROP of the column. The table stays in the target (it is not a
# whole-table drop, whose indexes would cascade with DROP TABLE); only the column
# and its index go. The index model keeps `t => {}` in the target so the drop is
# actually generated (Diff::Index iterates target tables).
{
  my $source = {
    tables       => { t => tbl('t') },
    columns      => { t => [ col('id'), col('x', type => 'varchar') ] },
    indexes      => { t => { ix_x => idx('ix_x', columns => ['x']) } },
    foreign_keys => {},
  };
  my $target = {
    tables       => { t => tbl('t') },
    columns      => { t => [ col('id') ] },
    indexes      => { t => {} },
    foreign_keys => {},
  };
  my $diff = DBIO::Sybase::Diff->new(source => $source, target => $target);
  my $sql  = $diff->as_sql;

  like($sql, qr/DROP INDEX t\.ix_x/,      'index drop emitted');
  like($sql, qr/ALTER TABLE t DROP x/,    'column drop emitted');
  ok(index($sql, 'DROP INDEX') < index($sql, 'ALTER TABLE t DROP x'),
    'index drop precedes the column drop it would block');
}

# --- Index create/alter stay AFTER the column diff (karr k43) ---
# The property the fix must NOT break: a new/changed column must exist before an
# index can reference it, so index CREATE keeps landing after ALTER TABLE ... ADD.
# Only index DROPs move ahead of the column diff; CREATE/ALTER do not.
{
  my $source = {
    tables       => { t => tbl('t') },
    columns      => { t => [ col('id') ] },
    indexes      => { t => {} },
    foreign_keys => {},
  };
  my $target = {
    tables       => { t => tbl('t') },
    columns      => { t => [ col('id'), col('y', type => 'varchar') ] },
    indexes      => { t => { ix_y => idx('ix_y', columns => ['y']) } },
    foreign_keys => {},
  };
  my $diff = DBIO::Sybase::Diff->new(source => $source, target => $target);
  my $sql  = $diff->as_sql;

  like($sql, qr/CREATE INDEX ix_y ON t/,  'index create emitted');
  like($sql, qr/ALTER TABLE t ADD y/,     'column add emitted');
  ok(index($sql, 'CREATE INDEX ix_y') > index($sql, 'ALTER TABLE t ADD y'),
    'index create follows the column add it references');
}

done_testing;
