use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k107 (t/100 has the live half and the measurements): a
# table that exists in the source and the target gets the primary key the
# target names.
#
# WHY IT MATTERS. is_pk was no field of the column comparison and the index
# diff leaves the PRIMARY index out, so an upgrade of a table that had no
# primary key never gave it one, and one whose key was composed differently
# kept the old key -- for ever, the diff saying nothing. Claims:
#   1. no primary key in the source, one in the target: ADD PRIMARY KEY;
#   2. a different key: DROP PRIMARY KEY and ADD PRIMARY KEY in ONE statement
#      (the server refuses an AUTO_INCREMENT column that stands without a key
#      in between);
#   3. the same columns in another ORDER are another key (b, a is not a, b),
#      the order being pk_position, the position in the key -- not the order of
#      the columns in the table;
#   4. the same key: no operation;
#   5. a table the diff creates has its key in the CREATE TABLE, in the order
#      of pk_position, and no operation of this kind;
#   6. the statement stands after the column changes (the columns of the key
#      exist by then), before the indexes that are created and the foreign
#      keys that are added -- except where a column of the key gains
#      AUTO_INCREMENT: that MODIFY needs the key, so the key goes first;
#   7. the operation answers has_changes, summary and as_sql like the others;
#   8. a target without a key and a source with one: DROP PRIMARY KEY (action
#      drop, destructive), named in the summary with the columns it had; only
#      for a table that is in both models. An AUTO_INCREMENT column of the old
#      key that loses the attribute is written without it first; one that keeps
#      it is released for the drop and given the attribute back after the key it
#      has in the target; a key whose columns all go is dropped by the server
#      with the last column, no statement of its own;
#   9. the foreign keys that need the old key as their index (child keys that
#      point at its columns, keys of the table over them) are dropped before the
#      key changes and added again after it -- unless the new key, or another
#      index that stays, serves them, or the foreign key leaves the model
#      anyway (the foreign key diff drops that one, once). A foreign key the
#      TARGET declares on columns the target has no key over any more is
#      refused (DBIO::Exception) instead of being dropped without a word;
#  10. a new AUTO_INCREMENT column that is (part of) the key of an existing
#      table is added with the key in ONE ALTER TABLE (the server refuses the
#      column without a key).

use DBIO::MySQL::Diff;
use DBIO::MySQL::Diff::PrimaryKey;

# table => [ column spec ]: a name, or [name, pk_position], or a hash for more
sub model {
  my (%t) = @_;
  my %columns;
  for my $name (keys %t) {
    $columns{$name} = [ map {
      my $c = ref $_ eq 'HASH' ? $_ : { column_name => (ref $_ ? $_->[0] : $_), (ref $_ ? (pk_position => $_->[1], is_pk => 1) : ()) };
      { column_type => 'int(11)', not_null => 1, is_pk => 0, %$c };
    } @{ $t{$name} } ];
  }
  return {
    tables       => { map { $_ => { table_name => $_, engine => 'InnoDB' } } keys %t },
    columns      => \%columns,
    indexes      => { map { $_ => {} } keys %t },
    foreign_keys => {},
  };
}
sub statements {
  my ($source, $target) = @_;
  return [ map { $_->as_sql =~ s/\s+/ /gr } @{ DBIO::MySQL::Diff->new(source => $source, target => $target)->operations } ];
}

# --- 1. a table without a key gets one ---
is_deeply statements(model(t => [qw(a b)]), model(t => [ [a => 1], 'b' ])),
  [ 'ALTER TABLE `t` ADD PRIMARY KEY (`a`);' ], '1. no key in the source: ADD PRIMARY KEY';

# --- 2. another composition: one statement ---
is_deeply statements(model(t => [ [a => 1], 'b', 'c' ]), model(t => [ 'a', [b => 1], [c => 2] ])),
  [ 'ALTER TABLE `t` DROP PRIMARY KEY, ADD PRIMARY KEY (`b`, `c`);' ],
  '2. another key: DROP PRIMARY KEY, ADD PRIMARY KEY in one statement';

# --- 3. the same columns, another order ---
is_deeply statements(model(t => [ [a => 1], [b => 2] ]), model(t => [ [a => 2], [b => 1] ])),
  [ 'ALTER TABLE `t` DROP PRIMARY KEY, ADD PRIMARY KEY (`b`, `a`);' ],
  '3. the same columns in another order are another key, written in pk_position order';
is_deeply statements(model(t => [ [a => 2], [b => 1] ]), model(t => [ [a => 2], [b => 1] ])), [],
  '... and the very same order is no change, although the key is not in table order';

