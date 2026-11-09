use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k94 and karr k81: where the foreign key statements stand
# among the table and the index statements of one diff. The live half is t/90,
# which asks the servers; this file pins the order the diff writes, for two
# hand made models.
#
# WHY THE ORDER MATTERS. The server refuses a statement while a constraint
# needs what it takes away: DROP INDEX of an index a foreign key needs (1553),
# DROP TABLE of a table a constraint references (3730 / 1451), a constraint
# whose referenced columns have no index yet (1822 / errno 150). So
#   k94  the foreign keys that leave are dropped first, before the tables and
#        the indexes -- also a constraint of a dropped table into another
#        dropped table -- and those that arrive last;
#   k81  a foreign key of a new table that needs an index the same diff
#        creates is added after the index and is not in the CREATE TABLE; and
#        the drop of an index a foreign key that stays needs is preceded by
#        the index that takes its place, or the diff dies.

use DBIO::MySQL::Diff;

my $int = sub { { column_name => $_[0], column_type => 'int(11)', not_null => 1, is_pk => ($_[1] ? 1 : 0) } };
my $fk  = sub {
  my ($name, $from, $to, $to_col) = @_;
  return { constraint_name => $name, from_columns => [$from], to_table => $to,
    to_columns => [$to_col], on_update => 'NO ACTION', on_delete => 'NO ACTION' };
};
my $key = sub {
  my ($name, $unique, @columns) = @_;
  return $name => { index_name => $name, is_unique => $unique ? 1 : 0, columns => [@columns],
    index_type => 'BTREE', origin => $unique ? 'u' : 'c' };
};

