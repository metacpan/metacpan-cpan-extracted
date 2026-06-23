use strict;
use warnings;
use Test::More;

use_ok 'DBIO::MySQL::Diff::Table';
use_ok 'DBIO::MySQL::Diff::Column';
use_ok 'DBIO::MySQL::Diff::Index';
use_ok 'DBIO::MySQL::Diff::ForeignKey';
use_ok 'DBIO::MySQL::Diff';

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

# --- Diff::Index create ---
{
  my @ops = DBIO::MySQL::Diff::Index->diff(
    {},
    { t => { idx_t_name => {
      index_name => 'idx_t_name', is_unique => 1,
      columns => ['name'], origin => 'c',
    }}},
  );
  is(scalar @ops, 1, 'one index create');
  is($ops[0]->as_sql, 'CREATE UNIQUE INDEX `idx_t_name` ON `t` (`name`);', 'create SQL');
}

# --- Diff::Index skips PK + UNIQUE constraint indexes ---
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
  is(scalar @ops, 0, 'auto indexes skipped');
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

done_testing;
