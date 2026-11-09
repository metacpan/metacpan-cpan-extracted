use strict;
use warnings;
use Test::More;

use_ok 'DBIO::MySQL::Diff::Table';
use_ok 'DBIO::MySQL::Diff::Column';
use_ok 'DBIO::MySQL::Diff::Index';
use_ok 'DBIO::MySQL::Diff::ForeignKey';
use_ok 'DBIO::MySQL::Diff';

use DBIO::MySQL::Adapter ();

# --- Diff::Table create with columns + FK inline ---
{
  my @ops = DBIO::MySQL::Diff::Table->diff(
    {},
    { book => { table_name => 'book', engine => 'InnoDB' } },
    {
      book => [
        { column_name => 'id',        column_type => 'int(11)',     is_pk => 1, is_auto_increment => 1, not_null => 1 },
        { column_name => 'author_id', column_type => 'int(11)',     not_null => 1 },
        { column_name => 'title',     column_type => 'varchar(255)', not_null => 1 },
      ],
    },
    {
      book => [
        { from_columns => ['author_id'], to_table => 'author', to_columns => ['id'] },
      ],
    },
  );
  is(scalar @ops, 1, 'one create op');
  is($ops[0]->action, 'create', 'create');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/CREATE TABLE `book`/, 'CREATE TABLE');
  like($sql, qr/`id` int\(11\) NOT NULL AUTO_INCREMENT/, 'inline auto_increment');
  like($sql, qr/PRIMARY KEY \(`id`\)/,     'inline PK');
  like($sql, qr/FOREIGN KEY \(`author_id`\) REFERENCES `author`\(`id`\)/, 'inline FK');
  like($sql, qr/ENGINE=InnoDB/, 'engine clause');
}

# --- Diff::Table drop ---
{
  my @ops = DBIO::MySQL::Diff::Table->diff(
    { gone => { table_name => 'gone' } }, {},
  );
  is($ops[0]->action, 'drop', 'drop');
  is($ops[0]->as_sql, 'DROP TABLE `gone`;', 'drop SQL');
}