# table => [ [columns...], { indexes }, [ fks ] ], columns by name, the first
# of them the primary key.
sub model {
  my (%t) = @_;
  return {
    tables       => { map { $_ => { table_name => $_, engine => 'InnoDB' } } keys %t },
    columns      => { map { my $n = $_; $n => [ map { $int->($_, $_ eq $t{$n}[0][0]) } @{ $t{$n}[0] } ] } keys %t },
    indexes      => { map { $_ => ($t{$_}[1] // {}) } keys %t },
    foreign_keys => { map { $_ => $t{$_}[2] } grep { $t{$_}[2] && @{ $t{$_}[2] } } keys %t },
  };
}
sub statements {
  my ($source, $target) = @_;
  return [ map { $_->as_sql =~ s/\s+/ /gr } @{ DBIO::MySQL::Diff->new(source => $source, target => $target)->operations } ];
}
sub create_table {
  my ($name, @cols) = @_;
  return "CREATE TABLE `$name` ( " . join(', ', @cols) . " ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";
}

# --- k94: the constraint goes before the index it needed and the table it references ---
{
  my %author = (author => [ ['id'] ]);
  # The server's index over the referencing column is in the source model and,
  # the schema having no index of its own over it, not in the target.
  my $with = model(%author, book => [ [qw(id author_id)], { $key->(author_id => 0, 'author_id') },
    [ $fk->(book_ibfk_1 => 'author_id', 'author', 'id') ] ]);
  my $without = model(%author, book => [ [qw(id author_id)] ]);

  is_deeply statements($with, $without), [
    'ALTER TABLE `book` DROP FOREIGN KEY `book_ibfk_1`;',
    'DROP INDEX `author_id` ON `book`;',
  ], 'k94: the constraint is dropped before the index the server made for it';

  my $none = model(other => [ ['id'] ]);
  is_deeply statements(
    model(other => [ ['id'] ], %author, book => [ [qw(id author_id)],
      { $key->(author_id => 0, 'author_id') }, [ $fk->(book_ibfk_1 => 'author_id', 'author', 'id') ] ]),
    $none,
  ), [
    'ALTER TABLE `book` DROP FOREIGN KEY `book_ibfk_1`;',
    'DROP TABLE `author`;',
    'DROP TABLE `book`;',
  ], 'k94: both tables leave: the constraint of the referencing one is dropped before either DROP TABLE';

  is_deeply statements($with, model(book => [ [qw(id author_id)] ])), [
    'ALTER TABLE `book` DROP FOREIGN KEY `book_ibfk_1`;',
    'DROP TABLE `author`;',
    'DROP INDEX `author_id` ON `book`;',
  ], 'k94: the referenced table leaves, the referencing one stays: constraint, table, index';

  is_deeply statements(
    model(%author, book => [ [qw(id author_id)], { $key->(author_id => 0, 'author_id') },
      [ $fk->(book_ibfk_1 => 'author_id', 'author', 'id') ] ]),
    model(%author, book => [ [qw(id author_id)], { $key->(author_id => 0, 'author_id') },
      [ $fk->(book_ibfk_1 => 'author_id', 'author', 'id') ] ]),
  ), [], 'nothing changes: nothing is written';

  is_deeply statements(model(%author), model(%author, book => [ [qw(id author_id)], {},
      [ $fk->(book_ibfk_1 => 'author_id', 'author', 'id') ] ])), [
    create_table(book => '`id` int(11) NOT NULL', '`author_id` int(11) NOT NULL',
      'PRIMARY KEY (`id`)', 'CONSTRAINT `book_ibfk_1` FOREIGN KEY (`author_id`) REFERENCES `author`(`id`)'),
  ], 'a new table with a foreign key to a primary key: the constraint stays in the CREATE TABLE';

  # A changed constraint is a drop and an add: the drop first, the add last.
  my $changed = model(%author, book => [ [qw(id author_id)], { $key->(author_id => 0, 'author_id') },
    [ { %{ $fk->(book_ibfk_1 => 'author_id', 'author', 'id') }, on_delete => 'CASCADE' } ] ]);
  is_deeply statements($with, $changed), [
    'ALTER TABLE `book` DROP FOREIGN KEY `book_ibfk_1`;',
    'ALTER TABLE `book` ADD CONSTRAINT `book_ibfk_1` FOREIGN KEY (`author_id`) REFERENCES `author`(`id`) ON DELETE CASCADE;',
  ], 'a changed constraint: dropped first, added last';
}

# --- k81 1: the foreign key of a new table into a key the diff creates ---
{
  my $parent = sub { model(
    parent => [ [qw(id code)], { $key->(uniq_code => 1, 'code') } ],
    child  => [ [qw(id parent_code)], { $key->(parent_code => 0, 'parent_code') },
      [ $fk->(child_ibfk_1 => 'parent_code', 'parent', 'code') ] ],
  ) };
  is_deeply statements(model(other => [ ['id'] ]), do { my $m = $parent->(); $m->{tables}{other} = {}; $m->{columns}{other} = [ $int->('id', 1) ]; $m->{indexes}{other} = {}; $m }), [
    create_table(child => '`id` int(11) NOT NULL', '`parent_code` int(11) NOT NULL', 'PRIMARY KEY (`id`)'),
    create_table(parent => '`id` int(11) NOT NULL', '`code` int(11) NOT NULL', 'PRIMARY KEY (`id`)'),
    'CREATE INDEX `parent_code` ON `child` (`parent_code`) USING BTREE;',
    'CREATE UNIQUE INDEX `uniq_code` ON `parent` (`code`) USING BTREE;',
    'ALTER TABLE `child` ADD CONSTRAINT `child_ibfk_1` FOREIGN KEY (`parent_code`) REFERENCES `parent`(`code`);',
  ], 'k81 1: parent and child are new: the unique key is created, and the constraint is added after it';

  # The parent already there with the key: nothing to wait for on the parent
  # side. The child has no index of its own over parent_code here -- one the
  # diff creates would defer the constraint for its own reason (karr k92, the
  # case below).
  my $with_key = model(parent => [ [qw(id code)], { $key->(uniq_code => 1, 'code') } ]);
  is_deeply statements($with_key, model(
    parent => [ [qw(id code)], { $key->(uniq_code => 1, 'code') } ],
    child  => [ [qw(id parent_code)], {}, [ $fk->(child_ibfk_1 => 'parent_code', 'parent', 'code') ] ],
  )), [
    create_table(child => '`id` int(11) NOT NULL', '`parent_code` int(11) NOT NULL', 'PRIMARY KEY (`id`)',
      'CONSTRAINT `child_ibfk_1` FOREIGN KEY (`parent_code`) REFERENCES `parent`(`code`)'),
  ], '... and when the parent has the key already, the constraint stays in the CREATE TABLE';
}

# --- k92: the foreign key of a new table over columns an index of the diff covers ---
# In the CREATE TABLE the server makes an index of its own for the constraint;
# the CREATE INDEX of the diff over the same columns would then be a second
# one. Added after the index, the constraint finds it there, and gets the name
# the target has.
{
  my %parent = (parent => [ ['id'] ]);
  is_deeply statements(model(%parent), model(%parent,
    child => [ [qw(id parent_id)], { $key->(parent_id => 0, 'parent_id') },
      [ $fk->(child_ibfk_1 => 'parent_id', 'parent', 'id') ] ],
  )), [
    create_table(child => '`id` int(11) NOT NULL', '`parent_id` int(11) NOT NULL', 'PRIMARY KEY (`id`)'),
    'CREATE INDEX `parent_id` ON `child` (`parent_id`) USING BTREE;',
    'ALTER TABLE `child` ADD CONSTRAINT `child_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `parent`(`id`);',
  ], 'k92: the child has an index over the column of the constraint: the index first, then the constraint';
}

# --- k81 2: an index a foreign key that stays needs is not dropped before its replacement ---
{
  my $fkc = $fk->(child_ibfk_1 => 'parent_code', 'parent', 'code');
  my $child = [ [qw(id parent_code)], { $key->(parent_code => 0, 'parent_code') }, [ $fkc ] ];
  my $from = model(parent => [ [qw(id code region)], { $key->(uniq_code => 1, 'code') } ], child => $child);

  is_deeply statements($from, model(
    parent => [ [qw(id code region)], { $key->(uniq_pair => 1, 'code', 'region') } ], child => $child,
  )), [
    'CREATE UNIQUE INDEX `uniq_pair` ON `parent` (`code`, `region`) USING BTREE;',
    'DROP INDEX `uniq_code` ON `parent`;',
  ], 'k81 2: another name: the replacement is created before the drop';

  is_deeply statements($from, model(
    parent => [ [qw(id code region)], { $key->(uniq_code => 1, 'code', 'region') } ], child => $child,
  )), [
    'ALTER TABLE `parent` DROP INDEX `uniq_code`, ADD UNIQUE INDEX `uniq_code` (`code`, `region`) USING BTREE;',
  ], '... the same name: drop and add are one statement';

  is_deeply statements($from, model(
    parent => [ [qw(id code region extra)], { $key->(uniq_code => 1, 'code', 'extra') } ], child => $child,
  )), [
    'ALTER TABLE `parent` ADD COLUMN `extra` int(11) NOT NULL;',
    'ALTER TABLE `parent` DROP INDEX `uniq_code`, ADD UNIQUE INDEX `uniq_code` (`code`, `extra`) USING BTREE;',
  ], '... over a column that is new: the column first, then the one statement';

  is_deeply statements($from, model(
    parent => [ [qw(id code region extra)], { $key->(uniq_new => 1, 'code', 'extra') } ], child => $child,
  )), [
    'ALTER TABLE `parent` ADD COLUMN `extra` int(11) NOT NULL;',
    'CREATE UNIQUE INDEX `uniq_new` ON `parent` (`code`, `extra`) USING BTREE;',
    'DROP INDEX `uniq_code` ON `parent`;',
  ], '... another name over a column that is new: column, create, drop';

  # Another index over the column is left: nothing to put in front.
  my $two = model(parent => [ [qw(id code region)],
    { $key->(uniq_code => 1, 'code'), $key->(k_code => 0, 'code') } ], child => $child);
  is_deeply statements($two, model(
    parent => [ [qw(id code region)], { $key->(k_code => 0, 'code') } ], child => $child,
  )), [ 'DROP INDEX `uniq_code` ON `parent`;' ],
    '... and when another index over the columns stays, the drop is written as it was';

  # The constraint goes with the index: the drop of the constraint comes first.
  is_deeply statements($from, model(
    parent => [ [qw(id code region)], {} ],
    child  => [ [qw(id parent_code)], { $key->(parent_code => 0, 'parent_code') } ],
  )), [
    'ALTER TABLE `child` DROP FOREIGN KEY `child_ibfk_1`;',
    'DROP INDEX `uniq_code` ON `parent`;',
  ], '... and when the constraint leaves as well, it is dropped, and then the index';

  # No index takes its place: the diff refuses.
  ok !eval { statements($from, model(
    parent => [ [qw(id code region)], {} ], child => $child,
  )); 1 }, '... and where no index takes its place the diff dies, writing no statement the server would refuse';
  like $@, qr/index uniq_code on parent is dropped.*no index of this diff takes its place/s,
    '... and says which index and why';
  isa_ok $@, 'DBIO::Exception', '... the error (karr k106)';
}

done_testing;