# --- 4. nothing to do ---
is_deeply statements(model(t => [ [a => 1], 'b' ]), model(t => [ [a => 1], 'b' ])), [], '4. the same key: nothing';
# a target model without pk_position (target_from_compiled of an old caller): table order
is_deeply statements(model(t => [ [a => 1], [b => 2] ]), model(t => [ { column_name => 'a', is_pk => 1 }, { column_name => 'b', is_pk => 1 } ])), [],
  '... a key without positions counts in table order';

# --- 5. a table the diff creates ---
{
  my $ops = DBIO::MySQL::Diff->new(source => model(), target => model(n => [ [a => 2], [b => 1] ]))->operations;
  is scalar @$ops, 1, '5. a new table is one operation';
  like $ops->[0]->as_sql, qr/PRIMARY KEY \(`b`, `a`\)/, '... its CREATE TABLE writes the key in pk_position order';
}

# --- 6. the place among the other statements ---
{
  my $src = model(t => [ 'a' ]);
  my $tgt = model(t => [ 'a', [b => 1] ]);
  $tgt->{indexes}{t} = { ix => { index_name => 'ix', is_unique => 0, columns => ['b'], index_type => 'BTREE', origin => 'c' } };
  is_deeply statements($src, $tgt), [
    'ALTER TABLE `t` ADD COLUMN `b` int(11) NOT NULL;',
    'ALTER TABLE `t` ADD PRIMARY KEY (`b`);',
    'CREATE INDEX `ix` ON `t` (`b`) USING BTREE;',
  ], '6. the key follows the column it is over and precedes the index creates';

  # a column that gains AUTO_INCREMENT and is the key: the key first
  my $s2 = model(t => [ { column_name => 'id', is_pk => 0, is_auto_increment => 0 } ]);
  my $t2 = model(t => [ { column_name => 'id', is_pk => 1, pk_position => 1, is_auto_increment => 1 } ]);
  my $got = statements($s2, $t2);
  is scalar @$got, 2, '... AUTO_INCREMENT gained by a key column: two statements';
  like $got->[0], qr/ADD PRIMARY KEY \(`id`\)/, '... the key first (the MODIFY with AUTO_INCREMENT needs one)';
  like $got->[1], qr/MODIFY COLUMN `id`.*AUTO_INCREMENT/, '... the MODIFY after it';
}

# --- 7. the operation ---
{
  my $diff = DBIO::MySQL::Diff->new(source => model(t => [qw(a b)]), target => model(t => [ [a => 1], [b => 2] ]));
  ok $diff->has_changes, '7. has_changes';
  like $diff->summary, qr/primary key: a, b on t/i, '... summary names the table and the columns';
  my ($op) = @{ $diff->operations };
  isa_ok $op, 'DBIO::MySQL::Diff::PrimaryKey';
  is $op->action, 'add', '... action add where the source had none';
  my $diff2 = DBIO::MySQL::Diff->new(source => model(t => [ [a => 1], 'b' ]), target => model(t => [ 'a', [b => 1] ]));
  is $diff2->operations->[0]->action, 'replace', '... action replace where it changes';
  is $diff2->classify->{class}, 'changing', '... and that is a change, not a destruction';
}

# --- 8. a target without a key: DROP PRIMARY KEY ---
is_deeply statements(model(t => [ [a => 1], 'b' ]), model(t => [ 'a', 'b' ])),
  [ 'ALTER TABLE `t` DROP PRIMARY KEY;' ], '8. a target without a key, a source with one: DROP PRIMARY KEY';
{
  my $diff = DBIO::MySQL::Diff->new(source => model(t => [ [a => 1], [b => 2] ]), target => model(t => [qw(a b)]));
  my ($op) = @{ $diff->operations };
  is $op->action, 'drop', '... action drop';
  like $diff->summary, qr/^  -pk: DROP PRIMARY KEY on t \(was a, b\)$/m, '... the summary names the drop, the table and the old columns'
    or diag $diff->summary;
  is $diff->classify->{class}, 'destructive', '... and it is destructive';
}
{
  my $got = statements(model(), model(t => [ [a => 1], 'b' ]));
  is scalar @$got, 1, '... a table that is only in the target: its CREATE TABLE only';
  unlike $got->[0], qr/DROP PRIMARY KEY/, '... and no DROP PRIMARY KEY in it';
}
is_deeply statements(model(t => [ [a => 1] ]), model()), [ 'DROP TABLE `t`;' ],
  '... a table that is only in the source: its DROP TABLE, no key statement';

