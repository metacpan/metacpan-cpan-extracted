use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# OFFLINE half of karr k112 (t/138 has the live half): install_ddl of a table
# with an AUTO_INCREMENT column that is NOT in the primary key.
#
# WHY IT MATTERS. The server accepts such a column only as a key of the table
# at the moment the table is created ("there can be only one auto column and it
# must be defined as a key", 1075). install_ddl wrote every mysql_index and
# idx as a CREATE INDEX after the CREATE TABLE, so the CREATE TABLE itself was
# refused. The diff has put that key into the CREATE TABLE since k107; install
# does the same now, and the key is then not written a second time.

{
  package K112::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
sub result {
  my ($name, $table, $setup) = @_;
  my $class = "K112::Schema::Result::$name";
  eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
  $class->table($table);
  $class->add_columns(
    id   => { data_type => 'int' },
    seq  => { data_type => 'int', is_auto_increment => 1 },
    note => { data_type => 'int' },
  );
  $class->set_primary_key('id');
  $setup->($class);
  K112::Schema->register_class($name => $class);
}

result(Uniq  => 'uniq_t',  sub { $_[0]->mysql_index(k_seq => { columns => ['seq'], unique => 1 }) });
result(Plain => 'plain_t', sub { $_[0]->mysql_index(k_seq => { columns => ['seq'] }) });
result(Typed => 'typed_t', sub { $_[0]->mysql_index(k_seq => { columns => ['seq'], using => 'BTREE' }) });
result(Other => 'other_t', sub {
  $_[0]->mysql_index(k_seq => { columns => ['seq'], unique => 1 });
  $_[0]->mysql_index(i_note => { columns => ['note'] });
});
result(Canon => 'canon_t', sub {
  $_[0]->result_source_instance->add_index_declaration({ name => 'k_seq', columns => ['seq'], type => 'unique' });
});
result(Cons => 'cons_t', sub { $_[0]->add_unique_constraint(u_seq => ['seq']) });

my @all = split /\n\n/, DBIO::MySQL::DDL->install_ddl('K112::Schema');
sub for_table {
  my ($t) = @_;
  my @s = map { s/\s+/ /gr } grep { /`\Q$t\E`/ } @all;
  return \@s;
}

my $tail = ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;';

is_deeply for_table('uniq_t'), [
  'CREATE TABLE `uniq_t` ( `id` int NOT NULL, `seq` int NOT NULL AUTO_INCREMENT, `note` int NOT NULL, '
  . 'PRIMARY KEY (`id`), UNIQUE KEY `k_seq` (`seq`) ' . $tail ],
  'a: the UNIQUE mysql_index of the AUTO_INCREMENT column stands in the CREATE TABLE, once';

is_deeply for_table('plain_t'), [
  'CREATE TABLE `plain_t` ( `id` int NOT NULL, `seq` int NOT NULL AUTO_INCREMENT, `note` int NOT NULL, '
  . 'PRIMARY KEY (`id`), KEY `k_seq` (`seq`) ' . $tail ],
  'b: a plain index serves as the key as well';

is_deeply for_table('typed_t'), [
  'CREATE TABLE `typed_t` ( `id` int NOT NULL, `seq` int NOT NULL AUTO_INCREMENT, `note` int NOT NULL, '
  . 'PRIMARY KEY (`id`), KEY `k_seq` (`seq`) USING BTREE ' . $tail ],
  'c: the index type is kept';

{
  my $got = for_table('other_t');
  is scalar(@$got), 2, 'd: two statements';
  like $got->[0], qr/UNIQUE KEY `k_seq` \(`seq`\)/, 'd: the key of seq is inline';
  unlike $got->[0], qr/i_note/, 'd: the other index is not';
  is $got->[1], 'CREATE INDEX `i_note` ON `other_t` (`note`);', 'd: ... it follows the table';
}

like for_table('canon_t')->[0], qr/UNIQUE KEY `k_seq` \(`seq`\)/, 'e: the canonical declaration (idx) is inline too';
is scalar(@{ for_table('canon_t') }), 1, 'e: ... and not written again';

is scalar(@{ for_table('cons_t') }), 1, 'f: a unique constraint over the column stays the one key, no statement after';

done_testing;