# --- Diff::Column add ---
{
  my @ops = DBIO::MySQL::Diff::Column->diff(
    { t => [ { column_name => 'id', column_type => 'int(11)' } ] },
    {
      t => [
        { column_name => 'id',    column_type => 'int(11)' },
        { column_name => 'extra', column_type => 'varchar(50)', not_null => 1 },
      ],
    },
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one add op');
  like($ops[0]->as_sql, qr/ADD COLUMN `extra` varchar\(50\) NOT NULL/, 'add SQL');
}

# --- Diff::Column modify (type changed) ---
{
  my @ops = DBIO::MySQL::Diff::Column->diff(
    { t => [ { column_name => 'a', column_type => 'int(11)' } ] },
    { t => [ { column_name => 'a', column_type => 'bigint' } ] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'modify', 'modify op');
  like($ops[0]->as_sql, qr/MODIFY COLUMN `a` bigint/, 'modify SQL');
}

# --- Diff::Column drop ---
{
  my @ops = DBIO::MySQL::Diff::Column->diff(
    { t => [
      { column_name => 'id', column_type => 'int' },
      { column_name => 'old', column_type => 'text' },
    ]},
    { t => [ { column_name => 'id', column_type => 'int' } ] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'drop', 'drop col');
  like($ops[0]->as_sql, qr/DROP COLUMN `old`/, 'drop SQL');
}

# --- Diff::Column add: in the order the target declares the columns (karr k92) ---
# A table the diff extends is to have its columns in the order a fresh deploy
# of the schema gives it. The columns are declared zeta before alpha, against
# the order of their names; the MODIFY of beta stays where it was.
{
  my @ops = DBIO::MySQL::Diff::Column->diff(
    { t => [
      { column_name => 'id',   column_type => 'int(11)' },
      { column_name => 'beta', column_type => 'int(11)' },
    ]},
    { t => [
      { column_name => 'id',    column_type => 'int(11)' },
      { column_name => 'beta',  column_type => 'bigint' },
      { column_name => 'zeta',  column_type => 'int(11)' },
      { column_name => 'alpha', column_type => 'int(11)' },
    ]},
    { t => {} }, { t => {} },
  );
  is_deeply [ map { $_->as_sql } @ops ], [
    'ALTER TABLE `t` ADD COLUMN `zeta` int(11);',
    'ALTER TABLE `t` MODIFY COLUMN `beta` bigint;',
    'ALTER TABLE `t` ADD COLUMN `alpha` int(11);',
  ], 'k92: the columns a table gains are added in the order of the target, not of their names';
}

# --- Diff::Index create ---
# A unique index as the introspection hands it over: is_unique with origin 'u'
# (DBIO::MySQL::Introspect::Indexes gives 'u' to every unique index that is not
# the PRIMARY KEY; is_unique with origin 'c' is a pair it never produces).
{
  my @ops = DBIO::MySQL::Diff::Index->diff(
    {},
    { t => { idx_t_name => {
      index_name => 'idx_t_name', is_unique => 1,
      columns => ['name'], origin => 'u',
    }}},
  );
  is(scalar @ops, 1, 'one index create');
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX `idx_t_name` ON `t` (`name`);', 'create SQL');
}

# --- Diff::Index skips the PRIMARY KEY, and only that (karr k70) ---
# The PRIMARY KEY is written into CREATE TABLE by Diff::Table. A unique index
# is not: on this engine a UNIQUE constraint is a unique index and nothing
# else, so it is created here like every other index. t/43 has the four cases.
{
  my @ops = DBIO::MySQL::Diff::Index->diff(
    {},
    {
      t => {
        PRIMARY    => { index_name => 'PRIMARY',    is_unique => 1, columns => ['id'],   origin => 'pk' },
        uniq_email => { index_name => 'uniq_email', is_unique => 1, columns => ['email'], origin => 'u' },
      },
    },
  );
  is_deeply([ map { $_->as_sql } @ops ],
    [ 'CREATE UNIQUE INDEX `uniq_email` ON `t` (`email`);' ],
    'the PRIMARY KEY is skipped, the unique index beside it is created');
}

# --- Diff::Index drop ---
{
  my @ops = DBIO::MySQL::Diff::Index->diff(
    { t => { gone_idx => {
      index_name => 'gone_idx', columns => ['x'], origin => 'c',
    }}},
    {},
  );
  is($ops[0]->as_sql, 'DROP INDEX `gone_idx` ON `t`;', 'drop index SQL');
}

# --- Diff::Index: owning table dropped -> suppress standalone DROP INDEX (karr #23) ---
# When the table itself is being dropped in the same pass (present in source
# tables, absent from target tables), DROP TABLE already removes the table's
# own indexes, so no standalone DROP INDEX must be emitted for them.
{
  my @ops = DBIO::MySQL::Diff::Index->diff(
    { leftover => { idx_leftover_x => {
      index_name => 'idx_leftover_x', columns => ['x'], origin => 'c',
    }}},
    {},
    { leftover => { table_name => 'leftover' } },   # source tables: leftover exists
    {},                                             # target tables: gone -> dropped
  );
  is(scalar @ops, 0, 'no standalone DROP INDEX when owning table is dropped (DROP TABLE covers it)');
}

# --- Diff::Index: over-suppression guard (karr #23) ---
# A table that STAYS but loses one of its indexes must still get a standalone
# DROP INDEX -- the suppression only applies to indexes of dropped tables.
{
  my @ops = DBIO::MySQL::Diff::Index->diff(
    { users => { idx_users_email => {
      index_name => 'idx_users_email', columns => ['email'], origin => 'c',
    }}},
    {},
    { users => { table_name => 'users' } },   # source tables: users exists
    { users => { table_name => 'users' } },   # target tables: users still exists
  );
  is(scalar @ops, 1, 'index drop still emitted when the table itself survives');
  is($ops[0]->action, 'drop', 'surviving-table index drop is a drop op');
  is($ops[0]->as_sql, 'DROP INDEX `idx_users_email` ON `users`;',
    'surviving-table index still dropped standalone');
}

# --- Diff::Index: index_type rendering + phantom-diff guard (karr k52 / core k181, ADR 0052) ---
# core k181 taught the canonical comparison (changed_index_fields) to compare
# index_type as a `mutual` field: a difference only when BOTH sides carry a
# type, so a driver that does not introspect the type never manufactures a
# phantom diff. This driver now (a) sees a BTREE->FULLTEXT switch as a real
# change, (b) RENDERS the index class/type keyword in the CREATE it emits, and
# (c) stays silent when the type is absent on either side or unchanged.

# (b) rendering: a created FULLTEXT/SPATIAL index carries the class keyword in
# front of INDEX; BTREE/HASH carry the trailing USING clause. This is the gap
# Diff::Index::as_sql used to have -- it emitted a bare CREATE INDEX, so a
# FULLTEXT index created by a diff silently came back as the default BTREE. The
# split is the same grammar DDL.pm renders (CREATE [UNIQUE | FULLTEXT | SPATIAL]
# INDEX name [USING BTREE|HASH]), shared through one helper, not re-rendered.
{
  my %want = (
    FULLTEXT => 'CREATE FULLTEXT INDEX `idx_t_c` ON `t` (`c`);',
    SPATIAL  => 'CREATE SPATIAL INDEX `idx_t_c` ON `t` (`c`);',
    BTREE    => 'CREATE INDEX `idx_t_c` ON `t` (`c`) USING BTREE;',
    HASH     => 'CREATE INDEX `idx_t_c` ON `t` (`c`) USING HASH;',
  );
  for my $type (sort keys %want) {
    my @ops = DBIO::MySQL::Diff::Index->diff(
      {},
      { t => { idx_t_c => {
        index_name => 'idx_t_c', is_unique => 0,
        columns => ['c'], index_type => $type, origin => 'c',
      }}},
    );
    is(scalar @ops, 1, "$type: one create op");
    is($ops[0]->as_sql, $want{$type},
      "$type index_type renders its keyword in the CREATE");
  }
}

# (a) a BTREE->FULLTEXT switch on otherwise-identical columns is a real change:
# drop the old, create the new. This is exactly what the core `mutual` group
# fires on, and the recreated index is rendered with its new class keyword.
{
  my @ops = DBIO::MySQL::Diff::Index->diff(
    { t => { idx_t_c => {
      index_name => 'idx_t_c', is_unique => 0,
      columns => ['c'], index_type => 'BTREE', origin => 'c',
    }}},
    { t => { idx_t_c => {
      index_name => 'idx_t_c', is_unique => 0,
      columns => ['c'], index_type => 'FULLTEXT', origin => 'c',
    }}},
  );
  is(scalar @ops, 2, 'type switch -> drop + create');
  is($ops[0]->action, 'drop',   'old index dropped first');
  is($ops[1]->action, 'create', 'new index created');
  is($ops[1]->as_sql, 'CREATE FULLTEXT INDEX `idx_t_c` ON `t` (`c`);',
    'the recreated index is rendered with its new class keyword');
}

# (c) phantom-diff guard: the `mutual` group means a type present on only one
# side is NOT a change (a driver that does not introspect the type must not
# churn), and an unchanged type is not a change either. All three produce zero
# ops. This is the property the mutual group protects; pin it explicitly.
{
  my $with = {
    index_name => 'idx_t_c', is_unique => 0, columns => ['c'],
    index_type => 'BTREE', origin => 'c',
  };
  my $without = {
    index_name => 'idx_t_c', is_unique => 0, columns => ['c'], origin => 'c',
  };

  my @only_target = DBIO::MySQL::Diff::Index->diff(
    { t => { idx_t_c => { %$without } } },
    { t => { idx_t_c => { %$with    } } },
  );
  is(scalar @only_target, 0,
    'index_type on the target alone is no change (mutual needs both sides)');

  my @only_source = DBIO::MySQL::Diff::Index->diff(
    { t => { idx_t_c => { %$with    } } },
    { t => { idx_t_c => { %$without } } },
  );
  is(scalar @only_source, 0,
    'index_type on the source alone is no change either');

  my @same = DBIO::MySQL::Diff::Index->diff(
    { t => { idx_t_c => { %$with } } },
    { t => { idx_t_c => { %$with } } },
  );
  is(scalar @same, 0, 'an unchanged index_type produces no diff');
}

# --- Diff::ForeignKey add ---
{
  my @ops = DBIO::MySQL::Diff::ForeignKey->diff(
    { t => [] },
    { t => [{
      constraint_name => 'fk_t_other',
      from_columns => ['other_id'],
      to_table     => 'other',
      to_columns   => ['id'],
      on_update    => 'NO ACTION',
      on_delete    => 'CASCADE',
    }]},
    { t => {} }, { t => {} },
  );
  is(scalar @ops, 1, 'one fk add');
  my $sql = $ops[0]->as_sql;
  like($sql, qr/ADD CONSTRAINT `fk_t_other` FOREIGN KEY \(`other_id`\) REFERENCES `other`\(`id`\)/, 'add fk');
  like($sql, qr/ON DELETE CASCADE/, 'on delete cascade');
  unlike($sql, qr/ON UPDATE/, 'on update NO ACTION omitted');
}

# --- Diff::ForeignKey drop ---
{
  my @ops = DBIO::MySQL::Diff::ForeignKey->diff(
    { t => [{
      constraint_name => 'fk_old', from_columns => ['x'],
      to_table => 'other', to_columns => ['id'],
    }]},
    { t => [] },
    { t => {} }, { t => {} },
  );
  is($ops[0]->action, 'drop', 'drop fk');
  is($ops[0]->as_sql, 'ALTER TABLE `t` DROP FOREIGN KEY `fk_old`;', 'drop fk SQL');
}

# --- The last foreign key of a table (karr k86) ---
# The block above gives the table that lost its foreign key an entry in the
# target, `t => []`. No model has that entry: Introspect::ForeignKeys makes one
# only for a table it found a constraint on, and target_from_compiled returns
# an empty section. So a table that loses its only foreign key is a table the
# target does not name among the foreign keys at all. The diff walked the
# tables named there and no others, wrote nothing for this one, and upgrade
# said there was nothing to do while the constraint stayed in the database.
#
# The two cases beside it are the ones that must go on writing nothing here: a
# foreign key of a table the diff creates is in its CREATE TABLE, and one of a
# table the diff drops goes with the table -- an ALTER TABLE on it after the
# DROP TABLE is refused by the server and ends the upgrade.
{
  my %fk = (
    constraint_name => 'child_ibfk_1', from_columns => ['parent_id'],
    to_table => 'parent', to_columns => ['id'],
    on_update => 'NO ACTION', on_delete => 'NO ACTION',
  );
  my %column = (
    parent => [ { column_name => 'id', column_type => 'int(11)', is_pk => 1, not_null => 1 } ],
    map { $_ => [
      { column_name => 'id',        column_type => 'int(11)', is_pk => 1, not_null => 1 },
      { column_name => 'parent_id', column_type => 'int(11)', not_null => 1 },
    ] } qw(child other),
  );
  # A model of these tables; the foreign keys are given as the introspection
  # gives them, which is without a table that has none.
  my $model = sub {
    my ($tables, $fks) = @_;
    return {
      tables       => { map { $_ => { table_name => $_, engine => 'InnoDB' } } @$tables },
      columns      => { map { $_ => $column{$_} } @$tables },
      indexes      => {},
      foreign_keys => $fks,
    };
  };
  my $statements = sub {
    my ($source, $target) = @_;
    return [ map { $_->as_sql } @{ DBIO::MySQL::Diff->new(source => $source, target => $target)->operations } ];
  };

  is_deeply $statements->(
    $model->([qw(parent child)], { child => [ {%fk} ] }),
    $model->([qw(parent child)], {}),
  ), [ 'ALTER TABLE `child` DROP FOREIGN KEY `child_ibfk_1`;' ],
    'a table that lost its only foreign key: the diff drops it, and writes nothing else';

  is_deeply $statements->(
    $model->([qw(parent child other)], {
      child => [ {%fk} ],
      other => [ { %fk, constraint_name => 'other_ibfk_1' } ],
    }),
    $model->([qw(parent child other)], { other => [ { %fk, constraint_name => 'other_ibfk_1' } ] }),
  ), [ 'ALTER TABLE `child` DROP FOREIGN KEY `child_ibfk_1`;' ],
    '... also when another table keeps its own, which is left alone';

  is_deeply [ map { $_->as_sql } DBIO::MySQL::Diff::ForeignKey->diff(
    { child => [ {%fk} ] }, {},
    { parent => {}, child => {} }, { parent => {}, child => {} },
  ) ], [ 'ALTER TABLE `child` DROP FOREIGN KEY `child_ibfk_1`;' ],
    '... and so does Diff::ForeignKey asked directly, with the tables of both sides';

  is_deeply $statements->(
    $model->([qw(parent)], {}),
    $model->([qw(parent child)], { child => [ {%fk} ] }),
  ), [
    "CREATE TABLE `child` (\n"
      . "  `id` int(11) NOT NULL,\n"
      . "  `parent_id` int(11) NOT NULL,\n"
      . "  PRIMARY KEY (`id`),\n"
      . "  CONSTRAINT `child_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `parent`(`id`)\n"
      . ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
  ], 'a table the diff creates: its foreign key is in the CREATE TABLE, and no ADD CONSTRAINT follows';

  is_deeply $statements->(
    $model->([qw(parent child)], { child => [ {%fk} ] }),
    $model->([qw(parent)], {}),
  ), [ 'DROP TABLE `child`;' ],
    'a table the diff drops: its foreign key goes with it, and no DROP FOREIGN KEY follows';
}

# --- Where the index statements stand among the column changes (karr k80) ---
# An index is dropped before the columns of its table change, and created after
# they have. The diff used to write every index statement after the column
# changes, and a column that left the schema together with an index over it
# ended the upgrade: the server takes an index along with the last column it
# was over, so the DROP INDEX that followed named an index that was no longer
# there (1091); and MariaDB refuses to drop one column of a unique key over
# several (1072), so there the upgrade never got as far and never would.
#
# Dropped first, the index is out of the way of whatever happens to its
# columns. Created last, it finds the columns it is over: the ones the same
# diff adds, and the ones it changes in the type they are to have. A changed
# index is both, a drop and a create, and so stands on either side of the
# column changes.
#
# The live half is t/87-diff-column-with-index-live.t.
{
  my %column = (
    id     => { column_name => 'id',     data_type => 'int',     column_type => 'int(11)',     not_null => 1, is_pk => 1 },
    code   => { column_name => 'code',   data_type => 'int',     column_type => 'int(11)',     not_null => 1 },
    tenant => { column_name => 'tenant', data_type => 'int',     column_type => 'int(11)',     not_null => 1 },
    wide   => { column_name => 'code',   data_type => 'bigint',  column_type => 'bigint(20)',  not_null => 1 },
    extra  => { column_name => 'extra',  data_type => 'int',     column_type => 'int(11)',     not_null => 1 },
  );
  # An index entry as DBIO::MySQL::Introspect::Indexes->fetch returns it.
  my $index = sub {
    my ($kind, $name, @columns) = @_;
    return ($name => {
      index_name => $name, is_unique => ($kind eq 'unique' ? 1 : 0), columns => [@columns],
      index_type => 'BTREE', origin => ($kind eq 'unique' ? 'u' : 'c'),
    });
  };
  # A model of the tables given as name => [ [columns], { indexes } ].
  my $model = sub {
    my (%tables) = @_;
    return {
      tables       => { map { $_ => { table_name => $_, engine => 'InnoDB' } } keys %tables },
      columns      => { map { $_ => [ map { +{ %{ $column{$_} } } } @{ $tables{$_}[0] } ] } keys %tables },
      indexes      => { map { $_ => { %{ $tables{$_}[1] // {} } } } keys %tables },
      foreign_keys => {},
    };
  };
  my $statements = sub {
    my ($source, $target) = @_;
    return [ map { $_->as_sql } @{ DBIO::MySQL::Diff->new(source => $source, target => $target)->operations } ];
  };

  for my $kind (qw(plain unique)) {
    my $create = $kind eq 'unique' ? 'CREATE UNIQUE INDEX' : 'CREATE INDEX';

    is_deeply $statements->(
      $model->(t => [ [qw(id code)], { $index->($kind, k_code => 'code') } ]),
      $model->(t => [ [qw(id)] ]),
    ), [
      'DROP INDEX `k_code` ON `t`;',
      'ALTER TABLE `t` DROP COLUMN `code`;',
    ], "$kind index, its only column leaves with it: the index is dropped before the column";

    is_deeply $statements->(
      $model->(t => [ [qw(id tenant code)], { $index->($kind, k_pair => 'tenant', 'code') } ]),
      $model->(t => [ [qw(id code)] ]),
    ), [
      'DROP INDEX `k_pair` ON `t`;',
      'ALTER TABLE `t` DROP COLUMN `tenant`;',
    ], "$kind index over two columns, one of them leaves with it: the index is dropped before the column";

    is_deeply $statements->(
      $model->(t => [ [qw(id tenant code)], { $index->($kind, k_pair => 'tenant', 'code') } ]),
      $model->(t => [ [qw(id code)],        { $index->($kind, k_pair => 'code') } ]),
    ), [
      'DROP INDEX `k_pair` ON `t`;',
      'ALTER TABLE `t` DROP COLUMN `tenant`;',
      "$create `k_pair` ON `t` (`code`) USING BTREE;",
    ], "$kind index that stays over the column that is left: dropped before the column, created after";

    # The create half must not move forward with the drop half: the index is
    # over a column the same diff adds, and over one it changes.
    is_deeply $statements->(
      $model->(t => [ [qw(id code)],       { $index->($kind, k_code => 'code') } ]),
      $model->(t => [ [qw(id wide extra)], { $index->($kind, k_code => 'code', 'extra') } ]),
    ), [
      'DROP INDEX `k_code` ON `t`;',
      'ALTER TABLE `t` MODIFY COLUMN `code` bigint(20) NOT NULL;',
      'ALTER TABLE `t` ADD COLUMN `extra` int(11) NOT NULL;',
      "$create `k_code` ON `t` (`code`, `extra`) USING BTREE;",
    ], "$kind index changed along with its columns: dropped, then the columns changed and added, then created";

    is_deeply $statements->(
      $model->(t => [ [qw(id code)] ]),
      $model->(t => [ [qw(id code extra)], { $index->($kind, k_extra => 'extra') } ]),
    ), [
      'ALTER TABLE `t` ADD COLUMN `extra` int(11) NOT NULL;',
      "$create `k_extra` ON `t` (`extra`) USING BTREE;",
    ], "$kind index over a column the diff adds: created after the column";
  }

  # Every kind of statement in one diff: the tables, the index drops, the column
  # changes, the index creates. The index of the table the diff creates follows
  # its CREATE TABLE, and the one of the table it drops goes with the table
  # (karr k23).
  is_deeply $statements->(
    $model->(
      gone => [ [qw(id code)],        { $index->(plain => k_gone => 'code') } ],
      t    => [ [qw(id tenant code)], { $index->(unique => k_pair => 'tenant', 'code'), $index->(plain => k_old => 'code') } ],
    ),
    $model->(
      fresh => [ [qw(id code)],       { $index->(plain => k_fresh => 'code') } ],
      t     => [ [qw(id code extra)], { $index->(unique => k_pair => 'code'), $index->(plain => k_new => 'extra') } ],
    ),
  ), [
    "CREATE TABLE `fresh` (\n"
      . "  `id` int(11) NOT NULL,\n"
      . "  `code` int(11) NOT NULL,\n"
      . "  PRIMARY KEY (`id`)\n"
      . ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;",
    'DROP TABLE `gone`;',
    'DROP INDEX `k_pair` ON `t`;',
    'DROP INDEX `k_old` ON `t`;',
    'ALTER TABLE `t` ADD COLUMN `extra` int(11) NOT NULL;',
    'ALTER TABLE `t` DROP COLUMN `tenant`;',
    'CREATE INDEX `k_fresh` ON `fresh` (`code`) USING BTREE;',
    'CREATE INDEX `k_new` ON `t` (`extra`) USING BTREE;',
    'CREATE UNIQUE INDEX `k_pair` ON `t` (`code`) USING BTREE;',
  ], 'one diff with all of it: tables, then the index drops, then the column changes, then the index creates';
}

# --- AUTO_INCREMENT in a column diff (karr k93, karr k80) ---
# MODIFY COLUMN restates the whole column, so a column that has AUTO_INCREMENT
# in the target has to be written with it: the MODIFY of an AUTO_INCREMENT
# primary key that left the attribute out took it away from the column, and the
# next INSERT without an id failed. And AUTO_INCREMENT that comes or goes is a
# change of the column the diff has to see.
#
# A column that is AUTO_INCREMENT without being the primary key has to have a
# key, and the server (MySQL 8.0 and MariaDB 11.8 alike) refuses the DROP INDEX
# of its only key with 1075 -- also before dropping the column. What it takes
# is the column without AUTO_INCREMENT first, then the index, then the rest;
# a MODIFY is also what a column that is about to leave gets, for the same
# reason. The live half is t/105-diff-auto-increment-live.t.
{
  my %c = (
    id     => { column_name => 'id',   data_type => 'int',    column_type => 'int(11)',    not_null => 1, is_pk => 1, is_auto_increment => 1 },
    id_big => { column_name => 'id',   data_type => 'bigint', column_type => 'bigint(20)', not_null => 1, is_pk => 1, is_auto_increment => 1 },
    id_no  => { column_name => 'id',   data_type => 'int',    column_type => 'int(11)',    not_null => 1, is_pk => 1 },
    seq    => { column_name => 'seq',  data_type => 'int',    column_type => 'int(11)',    not_null => 1, is_auto_increment => 1 },
    seq_no => { column_name => 'seq',  data_type => 'int',    column_type => 'int(11)',    not_null => 1 },
    seq_big=> { column_name => 'seq',  data_type => 'bigint', column_type => 'bigint(20)', not_null => 1 },
    note   => { column_name => 'note', data_type => 'int',    column_type => 'int(11)',    not_null => 1 },
    note_b => { column_name => 'note', data_type => 'bigint', column_type => 'bigint(20)', not_null => 1 },
  );
  my $key = { k_seq => { index_name => 'k_seq', is_unique => 1, columns => ['seq'], index_type => 'BTREE', origin => 'u' } };
  my $sql = sub {
    my ($from, $to) = @_;
    my $m = sub { +{
      tables  => { t => { table_name => 't', engine => 'InnoDB' } },
      columns => { t => [ map { +{ %{ $c{$_} } } } @{ $_[0][0] } ] },
      indexes => { t => $_[0][1] // {} }, foreign_keys => {},
    } };
    return [ map { $_->as_sql } @{ DBIO::MySQL::Diff->new(source => $m->($from), target => $m->($to))->operations } ];
  };

  is_deeply $sql->([ [qw(id)] ], [ [qw(id_big)] ]),
    [ 'ALTER TABLE `t` MODIFY COLUMN `id` bigint(20) NOT NULL AUTO_INCREMENT;' ],
    'k93: the MODIFY of an AUTO_INCREMENT column keeps AUTO_INCREMENT';

  is_deeply $sql->([ [qw(id_no)] ], [ [qw(id)] ]),
    [ 'ALTER TABLE `t` MODIFY COLUMN `id` int(11) NOT NULL AUTO_INCREMENT;' ],
    'k93: AUTO_INCREMENT that comes is a change, and is written';

  is_deeply $sql->([ [qw(id)] ], [ [qw(id_no)] ]),
    [ 'ALTER TABLE `t` MODIFY COLUMN `id` int(11) NOT NULL;' ],
    'k93: AUTO_INCREMENT that goes is a change, and is written';

  is_deeply $sql->([ [qw(id seq)], $key ], [ [qw(id seq_no)] ]),
    [
      'ALTER TABLE `t` MODIFY COLUMN `seq` int(11) NOT NULL;',
      'DROP INDEX `k_seq` ON `t`;',
    ], 'k80 A: the column loses AUTO_INCREMENT and its only key: MODIFY, then DROP INDEX';

  is_deeply $sql->([ [qw(id seq note)], $key ], [ [qw(id seq_big note_b)] ]),
    [
      'ALTER TABLE `t` MODIFY COLUMN `seq` bigint(20) NOT NULL;',
      'DROP INDEX `k_seq` ON `t`;',
      'ALTER TABLE `t` MODIFY COLUMN `note` bigint(20) NOT NULL;',
    ], 'k80 B: ... and gets another type at the same time: the one MODIFY stands before the DROP INDEX, the other columns after';

  is_deeply $sql->([ [qw(id seq note)], $key ], [ [qw(id note)] ]),
    [
      'ALTER TABLE `t` MODIFY COLUMN `seq` int(11) NOT NULL;',
      'DROP INDEX `k_seq` ON `t`;',
      'ALTER TABLE `t` DROP COLUMN `seq`;',
    ], 'k80 C: the column leaves the schema with its key: MODIFY without AUTO_INCREMENT, DROP INDEX, DROP COLUMN';

  is_deeply $sql->([ [qw(id note)], {} ], [ [qw(id note_b)] ]),
    [ 'ALTER TABLE `t` MODIFY COLUMN `note` bigint(20) NOT NULL;' ],
    'a column that never had AUTO_INCREMENT is modified as before';
}

# --- Top-level orchestrator ---
{
  my $diff = DBIO::MySQL::Diff->new(
    source => { tables => {}, columns => {}, indexes => {}, foreign_keys => {} },
    target => {
      tables       => { t => { table_name => 't', engine => 'InnoDB' } },
      columns      => { t => [ { column_name => 'id', column_type => 'int(11)', is_pk => 1 } ] },
      indexes      => {},
      foreign_keys => {},
    },
  );
  ok($diff->has_changes, 'has changes');
  like($diff->as_sql, qr/CREATE TABLE `t`/, 'orchestrator emits CREATE TABLE');
  like($diff->summary, qr/\+ table: t/, 'summary line');
}

# --- Identical models = no changes ---
{
  my $model = {
    tables       => { t => { table_name => 't' } },
    columns      => { t => [ { column_name => 'id', column_type => 'int' } ] },
    indexes      => {},
    foreign_keys => {},
  };
  my $diff = DBIO::MySQL::Diff->new(source => $model, target => $model);
  ok(!$diff->has_changes, 'identical = no changes');
}

# --- Round-trip: an unchanged decimal column emits no MODIFY (karr #43) ---
# The width the adapter writes and the width the server reports back are not the
# same string. MySQL and MariaDB store DECIMAL(M) as DECIMAL(M,0) and a sizeless
# DECIMAL as DECIMAL(10,0), and information_schema answers with both members
# either way -- while the adapter renders a precision-only numeric as DECIMAL(p)
# (karr #41) and a sizeless one as bare DECIMAL. So target_from_compiled has to
# translate into the server's spelling: otherwise a column nobody touched is
# re-MODIFYed on every deploy, forever. The target side is derived from the
# adapter here, not typed out, so the two really are compared across the seam.
{
  my $adapter  = DBIO::MySQL::Adapter->new;
  my $compiled = {
    tables => {
      money => {
        columns => [
          { column_name => 'amt',
            native_type => $adapter->to_native({ base_type => 'numeric', precision => 8 }),
            not_null    => 1 },
          { column_name => 'total',
            native_type => $adapter->to_native({ base_type => 'numeric', precision => 10, scale => 2 }),
            not_null    => 1 },
          { column_name => 'plain',
            native_type => $adapter->to_native({ base_type => 'numeric' }),
            not_null    => 1 },
        ],
      },
    },
  };
  my $target = DBIO::MySQL::Diff->target_from_compiled($compiled);

  is_deeply(
    [ map { $_->{column_type} } @{ $target->{columns}{money} } ],
    [ 'decimal(8,0)', 'decimal(10,2)', 'decimal(10,0)' ],
    'target_from_compiled writes the column_type information_schema reports',
  );

  # What information_schema.columns answers for exactly those three columns.
  my $source = {
    tables  => { money => { table_name => 'money', engine => 'InnoDB' } },
    columns => { money => [
      { column_name => 'amt',   data_type => 'decimal', column_type => 'decimal(8,0)',  not_null => 1 },
      { column_name => 'total', data_type => 'decimal', column_type => 'decimal(10,2)', not_null => 1 },
      { column_name => 'plain', data_type => 'decimal', column_type => 'decimal(10,0)', not_null => 1 },
    ]},
    indexes      => {},
    foreign_keys => {},
  };

  my $diff = DBIO::MySQL::Diff->new(source => $source, target => $target);
  ok(!$diff->has_changes, 'a deployed decimal column nobody changed produces no diff')
    or diag $diff->as_sql;
}

# --- ... but the decimal width is still compared (karr #43 guard) ---
# Reconciling the two spellings must not turn into "stop looking at the width".
# Both of these are genuine ALTERs: widening the precision, and dropping a scale
# the deployed column has (DECIMAL(10) IS decimal(10,0), not "decimal(10,2)
# spelled shorter").
{
  my $tables = { money => { table_name => 'money' } };
  my %want   = ('DECIMAL(12)' => 'decimal(12,0)', 'DECIMAL(10)' => 'decimal(10,0)');

  for my $native (sort keys %want) {
    my $target = DBIO::MySQL::Diff->target_from_compiled({
      tables => { money => { columns => [
        { column_name => 'amt', native_type => $native, not_null => 1 },
      ]}},
    });
    my $deployed = $native eq 'DECIMAL(12)' ? 'decimal(8,0)' : 'decimal(10,2)';
    my @ops = DBIO::MySQL::Diff::Column->diff(
      { money => [ { column_name => 'amt', data_type => 'decimal',
          column_type => $deployed, not_null => 1 } ] },
      $target->{columns},
      $tables, $target->{tables},
    );
    is(scalar @ops, 1, "$deployed -> $native is a real change");
    is($ops[0]->action, 'modify', "$deployed -> $native emits a MODIFY");
    like($ops[0]->as_sql, qr/MODIFY COLUMN `amt` \Q$want{$native}\E/,
      "$native is altered to the server spelling $want{$native}");
  }
}

# --- DEFAULT: an expression is not a string, a literal is escaped (karr k78) ---
# t/112 has the full table; here the two cases the card names, through the diff.
{
  my @ops = DBIO::MySQL::Diff::Table->diff({}, { t => { table_name => 't' } }, { t => [
    { column_name => 'created', data_type => 'timestamp', column_type => 'timestamp',
      default_value => 'CURRENT_TIMESTAMP', default_is_expression => 1 },
    { column_name => 'note', data_type => 'varchar', column_type => 'varchar(20)',
      default_value => "it's" },
  ] });
  like($ops[0]->as_sql, qr/`created` timestamp DEFAULT CURRENT_TIMESTAMP,\n/,
    'a CURRENT_TIMESTAMP default is written as the expression, not as a string');
  like($ops[0]->as_sql, qr/`note` varchar\(20\) DEFAULT 'it''s'\n/,
    'a default with an apostrophe is a string literal with the apostrophe doubled');
}

done_testing;
