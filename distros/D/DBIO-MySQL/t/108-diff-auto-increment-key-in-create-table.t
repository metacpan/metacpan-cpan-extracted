use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k107 (t/109 has the live half): the upgrade of an empty
# database to a schema with an AUTO_INCREMENT column that is NOT in the primary
# key.
#
# WHY IT MATTERS. The server accepts an AUTO_INCREMENT column only when it is a
# key of the table at the moment the table is created ("there can be only one
# auto column and it must be defined as a key", 1075). The diff wrote the CREATE
# TABLE with the primary key only and the UNIQUE index of the column as a
# CREATE UNIQUE INDEX after it, so the CREATE TABLE itself was refused: an
# upgrade could not make what install_ddl makes. The key of that column belongs
# into the CREATE TABLE (as install_ddl writes it), and it must then not come
# a second time as an index of its own: the upgrade would fail on the
# duplicate name.

use DBIO::MySQL::Diff;

sub col {
  my ($name, %o) = @_;
  return { column_name => $name, column_type => 'int(11)', data_type => 'int', not_null => 1,
    is_pk => 0, is_auto_increment => 0, %o };
}
sub idx {
  my ($name, $unique, @columns) = @_;
  return $name => { index_name => $name, is_unique => $unique ? 1 : 0, columns => [@columns],
    index_type => 'BTREE', origin => $unique ? 'u' : 'c' };
}
sub model {
  my (%t) = @_;
  return {
    tables       => { map { $_ => { table_name => $_, engine => 'InnoDB' } } keys %t },
    columns      => { map { $_ => $t{$_}[0] } keys %t },
    indexes      => { map { $_ => ($t{$_}[1] // {}) } keys %t },
    foreign_keys => {},
  };
}
sub statements {
  my ($source, $target) = @_;
  my $ops = eval { DBIO::MySQL::Diff->new(source => $source, target => $target)->operations };
  return [ "the diff dies: $@" ] unless $ops;
  return [ map { $_->as_sql =~ s/\s+/ /gr } @$ops ];
}

my $empty = model();
my @cols = (col('id', is_pk => 1, pk_position => 1), col('seq', is_auto_increment => 1));

# a. UNIQUE key over the AUTO_INCREMENT column
is_deeply statements($empty, model(item => [ [@cols], { idx('k_item', 1, 'seq') } ])), [
  'CREATE TABLE `item` ( `id` int(11) NOT NULL, `seq` int(11) NOT NULL AUTO_INCREMENT, '
  . 'PRIMARY KEY (`id`), UNIQUE KEY `k_item` (`seq`) USING BTREE ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;',
], 'a: the UNIQUE index of the AUTO_INCREMENT column is in the CREATE TABLE and not a second statement';

# b. plain index over it
is_deeply statements($empty, model(item => [ [@cols], { idx('k_item', 0, 'seq') } ])), [
  'CREATE TABLE `item` ( `id` int(11) NOT NULL, `seq` int(11) NOT NULL AUTO_INCREMENT, '
  . 'PRIMARY KEY (`id`), KEY `k_item` (`seq`) USING BTREE ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;',
], 'b: a plain index serves as the key as well';

# c. other indexes stay statements of their own; only the key of the column moves
{
  my $got = statements($empty, model(item => [ [@cols, col('note')],
    { idx('k_item', 1, 'seq'), idx('i_note', 0, 'note') } ]));
  is scalar(@$got), 2, 'c: two statements';
  like $got->[0], qr/UNIQUE KEY `k_item`/, 'c: the key of seq is inline';
  unlike $got->[0], qr/i_note/, 'c: the other index is not';
  is $got->[1], 'CREATE INDEX `i_note` ON `item` (`note`) USING BTREE;', 'c: ... it follows the table';
}

# d. the AUTO_INCREMENT primary key needs nothing, and a table that exists is not touched
is_deeply statements($empty, model(item => [ [col('id', is_pk => 1, pk_position => 1, is_auto_increment => 1)] ])), [
  'CREATE TABLE `item` ( `id` int(11) NOT NULL AUTO_INCREMENT, PRIMARY KEY (`id`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;',
], 'd: an AUTO_INCREMENT primary key has no key but the primary key';
is_deeply statements(model(item => [ [col('id', is_pk => 1, pk_position => 1), col('seq', is_auto_increment => 1)] ]),
  model(item => [ [@cols], { idx('k_item', 1, 'seq') } ])), [
  'CREATE UNIQUE INDEX `k_item` ON `item` (`seq`) USING BTREE;',
], 'd: a table that exists gets its index as a statement, as before';

done_testing;
