use strict;
use warnings;
use Test::More;

# OFFLINE half of karr k82 (t/118 has the live half): the CREATE TABLE of a diff
# names the same character set and collation as the one install_ddl writes.
#
# WHY: the diff wrote DEFAULT CHARSET=utf8mb4 and no COLLATE, so the server
# filled in its own default collation (utf8mb4_0900_ai_ci on MySQL 8,
# utf8mb4_uca1400_ai_ci on MariaDB 11), while install_ddl writes
# utf8mb4_unicode_ci. The text columns of a table an upgrade created then
# differed from the schema, and every later diff reported a MODIFY COLUMN that
# changed nothing. The claims:
#   1. the CREATE TABLE of a diff ends in the tail install_ddl ends its own in
#      (compared against install_ddl, not against a second copy of the string);
#   2. a table that carries a collation of its own keeps it.

use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::DDL;

{
  package K82::Result::Note;
  use base 'DBIO::Core';
  __PACKAGE__->table('note');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package K82::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
K82::Schema->register_class(Note => 'K82::Result::Note');

sub tail { my ($sql) = @_; $sql =~ /(\) ENGINE=[^\n]*;)\s*\z/ ? $1 : "no tail in: $sql" }

my $install = DBIO::MySQL::DDL->install_ddl('K82::Schema');
my ($install_create) = $install =~ /(CREATE TABLE `note`.*?;)/s;

my @columns = (
  { column_name => 'id',    column_type => 'int',          not_null => 1, is_auto_increment => 1, is_pk => 1, pk_position => 1 },
  { column_name => 'title', column_type => 'varchar(100)', not_null => 1 },
);
my $create = DBIO::MySQL::Diff::Table->new(
  action => 'create', table_name => 'note', table_info => { table_name => 'note' }, columns => \@columns, foreign_keys => [],
)->as_sql;

like $create, qr/COLLATE=utf8mb4_unicode_ci;\z/, 'the CREATE TABLE of the diff names a collation';
is tail($create), tail($install_create), '... the tail install_ddl writes, character set and collation';

my $own = DBIO::MySQL::Diff::Table->new(
  action => 'create', table_name => 'note',
  table_info => { table_name => 'note', table_collation => 'latin1_swedish_ci' }, columns => \@columns, foreign_keys => [],
)->as_sql;
like $own, qr/DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;\z/, 'a table with a collation of its own keeps it';

done_testing;