# AUTO_INCREMENT in the old key
{
  my $ai = sub { +{ column_name => 'id', is_pk => $_[0], pk_position => ($_[0] ? 1 : undef), is_auto_increment => $_[1] } };
  my $got = statements(model(t => [ $ai->(1, 1) ]), model(t => [ $ai->(0, 0) ]));
  is scalar @$got, 2, '... an AUTO_INCREMENT key column that loses it: two statements';
  like $got->[0], qr/MODIFY COLUMN `id`/, '... the MODIFY first';
  unlike $got->[0], qr/AUTO_INCREMENT/, '... without AUTO_INCREMENT';
  is $got->[1], 'ALTER TABLE `t` DROP PRIMARY KEY;', '... then the drop';

  my $tgt = model(t => [ $ai->(0, 1) ]);
  $tgt->{indexes}{t} = { u => { index_name => 'u', is_unique => 1, columns => ['id'], index_type => 'BTREE', origin => 'u' } };
  $got = statements(model(t => [ $ai->(1, 1) ]), $tgt);
  is scalar @$got, 4, '... AUTO_INCREMENT kept without the key: release, drop, the index, the attribute back' or diag explain $got;
  unlike $got->[0], qr/AUTO_INCREMENT/, '... released first';
  is $got->[1], 'ALTER TABLE `t` DROP PRIMARY KEY;', '... the drop';
  like $got->[2], qr/CREATE UNIQUE INDEX `u`/, '... the key it has now';
  like $got->[3], qr/MODIFY COLUMN `id`.*AUTO_INCREMENT/, '... the attribute back, last';
}
{
  # every column of the key goes: the server takes the key along
  my $got = statements(model(t => [ [a => 1], [b => 2], 'c' ]), model(t => ['c']));
  is_deeply $got, [ 'ALTER TABLE `t` DROP COLUMN `a`;', 'ALTER TABLE `t` DROP COLUMN `b`;' ],
    '... all columns of the key dropped: no statement for the key (the server drops it with the last column)';
  # another key whose old columns are all gone: an ADD, not a replace
  $got = statements(model(t => [ [a => 1], 'b' ]), model(t => [ 'b' ]));
  is_deeply $got, [ 'ALTER TABLE `t` DROP COLUMN `a`;' ], '... the same for the key being dropped by the column drop';
  $got = statements(model(t => [ [a => 1], 'b' ]), model(t => [ [b => 1] ]));
  is_deeply $got, [ 'ALTER TABLE `t` DROP COLUMN `a`;', 'ALTER TABLE `t` ADD PRIMARY KEY (`b`);' ],
    '... a new key after the old one went with its column: ADD, not DROP PRIMARY KEY, ADD';
}

