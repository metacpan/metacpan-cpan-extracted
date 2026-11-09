use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;
use DBIO::MySQL::Diff;

# karr k122, offline half (t/172 has the live one): the diff compares a table
# named database.table in its database, as install makes it there (karr k120).
#
# WHY IT MATTERS. The diff read the current database alone, so a table of
# another database that a new version of the schema adds was neither compared
# nor created, and upgrade reported nothing to do: a silent omission. Claims:
#   1. install_ddl with { database => 'other' } is the install of that
#      database's tables alone, under the names they have there, without
#      views and without the tables of the current database;
#   2. a model with other_databases is diffed per database, and every
#      operation on such a table is written against `other`.`t`: CREATE TABLE,
#      ALTER TABLE ... ADD COLUMN, CREATE INDEX, DROP INDEX, and the summary
#      names the database;
#   3. the operations on another database come before those on the current one;
#   4. a table in the current database that is literally called `other.t` is
#      still one identifier (it is not the table of the database other);
#   5. a database only one side knows is diffed against an empty one -- nothing
#      is silently left out.

# 1.
{
  eval <<'PERL' or die $@;
package K122Off::Schema;
use DBIO 'Schema';
__PACKAGE__->load_components('MySQL');
package K122Off::Schema::Result::Here;
use DBIO 'Core', -mysql;
__PACKAGE__->table('here');
__PACKAGE__->add_columns(id => { data_type => 'int' });
__PACKAGE__->set_primary_key('id');
package K122Off::Schema::Result::There;
use DBIO 'Core', -mysql;
__PACKAGE__->table('other.there');
__PACKAGE__->add_columns(id => { data_type => 'int' }, v => { data_type => 'int', is_nullable => 1 });
__PACKAGE__->set_primary_key('id');
__PACKAGE__->mysql_index(by_v => { columns => ['v'] });
package K122Off::Schema::Result::Else;
use DBIO 'Core', -mysql;
__PACKAGE__->table('third.else');
__PACKAGE__->add_columns(id => { data_type => 'int' });
__PACKAGE__->set_primary_key('id');
K122Off::Schema->register_class(Here => 'K122Off::Schema::Result::Here');
K122Off::Schema->register_class(There => 'K122Off::Schema::Result::There');
K122Off::Schema->register_class(Else => 'K122Off::Schema::Result::Else');
1;
PERL
  my $ddl = DBIO::MySQL::DDL->install_ddl('K122Off::Schema', { database => 'other' });
  like $ddl, qr/CREATE TABLE `there` \(/, '1: the table of that database is made under its own name';
  like $ddl, qr/CREATE INDEX `by_v` ON `there` /, '1: ... with its index';
  unlike $ddl, qr/`here`|else|`other`|third/, '1: ... and nothing of the current database or of another one';
}

sub model {
  my (%tables) = @_;
  return {
    tables       => { map { $_ => { table_name => $_, kind => 'table', engine => 'InnoDB', table_collation => 'utf8mb4_unicode_ci' } } keys %tables },
    columns      => { map { my $t = $_; ($t => [ map { +{ column_name => $_->[0], data_type => 'int', column_type => 'int', not_null => $_->[1], is_pk => $_->[2] // 0 } } @{ $tables{$t}{columns} } ]) } keys %tables },
    indexes      => { map { $_ => { map { $_->[0] => { index_name => $_->[0], columns => $_->[1], is_unique => 0, origin => 'c' } } @{ $tables{$_}{indexes} // [] } } } keys %tables },
    foreign_keys => {},
  };
}
my $id = [ 'id', 1, 1 ];

# 2. + 3.
{
  my $source = model(here => { columns => [$id] });
  my $target = model(here => { columns => [$id, [ n => 0 ]] });
  $source->{other_databases}{other} = model(t => { columns => [$id], indexes => [ [ old_ix => ['id'] ] ] });
  $target->{other_databases}{other} = model(
    t => { columns => [ $id, [ extra => 0 ] ], indexes => [ [ new_ix => ['extra'] ] ] },
    u => { columns => [$id] },
  );
  my $diff = DBIO::MySQL::Diff->new(source => $source, target => $target);
  ok $diff->has_changes, '2: a change only in another database is a change';
  my $sql = $diff->as_sql;
  like $sql, qr/CREATE TABLE `other`\.`u` \(/, '2: a new table is created in its database';
  like $sql, qr/ALTER TABLE `other`\.`t` ADD COLUMN `extra`/, '2: a column is added to the table of the database';
  like $sql, qr/CREATE INDEX `new_ix` ON `other`\.`t` /, '2: an index is created on it';
  like $sql, qr/DROP INDEX `old_ix` ON `other`\.`t`;/, '2: an index is dropped from it';
  like $sql, qr/ALTER TABLE `here` ADD COLUMN `n`/, '... the current database is diffed as before';
  unlike $sql, qr/`other`\.`here`|`here`\.`/, '... and keeps its own names';
  cmp_ok index($sql, 'ALTER TABLE `here`'), '>', index($sql, 'CREATE TABLE `other`.`u`'),
    '3: the operations on the other database come first';
  like $diff->summary, qr/\(database other\)/, '2: the summary names the database';
  unlike((grep { /ALTER TABLE `here`/ } split /\n/, $sql)[0] // '', qr/other/, '... and only there');
  ok !(grep { $_->can('database') && defined $_->database } grep { $_->table_name eq 'here' } @{ $diff->operations }),
    '... no operation on the current database carries one';
}

# 4. a table literally called other.t in the current database
{
  my $source = model('other.t' => { columns => [$id] });
  my $target = model('other.t' => { columns => [$id, [ n => 0 ]] });
  my $sql = DBIO::MySQL::Diff->new(source => $source, target => $target)->as_sql;
  like $sql, qr/ALTER TABLE `other\.t` ADD COLUMN `n`/, '4: a table with a dot in its name is one identifier';
}

# 5. one side only
{
  my $empty = model();
  my $target = model(); $target->{other_databases}{only_target} = model(t => { columns => [$id] });
  like(DBIO::MySQL::Diff->new(source => $empty, target => $target)->as_sql, qr/CREATE TABLE `only_target`\.`t`/,
    '5: a database only the target knows is created in');
  my $source = model(); $source->{other_databases}{only_source} = model(t => { columns => [$id] });
  like(DBIO::MySQL::Diff->new(source => $source, target => model())->as_sql, qr/DROP TABLE `only_source`\.`t`/,
    '5: a database only the source knows is compared against nothing (not left out)');
}

done_testing;
