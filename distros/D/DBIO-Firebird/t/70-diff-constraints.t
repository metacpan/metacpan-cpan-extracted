use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Diff;

# Offline (karr k34): foreign keys and unique constraints in the diff.
#
# The target model is the temp database the schema is installed into, so it
# holds every constraint install_ddl wrote. Two cases:
#
#   * a table that is NEW: its constraints are ALTER TABLE ... ADD CONSTRAINT
#     after every CREATE TABLE of the diff (unique constraints before foreign
#     keys), and the CREATE TABLE has no foreign key inline;
#   * a table that exists on both sides with other constraints (karr k62): the
#     diff writes DROP CONSTRAINT / ADD CONSTRAINT, a changed one as both, in
#     the order foreign keys to drop, tables, keys to drop, columns, keys to
#     add, foreign keys to add -- it no longer refuses.

sub col { return { column_name => $_[0], data_type => 'integer', size => undef, not_null => 0, default_value => undef, is_pk => 0 } }
sub fk {
  my (%a) = @_;
  return { constraint_name => "$a{from}_$a{cols}[0]_fk", from_table => $a{from}, from_columns => $a{cols},
           to_table => $a{to}, to_columns => $a{to_cols} // ['id'],
           on_update => $a{on_update} // 'RESTRICT', on_delete => $a{on_delete} // 'RESTRICT', match => 'FULL' };
}
sub model {
  my (%m) = @_;
  my %cols = %{ $m{columns} };
  return {
    tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %cols },
    columns => { map { my $t = $_; $t => [ map { col($_) } @{ $cols{$t} } ] } keys %cols },
    indexes => {}, unique_constraints => $m{uniques} // {}, foreign_keys => $m{fks} // {},
  };
}
sub diff { DBIO::Firebird::Diff->new(source => $_[0], target => $_[1]) }

# --- new tables with a cycle -------------------------------------------------------
{
  my $d = diff(model(columns => {}), model(
    columns => { a => [qw/id b_id/], b => [qw/id a_id code/] },
    fks     => { a => [ fk(from => 'a', cols => ['b_id'], to => 'b') ],
                 b => [ fk(from => 'b', cols => ['a_id'], to => 'a', on_delete => 'CASCADE', on_update => 'NO ACTION') ] },
    uniques => { b => [ [ 'b_code', ['code'] ] ] },
  ));
  my @sql = split /\n/, $d->as_sql;
  my @stmt = grep { /^(?:CREATE|ALTER)/ } @sql;
  is_deeply [ map { /^(CREATE TABLE|ALTER TABLE)/ && $1 } @stmt ],
    ['CREATE TABLE', 'CREATE TABLE', 'ALTER TABLE', 'ALTER TABLE', 'ALTER TABLE'],
    'both tables first, then the constraints';
  like $stmt[2], qr/^ALTER TABLE "b" ADD CONSTRAINT "b_code" UNIQUE \("code"\);$/, 'the unique constraint comes before the keys';
  like $stmt[3], qr/^ALTER TABLE "a" ADD CONSTRAINT "a_b_id_fk" FOREIGN KEY \("b_id"\) REFERENCES "b" \("id"\);$/,
    'a -> b (a clause for no rule: RESTRICT is the default)';
  like $stmt[4], qr/^ALTER TABLE "b" ADD CONSTRAINT "b_a_id_fk" FOREIGN KEY \("a_id"\) REFERENCES "a" \("id"\) ON DELETE CASCADE ON UPDATE NO ACTION;$/,
    'b -> a closes the cycle, with its actions';
  unlike join("\n", @sql[0 .. 8]), qr/FOREIGN KEY/, 'no foreign key inside a CREATE TABLE';
  like $d->summary, qr/\+ foreign key: a\.a_b_id_fk/, 'summary names the key';
  like $d->summary, qr/\+ unique constraint: b\.b_code/, '... and the unique constraint';
}

# --- an existing table, same constraints under other names -> nothing -------------
{
  my $src = model(columns => { t => [qw/id c/], o => ['id'] },
    fks => { t => [ fk(from => 't', cols => ['c'], to => 'o') ] }, uniques => { t => [ [ 'INTEG_7', ['c'] ] ] });
  my $tgt = model(columns => { t => [qw/id c/], o => ['id'] },
    fks => { t => [ { %{ fk(from => 't', cols => ['c'], to => 'o') }, constraint_name => 't_c_fk', on_delete => undef } ] },
    uniques => { t => [ [ 't_c', ['c'] ] ] });
  ok !diff($src, $tgt)->has_changes, 'same constraints under other names, an absent action and RESTRICT: no change';
}

