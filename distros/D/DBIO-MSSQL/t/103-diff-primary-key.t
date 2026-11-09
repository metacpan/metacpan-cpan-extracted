use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Diff;
use DBIO::MSSQL::DDL ();

# karr k74. A table that exists without a primary key, or with another one,
# gets the key of the classes in the upgrade. The server's answer to each
# statement and order is measured in t/104-diff-primary-key-live.t (2026-10-20,
# MSSQL 2022):
#   - ADD PRIMARY KEY on a nullable column fails -> NOT NULL (phase 4) first;
#   - a second PRIMARY KEY on a table fails -> drop, then add;
#   - DROP of a key that a foreign key references fails -> those keys are
#     dropped before and added again after;
#   - ALTER COLUMN to another type fails on a key column (a width change does
#     not) -> the key is dropped before the column phase, added after it.
# This file pins the statements and their order.

sub tbl { +{ map { $_ => { table_name => $_, kind => 'table' } } @_ } }
# column spec: name, or [name, pk_position, extra...]
sub cols {
  return [ map {
    my ($n, $pos, %x) = ref $_ ? @$_ : ($_, 0);
    +{ column_name => $n, data_type => 'int', not_null => $pos ? 1 : 0,
       is_pk => $pos ? 1 : 0, pk_position => $pos, %x }
  } @_ ];
}
sub stmts {
  my ($src, $tgt) = @_;
  my $d = DBIO::MSSQL::Diff->new(source => $src, target => $tgt);
  return grep { length } map { split /\n(?=\S)/, $_->as_sql } @{ $d->operations };
}
sub model {
  my (%m) = @_;
  return { tables => tbl(keys %{ $m{columns} }), indexes => {}, foreign_keys => {}, %m };
}
sub pos_of {
  my ($re, @s) = @_;
  for my $i (0 .. $#s) { return $i if $s[$i] =~ $re }
  return -1;
}
sub before_ok {
  my ($a, $b, $s, $name) = @_;
  my ($pa, $pb) = (pos_of($a, @$s), pos_of($b, @$s));
  ok($pa >= 0 && $pb >= 0 && $pa < $pb, $name) or diag join "\n", map { "  $_" } @$s;
}

# 1. a table without a key gets one, with the deterministic name
{
  my @s = stmts(
    model(columns => { t => cols('id', 'x') }),
    model(columns => { t => cols(['id', 1], 'x') }),
  );
  my @pk = grep { /PRIMARY KEY/ } @s;
  is scalar(@pk), 1, '1: one statement carries a primary key';
  is $pk[0], 'ALTER TABLE t ADD CONSTRAINT PK_t PRIMARY KEY (id);',
    '1: ALTER TABLE ADD CONSTRAINT PK_<table> PRIMARY KEY (...)';
  is scalar(grep { /DROP CONSTRAINT/ } @s), 0, '1: nothing is dropped';
}

# 2. the key of the classes equals the live one: nothing
{
  my @s = stmts(
    model(columns => { t => cols(['id', 1, pk_constraint_name => 'PK__t__ABC']) }),
    model(columns => { t => cols(['id', 1, pk_constraint_name => 'PK_t']) }),
  );
  is scalar(@s), 0, '2: the same key under another name is no change (names are not compared)';
}

# 3. a composite key in another column order: the order counts
{
  my $src = model(columns => { t => cols(['a', 1, pk_constraint_name => 'PK__t__ABC'], ['b', 2, pk_constraint_name => 'PK__t__ABC']) });
  my $tgt = model(columns => { t => cols(['a', 2], ['b', 1]) });
  my @s = stmts($src, $tgt);
  is_deeply \@s, [
    'ALTER TABLE t DROP CONSTRAINT PK__t__ABC;',
    'ALTER TABLE t ADD CONSTRAINT PK_t PRIMARY KEY (b, a);',
  ], '3: drop the live key by its live name, add it with the columns in pk_position order';
  is scalar(grep { /PRIMARY KEY/ } @s), 1, '3: never two ADD PRIMARY KEY';
}

# 4. another set of columns
{
  my @s = stmts(
    model(columns => { t => cols(['a', 1, pk_constraint_name => 'PK_t'], 'b') }),
    model(columns => { t => cols('a', ['b', 1]) }),
  );
  is_deeply [ grep { /PRIMARY KEY|DROP CONSTRAINT/ } @s ], [
    'ALTER TABLE t DROP CONSTRAINT PK_t;',
    'ALTER TABLE t ADD CONSTRAINT PK_t PRIMARY KEY (b);',
  ], '4: another column: drop then add';
  before_ok qr/DROP CONSTRAINT PK_t/, qr/ADD CONSTRAINT PK_t/, \@s, '4: drop before add';
}

# 5. the target has no key: the live key is dropped (maintainer decision, as
# Sybase does and as undeclared foreign keys are), and the summary says so
{
  my $d = DBIO::MSSQL::Diff->new(
    source => model(columns => { t => cols(['id', 1, pk_constraint_name => 'PK__t__ABC']) }),
    target => model(columns => { t => cols(['id', 0, not_null => 1]) }));
  my @s = grep { length } map { split /\n(?=\S)/, $_->as_sql } @{ $d->operations };
  is_deeply \@s, ['ALTER TABLE t DROP CONSTRAINT PK__t__ABC;'],
    '5: a target without a key drops the live one, and adds none';
  like $d->summary, qr/PRIMARY KEY DROPPED.*\bt\b.*\(id\)/m,
    '5: the summary has a conspicuous line for the drop';
  my $again = DBIO::MSSQL::Diff->new(
    source => model(columns => { t => cols(['id', 0, not_null => 1]) }),
    target => model(columns => { t => cols(['id', 0, not_null => 1]) }));
  ok !$again->has_changes, '5: nothing left to do afterwards';
}

# 5b. a foreign key the classes do not declare: dropped first, then the key
{
  my $fk = { constraint_name => 'FK_c_p', from_columns => ['p'], to_table => 'par',
             to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  my @s = stmts(
    model(columns => { par => cols(['id', 1, pk_constraint_name => 'PK_par']), c => cols('p') },
          foreign_keys => { c => [ $fk ] }),
    model(columns => { par => cols(['id', 0, not_null => 1]), c => cols('p') }));
  is_deeply \@s, [ 'ALTER TABLE c DROP CONSTRAINT FK_c_p;', 'ALTER TABLE par DROP CONSTRAINT PK_par;' ],
    '5b: the undeclared foreign key goes first, then the key; nothing is added';
}

# 5c. a declared foreign key whose target loses its key cannot exist: refused
{
  my $fk = { constraint_name => 'FK_c_p', from_columns => ['p'], to_table => 'par',
             to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  my $d = DBIO::MSSQL::Diff->new(
    source => model(columns => { par => cols(['id', 1, pk_constraint_name => 'PK_par']), c => cols('p') },
                    foreign_keys => { c => [ $fk ] }),
    target => model(columns => { par => cols('id'), c => cols('p') },
                    foreign_keys => { c => [ $fk ] }));
  my $ok = eval { $d->as_sql; 1 };
  ok !$ok, '5c: the key of a table a declared foreign key references is not dropped';
  like $@, qr/par.*FK_c_p|FK_c_p.*par/s, '5c: table and foreign key are named';
  isa_ok $@, 'DBIO::Exception';

  # the declared foreign key can rest on a unique constraint instead
  my $uq = { UQ_par_id => { index_name => 'UQ_par_id', columns => ['id'], is_unique => 1,
                            is_unique_constraint => 1, kind => 'nonclustered' } };
  my @s = stmts(
    model(columns => { par => cols(['id', 1, pk_constraint_name => 'PK_par']), c => cols('p') },
          foreign_keys => { c => [ $fk ] }, indexes => { par => $uq }),
    model(columns => { par => cols('id'), c => cols('p') },
          foreign_keys => { c => [ $fk ] }, indexes => { par => $uq }));
  is scalar(grep { /DROP CONSTRAINT PK_par/ } @s), 1,
    '5c: ... with a unique constraint over the same columns the key is dropped';
  is scalar(grep { /FK_c_p/ } @s), 2, '5c: ... and the foreign key is dropped and added around it';
}

# 6. nullable column becomes the key: NOT NULL first, then the key
{
  my @s = stmts(
    model(columns => { t => cols('id') }),
    model(columns => { t => cols(['id', 1]) }),
  );
  before_ok qr/ALTER COLUMN id int NOT NULL/, qr/ADD CONSTRAINT PK_t PRIMARY KEY/, \@s,
    '6: ALTER COLUMN ... NOT NULL comes before ADD PRIMARY KEY';
}

# 7. a key a foreign key references: the key is dropped and added between them
{
  my $fk = { constraint_name => 'FK_c_p', from_columns => ['p'], to_table => 'par',
             to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  my $src = model(columns => { par => cols(['id', 1, pk_constraint_name => 'PK_par'], 'b'),
                               c   => cols(['id', 1, pk_constraint_name => 'PK_c'], 'p') },
                  foreign_keys => { c => [ $fk ] });
  # the key of par moves from id to b; the foreign key still references par(id),
  # which a unique constraint holds afterwards (without one the model is
  # impossible: the server cannot create the foreign key, see 7c)
  my $uq = { UQ_par_id => { index_name => 'UQ_par_id', columns => ['id'], is_unique => 1,
                            is_unique_constraint => 1, kind => 'nonclustered' } };
  my $tgt = model(columns => { par => cols('id', ['b', 1]),
                               c   => cols(['id', 1], 'p') },
                  foreign_keys => { c => [ { %$fk, to_columns => ['id'] } ] },
                  indexes => { par => $uq });
  my @s = stmts($src, $tgt);
  before_ok qr/DROP CONSTRAINT FK_c_p/, qr/DROP CONSTRAINT PK_par/, \@s,
    '7: the foreign key is dropped before the key it references';
  before_ok qr/ADD CONSTRAINT PK_par PRIMARY KEY \(b\)/, qr/ADD CONSTRAINT FK_c_p FOREIGN KEY/, \@s,
    '7: the key is added before the foreign key';
  is scalar(grep { /FK_c_p/ } @s), 2, '7: the foreign key is dropped once and added once';
  before_ok qr/ADD CONSTRAINT UQ_par_id UNIQUE/, qr/ADD CONSTRAINT FK_c_p FOREIGN KEY/, \@s,
    '7: the unique constraint is there before the foreign key';
}

# 7c. the same without the unique constraint: no key to reference, refused
{
  my $fk = { constraint_name => 'FK_c_p', from_columns => ['p'], to_table => 'par',
             to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  my $d = DBIO::MSSQL::Diff->new(
    source => model(columns => { par => cols(['id', 1, pk_constraint_name => 'PK_par'], 'b'), c => cols('p') },
                    foreign_keys => { c => [ $fk ] }),
    target => model(columns => { par => cols('id', ['b', 1]), c => cols('p') },
                    foreign_keys => { c => [ $fk ] }));
  ok !eval { $d->as_sql; 1 }, '7c: a declared foreign key onto columns that are no key afterwards is refused';
  like $@, qr/par.*FK_c_p|FK_c_p.*par/s, '7c: table and foreign key are named';
}

# 7b. the foreign key is changed by the diff anyway: no second pair
{
  my $fk = { constraint_name => 'FK_c_p', from_columns => ['p'], to_table => 'par',
             to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  my $src = model(columns => { par => cols(['id', 1, pk_constraint_name => 'PK_par'], 'b'),
                               c   => cols('id', 'p') },
                  foreign_keys => { c => [ $fk ] });
  my $uq = { UQ_par_id => { index_name => 'UQ_par_id', columns => ['id'], is_unique => 1,
                            is_unique_constraint => 1, kind => 'nonclustered' } };
  my $tgt = model(columns => { par => cols('id', ['b', 1]), c => cols('id', 'p') },
                  foreign_keys => { c => [ { %$fk, on_delete => 'CASCADE' } ] },
                  indexes => { par => $uq });
  my @s = stmts($src, $tgt);
  is scalar(grep { /FK_c_p/ } @s), 2, '7b: a foreign key that changes anyway is dropped and added once';
}

# 8. a type change of a key column: the key goes around the column phase
{
  my $src = model(columns => { t => [ { column_name => 'id', data_type => 'int', not_null => 1,
      is_pk => 1, pk_position => 1, pk_constraint_name => 'PK_t' } ] });
  my $tgt = model(columns => { t => [ { column_name => 'id', data_type => 'bigint', not_null => 1,
      is_pk => 1, pk_position => 1 } ] });
  my @s = stmts($src, $tgt);
  before_ok qr/DROP CONSTRAINT PK_t/, qr/ALTER COLUMN id bigint/, \@s,
    '8: the key is dropped before ALTER COLUMN of its column';
  before_ok qr/ALTER COLUMN id bigint/, qr/ADD CONSTRAINT PK_t PRIMARY KEY \(id\)/, \@s,
    '8: ... and added after it';
}

# 8b. a width change of a key column is no reason to touch the key (measured)
{
  my $src = model(columns => { t => [ { column_name => 'c', data_type => 'nvarchar', size => 10, not_null => 1,
      is_pk => 1, pk_position => 1, pk_constraint_name => 'PK_t' } ] });
  my $tgt = model(columns => { t => [ { column_name => 'c', data_type => 'nvarchar', size => 20, not_null => 1,
      is_pk => 1, pk_position => 1 } ] });
  my @s = stmts($src, $tgt);
  is scalar(grep { /PRIMARY KEY|DROP CONSTRAINT/ } @s), 0, '8b: a width change leaves the key alone';
  is scalar(grep { /ALTER COLUMN c nvarchar\(20\)/ } @s), 1, '8b: ... and alters the column';
}

# 8c. ... but any retype of a column a foreign key stands on is refused by the
# server while the key stands (Msg "object is dependent on column", measured
# 2026-10-21, both sides, widths included): the foreign key goes around, the
# primary key stays
{
  my $fk = { constraint_name => 'FK_c2_pc', from_columns => ['pc'], to_table => 'par',
             to_columns => ['c'], on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  my $nv = sub { my ($size, %x) = @_; +{ data_type => 'nvarchar', size => $size, not_null => 1, %x } };
  my $src = model(columns => {
      par => [ $nv->(10, column_name => 'c', is_pk => 1, pk_position => 1, pk_constraint_name => 'PK_par') ],
      c2  => [ $nv->(10, column_name => 'pc') ] },
    foreign_keys => { c2 => [ $fk ] });
  my $tgt = model(columns => {
      par => [ $nv->(20, column_name => 'c', is_pk => 1, pk_position => 1) ],
      c2  => [ $nv->(20, column_name => 'pc') ] },
    foreign_keys => { c2 => [ $fk ] });
  my @s = stmts($src, $tgt);
  is scalar(grep { /FK_c2_pc/ } @s), 2, '8c: the foreign key is dropped once and added once';
  is scalar(grep { /PRIMARY KEY|DROP CONSTRAINT PK_par/ } @s), 0, '8c: the primary key stays (a width change)';
  before_ok qr/DROP CONSTRAINT FK_c2_pc/, qr/ALTER TABLE par ALTER COLUMN c nvarchar\(20\)/, \@s,
    '8c: the foreign key is dropped before the referenced column is altered';
  before_ok qr/DROP CONSTRAINT FK_c2_pc/, qr/ALTER TABLE c2 ALTER COLUMN pc nvarchar\(20\)/, \@s,
    '8c: ... and before the child column is altered';
  before_ok qr/ALTER COLUMN pc nvarchar\(20\)/, qr/ADD CONSTRAINT FK_c2_pc FOREIGN KEY/, \@s,
    '8c: ... and added after both';

  # only the child column changes: the foreign key goes around it as well
  my $tgt2 = model(columns => {
      par => $src->{columns}{par}, c2 => [ $nv->(20, column_name => 'pc') ] },
    foreign_keys => { c2 => [ $fk ] });
  my @s2 = stmts($src, $tgt2);
  is scalar(grep { /FK_c2_pc/ } @s2), 2, '8c: a retype of the child column alone takes the foreign key along';

  # a nullability change alone does not (measured: it runs with the key standing)
  my $nn = sub { +{ data_type => 'int', column_name => $_[0], not_null => $_[1] } };
  my @s3 = stmts(
    model(columns => { par => cols(['id', 1, pk_constraint_name => 'PK_par']), c2 => [ $nn->('pc', 0) ] },
          foreign_keys => { c2 => [ { %$fk, from_columns => ['pc'], to_columns => ['id'] } ] }),
    model(columns => { par => cols(['id', 1]), c2 => [ $nn->('pc', 1) ] },
          foreign_keys => { c2 => [ { %$fk, from_columns => ['pc'], to_columns => ['id'] } ] }));
  is scalar(grep { /FK_c2_pc/ } @s3), 0, '8c: NULL to NOT NULL of the child column leaves the foreign key alone';
  is scalar(grep { /ALTER COLUMN pc int NOT NULL/ } @s3), 1, '8c: ... and alters the column';
}

# 8d. one mechanism for every key: a unique constraint a foreign key
# references is dropped around a type change, and the foreign key goes
# around that (measured: UQ and FK dropped, both columns altered, UQ and FK
# created again, in that order, is the only way the server takes)
{
  my $fk = { constraint_name => 'FK_c5_cc', from_columns => ['cc'], to_table => 't5',
             to_columns => ['code'], on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  my $uq = { UQ_t5_code => { index_name => 'UQ_t5_code', columns => ['code'], is_unique => 1,
                             is_unique_constraint => 1, kind => 'nonclustered' } };
  my $col = sub { my ($n, $type, %x) = @_; +{ column_name => $n, data_type => $type, not_null => 1, %x } };
  my $src = model(columns => { t5 => [ $col->('code', 'int') ], c5 => [ $col->('cc', 'int') ] },
                  foreign_keys => { c5 => [ $fk ] }, indexes => { t5 => $uq });
  my $tgt = model(columns => { t5 => [ $col->('code', 'bigint') ], c5 => [ $col->('cc', 'bigint') ] },
                  foreign_keys => { c5 => [ $fk ] }, indexes => { t5 => $uq });
  my @s = stmts($src, $tgt);
  is scalar(grep { /FK_c5_cc/ } @s), 2, '8d: the foreign key is dropped once and added once';
  is scalar(grep { /UQ_t5_code/ } @s), 2, '8d: the unique constraint is dropped once and added once';
  before_ok qr/DROP CONSTRAINT FK_c5_cc/, qr/DROP CONSTRAINT UQ_t5_code/, \@s,
    '8d: the foreign key goes before the unique constraint it references';
  before_ok qr/DROP CONSTRAINT UQ_t5_code/, qr/ALTER TABLE t5 ALTER COLUMN code bigint/, \@s,
    '8d: the unique constraint goes before its column is altered';
  before_ok qr/ALTER TABLE c5 ALTER COLUMN cc bigint/, qr/ADD CONSTRAINT UQ_t5_code UNIQUE/, \@s,
    '8d: ... and comes back after the column phase';
  before_ok qr/ADD CONSTRAINT UQ_t5_code UNIQUE/, qr/ADD CONSTRAINT FK_c5_cc FOREIGN KEY/, \@s,
    '8d: ... before the foreign key that references it';

  # the unique key is dropped for good: a declared foreign key onto it is refused
  my $d = DBIO::MSSQL::Diff->new(
    source => $src,
    target => model(columns => $src->{columns}, foreign_keys => { c5 => [ $fk ] }));
  ok !eval { $d->as_sql; 1 }, '8d: a unique key dropped for good under a declared foreign key is refused';
  like $@, qr/t5.*FK_c5_cc|FK_c5_cc.*t5/s, '8d: table and foreign key are named';
}

# 9. a new table carries the named key in its CREATE TABLE, no extra ADD
{
  my @s = stmts(model(columns => {}), model(columns => { t => cols(['id', 1]) }));
  my $all = join "\n", @s;
  is scalar(grep { /^CREATE TABLE/ } @s), 1, '9: one CREATE TABLE for a new table';
  is scalar(grep { /^ALTER TABLE/ } @s), 0, '9: ... and no ALTER TABLE';
  like $all, qr/CONSTRAINT PK_t PRIMARY KEY \(id\)/,
    '9: CREATE TABLE names the key PK_<table>';
}

# 10. a live key whose name is unknown cannot be dropped: refused
{
  my $d = DBIO::MSSQL::Diff->new(
    source => model(columns => { t => cols(['a', 1]) }),
    target => model(columns => { t => cols('a', ['b', 1]) }));
  my $ok = eval { $d->as_sql; 1 };
  ok !$ok, '10: no live key name, no DROP CONSTRAINT';
  like $@, qr/primary key.*(name|pk_constraint_name)/is, '10: ... and the message says why';
}

# 11. a key name that is the name of a table is refused (one namespace, Msg 2714)
{
  my $d = DBIO::MSSQL::Diff->new(
    source => model(columns => { PK_t => cols('id'), t => cols('id') }),
    target => model(columns => { PK_t => cols('id'), t => cols(['id', 1]) }));
  my $ok = eval { $d->as_sql; 1 };
  ok !$ok, '11: PK_t is also a table';
  like $@, qr/PK_t.*(table|object)/is, '11: ... named in the message';
}

# 12. install_ddl names the key the way the diff does
{
  package K74::Schema; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL');
  package K74::Schema::Result::Thing; use base 'DBIO::Core';
  __PACKAGE__->table('thing');
  __PACKAGE__->add_columns(a => { data_type => 'integer' }, b => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('b', 'a');
}
K74::Schema->register_class(Thing => 'K74::Schema::Result::Thing');
my $ddl = DBIO::MSSQL::DDL->install_ddl('K74::Schema');
like $ddl, qr/CONSTRAINT PK_thing PRIMARY KEY \(b, a\)/,
  '12: install_ddl writes CONSTRAINT PK_<table> PRIMARY KEY in key order';

# 13. CLUSTERED or NONCLUSTERED counts (karr k74, measured live in t/104): the
# classes create the key clustered, a live key that is not is replaced, and
# the added key says CLUSTERED out loud
{
  my $live = sub { cols(['id', 1, pk_constraint_name => 'PK_live', pk_clustered => $_[0]], 'x') };
  my $want = sub { cols(['id', 1, pk_clustered => $_[0]], 'x') };
  my @s = stmts(model(columns => { t => $live->(0) }), model(columns => { t => $want->(1) }));
  is_deeply \@s, [
    'ALTER TABLE t DROP CONSTRAINT PK_live;',
    'ALTER TABLE t ADD CONSTRAINT PK_t PRIMARY KEY CLUSTERED (id);',
  ], '13a: a nonclustered live key is replaced by a clustered one';
  is scalar(stmts(model(columns => { t => $live->(1) }), model(columns => { t => $want->(1) }))), 0,
    '13b: clustered against clustered is no change';
  is scalar(stmts(model(columns => { t => $live->(0) }), model(columns => { t => $want->(0) }))), 0,
    '13c: nonclustered against nonclustered is no change (a model that asks for it)';
  is scalar(stmts(model(columns => { t => cols(['id', 1, pk_constraint_name => 'PK_live'], 'x') }),
                  model(columns => { t => $want->(1) }))), 0,
    '13d: a model that does not know the kind is not compared';

  # with a foreign key onto the key: dropped before, added again after
  my $fk = { constraint_name => 'FK_c_p', from_columns => ['p'], to_table => 't',
             to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION' };
  my @f = stmts(
    model(columns => { t => $live->(0), c => cols('p') }, foreign_keys => { c => [ $fk ] }),
    model(columns => { t => $want->(1), c => cols('p') }, foreign_keys => { c => [ $fk ] }));
  is scalar(grep { /FK_c_p/ } @f), 2, '13e: the foreign key is dropped and added once each';
  before_ok qr/DROP CONSTRAINT FK_c_p/, qr/DROP CONSTRAINT PK_live/, \@f, '13e: foreign key goes before the key';
  before_ok qr/ADD CONSTRAINT PK_t PRIMARY KEY CLUSTERED/, qr/ADD CONSTRAINT FK_c_p/, \@f,
    '13e: ... and comes back after it';

  # a clustered live index beside the nonclustered key is dropped before the
  # key is added, and comes back nonclustered after it (the target has none
  # clustered: Msg 1902)
  my $ix = sub { +{ ix => { index_name => 'ix', columns => ['x'], is_unique => 0,
                            is_unique_constraint => 0, kind => $_[0] } } };
  my @i = stmts(
    model(columns => { t => $live->(0) }, indexes => { t => $ix->('clustered') }),
    model(columns => { t => $want->(1) }, indexes => { t => $ix->('nonclustered') }));
  before_ok qr/DROP INDEX ix/, qr/ADD CONSTRAINT PK_t PRIMARY KEY CLUSTERED/, \@i,
    '13f: the clustered index goes before the clustered key is added';
  before_ok qr/ADD CONSTRAINT PK_t PRIMARY KEY CLUSTERED/, qr/CREATE NONCLUSTERED INDEX ix/, \@i,
    '13f: ... and returns nonclustered after it';
}

done_testing;