# --- 9. foreign keys that need the old key ---
sub fk {
  my (%o) = @_;
  return { constraint_name => 'fk1', from_columns => ['pa'], to_table => 'p', to_columns => ['a'],
           on_update => 'NO ACTION', on_delete => 'NO ACTION', %o };
}
sub with_fks {
  my ($m, %fks) = @_;
  $m->{foreign_keys} = { map { $_ => [ @{ $fks{$_} } ] } keys %fks };
  return $m;
}
sub fk_models {
  my ($p_src, $p_tgt, $src_fks, $tgt_fks) = @_;
  my $child = sub { [ { column_name => 'id', is_pk => 1, pk_position => 1 }, 'pa' ] };
  return (
    with_fks(model(p => $p_src, c => $child->()), %$src_fks),
    with_fks(model(p => $p_tgt, c => $child->()), %{ $tgt_fks // $src_fks }),
  );
}
{
  # child FK over a, key (a, b) becomes (b, a): the new key does not start with a
  # (the target has a unique index over a, which is created by the same diff)
  my $u = sub { $_[0]{indexes}{p} = { u => { index_name => 'u', is_unique => 1, columns => ['a'], index_type => 'BTREE', origin => 'u' } } };
  my @m = fk_models([ [a => 1], [b => 2] ], [ [a => 2], [b => 1] ], { c => [ fk() ] });
  $u->($m[1]);
  is_deeply statements(@m), [
    'ALTER TABLE `c` DROP FOREIGN KEY `fk1`;',
    'ALTER TABLE `p` DROP PRIMARY KEY, ADD PRIMARY KEY (`b`, `a`);',
    'CREATE UNIQUE INDEX `u` ON `p` (`a`) USING BTREE;',
    'ALTER TABLE `c` ADD CONSTRAINT `fk1` FOREIGN KEY (`pa`) REFERENCES `p`(`a`);',
  ], '9. a child FK that needs the old key: dropped before, added after the key and the index that takes its place';

  # the new key starts with a: the FK keeps its index
  @m = fk_models([ [a => 1], [b => 2] ], [ [a => 1], 'b' ], { c => [ fk() ] });
  is_deeply statements(@m), [ 'ALTER TABLE `p` DROP PRIMARY KEY, ADD PRIMARY KEY (`a`);' ],
    '... the new key serves it: the FK is left alone';

  # key dropped, a unique index over a stays
  @m = fk_models([ [a => 1], 'b' ], [ 'a', 'b' ], { c => [ fk() ] });
  for my $m (@m[0, 1]) { $m->{indexes}{p} = { u => { index_name => 'u', is_unique => 1, columns => ['a'], index_type => 'BTREE', origin => 'u' } } }
  is_deeply statements(@m), [ 'ALTER TABLE `p` DROP PRIMARY KEY;' ], '... another index that stays serves it: the FK is left alone';

  # key dropped, no other index: the target declares no FK any more -> the FK diff drops it, once
  @m = fk_models([ [a => 1], 'b' ], [ 'a', 'b' ], { c => [ fk() ] }, { c => [] });
  is_deeply statements(@m), [ 'ALTER TABLE `c` DROP FOREIGN KEY `fk1`;', 'ALTER TABLE `p` DROP PRIMARY KEY;' ],
    '... a FK that leaves the model is dropped once, not twice, and not added';

  # a changed FK (other action) is dropped and added by the FK diff: once each
  @m = fk_models([ [a => 1], [b => 2] ], [ [a => 2], [b => 1] ], { c => [ fk() ] }, { c => [ fk(on_delete => 'CASCADE') ] });
  $u->($m[1]);
  is_deeply statements(@m), [
    'ALTER TABLE `c` DROP FOREIGN KEY `fk1`;',
    'ALTER TABLE `p` DROP PRIMARY KEY, ADD PRIMARY KEY (`b`, `a`);',
    'CREATE UNIQUE INDEX `u` ON `p` (`a`) USING BTREE;',
    'ALTER TABLE `c` ADD CONSTRAINT `fk1` FOREIGN KEY (`pa`) REFERENCES `p`(`a`) ON DELETE CASCADE;',
  ], '... a FK that changes anyway: one drop, one add (the new definition)';

  # a FK of the table itself over the old key
  my $own = fk(from_columns => ['a'], to_table => 'q', to_columns => ['id'], constraint_name => 'own');
  my $src = with_fks(model(p => [ [a => 1], [b => 2] ], q => [ [id => 1] ]), p => [ $own ]);
  my $tgt = with_fks(model(p => [ [a => 2], [b => 1] ], q => [ [id => 1] ]), p => [ $own ]);
  is_deeply statements($src, $tgt), [
    'ALTER TABLE `p` DROP FOREIGN KEY `own`;',
    'ALTER TABLE `p` DROP PRIMARY KEY, ADD PRIMARY KEY (`b`, `a`);',
    'ALTER TABLE `p` ADD CONSTRAINT `own` FOREIGN KEY (`a`) REFERENCES `q`(`id`);',
  ], '... a FK of the table itself over the old key: the same';

  # a FK over b: the old key (a, b) does not start with b, it was no index for it
  @m = fk_models([ [a => 1], [b => 2] ], [ [a => 2], [b => 1] ], { c => [ fk(to_columns => ['b'], constraint_name => 'fkb') ] });
  is_deeply statements(@m), [ 'ALTER TABLE `p` DROP PRIMARY KEY, ADD PRIMARY KEY (`b`, `a`);' ],
    '... a FK the old key was no index for: left alone';
}
{
  # refused: the TARGET declares a FK on a column it has no key over any more
  my @m = fk_models([ [a => 1], 'b' ], [ 'a', 'b' ], { c => [ fk() ] });
  my $err = do { local $@; eval { DBIO::MySQL::Diff->new(source => $m[0], target => $m[1])->operations; 1 } ? '' : $@ };
  isa_ok $err, 'DBIO::Exception', '... a target FK on a key the target no longer has';
  like "$err", qr/\bp\b.*\bfk1\b|\bfk1\b.*\bp\b/s, '... the exception names table and constraint';
}

# --- 10. a new AUTO_INCREMENT key column ---
{
  my $s = model(t => ['k']);
  my $t = model(t => [ { column_name => 'id', is_pk => 1, pk_position => 1, is_auto_increment => 1 }, 'k' ]);
  is_deeply statements($s, $t), [ 'ALTER TABLE `t` ADD COLUMN `id` int(11) NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (`id`);' ],
    '10. a new AUTO_INCREMENT key column: ADD COLUMN and ADD PRIMARY KEY in one ALTER TABLE';

  my $s2 = model(t => [ [a => 1], 'k' ]);
  my $t2 = model(t => [ { column_name => 'id', is_pk => 1, pk_position => 1, is_auto_increment => 1 }, { column_name => 'a', is_pk => 1, pk_position => 2 }, 'k' ]);
  is_deeply statements($s2, $t2), [ 'ALTER TABLE `t` ADD COLUMN `id` int(11) NOT NULL AUTO_INCREMENT, DROP PRIMARY KEY, ADD PRIMARY KEY (`id`, `a`);' ],
    '... and with an old key to replace: one ALTER TABLE as well';
}

done_testing;