# --- an existing table: added, removed, changed -> written (karr k62) -------------
sub stmts { return [ grep { /^ALTER/ } split /\n/, $_[0]->as_sql ] }
for my $case (
  [ 'a key the database lacks',
    { fks => {} }, { fks => { t => [ fk(from => 't', cols => ['c'], to => 'o') ] } },
    [ 'ALTER TABLE "t" ADD CONSTRAINT "t_c_fk" FOREIGN KEY ("c") REFERENCES "o" ("id");' ] ],
  [ 'a key the schema does not have',
    { fks => { t => [ fk(from => 't', cols => ['c'], to => 'o') ] } }, { fks => {} },
    [ 'ALTER TABLE "t" DROP CONSTRAINT "t_c_fk";' ] ],
  [ 'a key with another action',
    { fks => { t => [ fk(from => 't', cols => ['c'], to => 'o') ] } },
    { fks => { t => [ fk(from => 't', cols => ['c'], to => 'o', on_delete => 'CASCADE') ] } },
    [ 'ALTER TABLE "t" DROP CONSTRAINT "t_c_fk";',
      'ALTER TABLE "t" ADD CONSTRAINT "t_c_fk" FOREIGN KEY ("c") REFERENCES "o" ("id") ON DELETE CASCADE;' ] ],
  [ 'a unique constraint the database lacks',
    { uniques => {} }, { uniques => { t => [ [ 't_c', ['c'] ] ] } },
    [ 'ALTER TABLE "t" ADD CONSTRAINT "t_c" UNIQUE ("c");' ] ],
  [ 'a unique constraint the schema does not have',
    { uniques => { t => [ [ 'u', ['c'] ] ] } }, { uniques => {} },
    [ 'ALTER TABLE "t" DROP CONSTRAINT "u";' ] ],
  [ 'a unique constraint over other columns',
    { uniques => { t => [ [ 'u', ['c'] ] ] } }, { uniques => { t => [ [ 'u', ['c', 'id'] ] ] } },
    [ 'ALTER TABLE "t" DROP CONSTRAINT "u";', 'ALTER TABLE "t" ADD CONSTRAINT "u" UNIQUE ("c", "id");' ] ],
) {
  my ($label, $s, $t, $want) = @$case;
  my $src = model(columns => { t => [qw/id c/], o => ['id'] }, %$s);
  my $tgt = model(columns => { t => [qw/id c/], o => ['id'] }, %$t);
  my $d = diff($src, $tgt);
  ok $d->has_changes, "$label: reported";
  is_deeply stmts($d), $want, '... and written as ALTER TABLE statements, not refused';
}

# --- the order of a whole diff (karr k62) -----------------------------------------------
# foreign keys to drop, tables, keys to drop, columns (drop index with the
# column), keys to add, foreign keys to add.
{
  my $src = model(columns => { t => [qw/id c old/], o => ['id'], gone => ['id'] },
    fks     => { t => [ fk(from => 't', cols => ['c'], to => 'o'), fk(from => 't', cols => ['old'], to => 'gone') ] },
    uniques => { t => [ [ 'u_old', ['old'] ] ] });
  $src->{indexes} = { t => { t_old_idx => { index_name => 't_old_idx', columns => ['old'], is_unique => 0 } } };
  my $tgt = model(columns => { t => [qw/id c new/], o => ['id'], fresh => ['id'] },
    fks     => { t => [ fk(from => 't', cols => ['c'], to => 'o', on_delete => 'CASCADE'), fk(from => 't', cols => ['new'], to => 'fresh') ],
                 fresh => [] },
    uniques => { t => [ [ 'u_new', ['new'] ] ] });
  my @sql = grep { /^(?:ALTER|CREATE|DROP)/ } split /\n/, diff($src, $tgt)->as_sql;
  is_deeply [ map { s/ (?:FOREIGN KEY|UNIQUE|integer|\().*|;$//r } @sql ], [
    'ALTER TABLE "t" DROP CONSTRAINT "t_c_fk"',
    'ALTER TABLE "t" DROP CONSTRAINT "t_old_fk"',
    'CREATE TABLE "fresh"',
    'DROP TABLE "gone"',
    'ALTER TABLE "t" DROP CONSTRAINT "u_old"',
    'DROP INDEX "t_old_idx"',
    'ALTER TABLE "t" ADD "new"',
    'ALTER TABLE "t" DROP "old"',
    'ALTER TABLE "t" ADD CONSTRAINT "u_new"',
    'ALTER TABLE "t" ADD CONSTRAINT "t_c_fk"',
    'ALTER TABLE "t" ADD CONSTRAINT "t_new_fk"',
  ], 'foreign keys out, tables, keys out, index out, columns, keys in, foreign keys in'
    or diag join "\n", @sql;
}

# --- a foreign key that stays under a key that goes (karr k62) ---------------------------
# The server refuses to drop a unique constraint / primary key a foreign key
# points at: that foreign key is dropped before and added after.
{
  my $src = model(columns => { p => [qw/id code/], c => [qw/id pcode/] },
    fks     => { c => [ fk(from => 'c', cols => ['pcode'], to => 'p', to_cols => ['code']) ] },
    uniques => { p => [ [ 'p_code', ['code'] ] ] });
  my $tgt = model(columns => { p => [qw/id code/], c => [qw/id pcode/] },
    fks     => { c => [ fk(from => 'c', cols => ['pcode'], to => 'p', to_cols => ['code']) ] },
    uniques => { p => [ [ 'p_code2', [qw/code id/] ] ] });
  is_deeply stmts(diff($src, $tgt)), [
    'ALTER TABLE "c" DROP CONSTRAINT "c_pcode_fk";',
    'ALTER TABLE "p" DROP CONSTRAINT "p_code";',
    'ALTER TABLE "p" ADD CONSTRAINT "p_code2" UNIQUE ("code", "id");',
    'ALTER TABLE "c" ADD CONSTRAINT "c_pcode_fk" FOREIGN KEY ("pcode") REFERENCES "p" ("code");',
  ], 'the key over the changed unique constraint goes first and comes back last';
}

# --- the primary key of a table that exists (karr k58, k62) ---------------------------
# The key is not a model section of its own, only is_pk / pk_position on the
# columns; its name is primary_key_name of the table. The same key (in key
# order) is no change; another one is DROP CONSTRAINT <name> + ADD PRIMARY KEY.
sub pk_model {
  my ($pk, $name) = @_;   # [ column => position, ... ]
  my %pos = @$pk;
  my @cols = map { { %{ col($_) }, (exists $pos{$_} ? (is_pk => 1, pk_position => $pos{$_}) : ()) } } qw/id c d/;
  return { tables => { t => { table_name => 't', kind => 'table', (defined $name && @$pk ? (primary_key_name => $name) : ()) } },
           columns => { t => \@cols }, indexes => {}, unique_constraints => {}, foreign_keys => {} };
}
ok !diff(pk_model([ id => 0, c => 1 ], 'INTEG_2'), pk_model([ c => 1, id => 0 ]))->has_changes,
  'the same composite key: no change';
for my $case (
  [ 'a key the database lacks', [], [ id => 0 ],
    [ 'ALTER TABLE "t" ADD PRIMARY KEY ("id");' ] ],
  [ 'a key the schema does not have', [ id => 0 ], [],
    [ 'ALTER TABLE "t" DROP CONSTRAINT "INTEG_2";' ] ],
  [ 'a key over another column', [ id => 0 ], [ c => 0 ],
    [ 'ALTER TABLE "t" DROP CONSTRAINT "INTEG_2";', 'ALTER TABLE "t" ADD PRIMARY KEY ("c");' ] ],
  [ 'a key with its columns in another order', [ id => 0, c => 1 ], [ c => 0, id => 1 ],
    [ 'ALTER TABLE "t" DROP CONSTRAINT "INTEG_2";', 'ALTER TABLE "t" ADD PRIMARY KEY ("c", "id");' ] ],
) {
  my ($label, $s, $t, $want) = @$case;
  my $d = diff(pk_model($s, 'INTEG_2'), pk_model($t));
  ok $d->has_changes, "primary key, $label: reported";
  like $d->summary, qr/primary key: t/, '... in the summary';
  is_deeply stmts($d), $want, '... and written';
}
{
  my $d = diff(pk_model([ id => 0 ]), pk_model([ c => 0 ]));
  ok !eval { $d->as_sql; 1 }, 'a key to drop whose model holds no name: as_sql dies';
  like "$@", qr/cannot drop the primary key of table "t".*no name/, '... naming the table';
}
{
  # a foreign key at the primary key that is replaced goes around it
  my $src = pk_model([ id => 0 ], 'INTEG_2');
  $src->{tables}{o} = { table_name => 'o', kind => 'table' };
  $src->{columns}{o} = [ col('x') ];
  $src->{foreign_keys}{o} = [ fk(from => 'o', cols => ['x'], to => 't') ];
  my $tgt = pk_model([ c => 0 ]);
  $tgt->{tables}{o} = { table_name => 'o', kind => 'table' };
  $tgt->{columns}{o} = [ col('x') ];
  $tgt->{foreign_keys}{o} = [ fk(from => 'o', cols => ['x'], to => 't') ];
  is_deeply stmts(diff($src, $tgt)), [
    'ALTER TABLE "o" DROP CONSTRAINT "o_x_fk";',
    'ALTER TABLE "t" DROP CONSTRAINT "INTEG_2";',
    'ALTER TABLE "t" ADD PRIMARY KEY ("c");',
    'ALTER TABLE "o" ADD CONSTRAINT "o_x_fk" FOREIGN KEY ("x") REFERENCES "t" ("id");',
  ], 'a foreign key at a replaced primary key is dropped before and added after';
}

# --- beside a new table, and beside a column change ------------------------------------
{
  my $src = model(columns => { t => [qw/id c/], o => ['id'] });
  my $tgt = model(columns => { t => [qw/id c/], o => ['id'], n => ['id'] },
    uniques => { t => [ [ 't_c', ['c'] ] ] });
  my @sql = grep { /^(?:CREATE|ALTER)/ } split /\n/, diff($src, $tgt)->as_sql;
  like $sql[0], qr/^CREATE TABLE "n"/, 'a new table beside a constraint change: the table first';
  like $sql[1], qr/^ALTER TABLE "t" ADD CONSTRAINT "t_c" UNIQUE/, '... then the constraint';
}
{
  my $src = model(columns => { t => [qw/id c/] });
  $src->{columns}{t}[1] = { %{ col('c') }, data_type => 'varchar', size => 20 };
  my $tgt = model(columns => { t => [qw/id c/] }, uniques => { t => [ [ 't_c', ['c'] ] ] });
  $tgt->{columns}{t}[1] = { %{ col('c') }, data_type => 'varchar', size => 10 };
  ok !eval { diff($src, $tgt)->as_sql; 1 }, 'a refused column change still refuses the whole diff';
  like "$@", qr/refusing to change 1 column/, '... with the column refusal of karr k38';
  unlike "$@", qr/UNIQUE|ADD CONSTRAINT/, '... and the constraint is no part of the refusal';
}

# --- DROP TABLE in the order of the keys (karr k34) -----------------------------------
# A table another table's key points at cannot be dropped; the tables go child
# before parent, and where they point at each other the keys go first.
sub drops { my ($d) = @_; return [ grep { /^(?:DROP TABLE|ALTER TABLE)/ } split /\n/, $d->as_sql ] }
{
  my $src = model(columns => { a_parent => ['id'], b_child => [qw/id pid/], c_grand => [qw/id pid/] },
    fks => { b_child => [ fk(from => 'b_child', cols => ['pid'], to => 'a_parent') ],
             c_grand => [ fk(from => 'c_grand', cols => ['pid'], to => 'b_child') ] });
  is_deeply drops(diff($src, model(columns => {}))),
    [ 'DROP TABLE "c_grand";', 'DROP TABLE "b_child";', 'DROP TABLE "a_parent";' ],
    'a chain of keys: grandchild, child, parent (not the alphabetical order)';
}
{
  my $src = model(columns => { p => ['id'], c => [qw/id pid/], keep => ['id'] },
    fks => { c => [ fk(from => 'c', cols => ['pid'], to => 'p') ] });
  is_deeply drops(diff($src, model(columns => { keep => ['id'] }))),
    [ 'DROP TABLE "c";', 'DROP TABLE "p";' ], 'parent and child dropped together: child first';
}
{
  my $src = model(columns => { a => [qw/id b_id/], b => [qw/id a_id/] },
    fks => { a => [ fk(from => 'a', cols => ['b_id'], to => 'b') ],
             b => [ fk(from => 'b', cols => ['a_id'], to => 'a') ] });
  my $d = diff($src, model(columns => {}));
  is_deeply drops($d), [
    'ALTER TABLE "b" DROP CONSTRAINT "b_a_id_fk";',
    'ALTER TABLE "a" DROP CONSTRAINT "a_b_id_fk";',
    'DROP TABLE "a";', 'DROP TABLE "b";',
  ], 'a cycle: the keys between the tables go first, then the tables';
  like $d->summary, qr/- foreign key: a\.a_b_id_fk/, 'the key drop is in the summary';
}
{
  my $src = model(columns => { t => [qw/id up/] }, fks => { t => [ fk(from => 't', cols => ['up'], to => 't') ] });
  is_deeply drops(diff($src, model(columns => {}))), [ 'DROP TABLE "t";' ],
    'a table pointing at itself is dropped without a key drop';
}
{
  my $src = model(columns => { p => ['id'], c => [qw/id pid/] },
    fks => { c => [ fk(from => 'c', cols => ['pid'], to => 'p') ] });
  is_deeply drops(diff($src, model(columns => { p => ['id'], c => [qw/id pid/] },
    fks => { c => [ fk(from => 'c', cols => ['pid'], to => 'p') ] }))), [], 'nothing dropped, nothing to order';
}

done_testing;
