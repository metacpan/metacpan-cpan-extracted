use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Diff;

# OFFLINE half of karr k111 (t/140 has the live half): a column whose character
# set or collation differs from the default of its table is written by MODIFY
# COLUMN and ADD COLUMN.
#
# WHY IT MATTERS. as_sql wrote type, NOT NULL, DEFAULT and ON UPDATE but never the
# character set or collation, while the diff compares them. A column with a
# collation of its own (title utf8mb4_bin in a utf8mb4_unicode_ci table) was
# reported as MODIFY COLUMN by every diff, the statement reset it to the default
# of the table, and the next diff reported it again: the diff never converged.
#
# The decision (maintainer, 2026-10-24): the statement writes CHARACTER SET and
# COLLATE of the column where they differ from the table's default, compared as
# the introspection reports them (lower case, the character set taken from the
# collation's prefix when only that is known). A column on the default is written
# without, so every statement of before stays what it was. Claims:
#   1. MODIFY and ADD write CHARACTER SET + COLLATE after the type for a column
#      off the table default, and nothing for one on it;
#   2. a column with only a character set, or only a collation, writes that part;
#   3. a table whose default is unknown (target_from_compiled) writes what the
#      column says, and a column that says nothing writes nothing;
#   4. a table that is converted (karr k109) gives its columns the collation of
#      the table, so a column with a collation of its own follows with a MODIFY
#      that writes it -- the second diff is then empty;
#   5. CREATE TABLE of a diff writes it too, so a new table converges as well.

sub col {
  my ($name, $type, %o) = @_;
  my $text = $type =~ /char|text|enum|set/;
  return { column_name => $name, data_type => ($type =~ /\A(\w+)/)[0], column_type => $type,
    not_null => 1, character_set => $text ? $o{cs} : undef, collation => $text ? $o{co} : undef };
}
sub model {
  my ($table_collation, @cols) = @_;
  return {
    tables  => { t => { table_name => 't', kind => 'table', engine => 'InnoDB',
      (defined $table_collation ? (table_collation => $table_collation) : ()) } },
    columns => { t => [ @cols ] },
    indexes => {}, foreign_keys => {},
  };
}
sub sql { my ($old, $new) = @_; return [ map { $_->as_sql } @{ DBIO::MySQL::Diff->new(source => $old, target => $new)->operations } ] }

my $id = col(id => 'int');

# 1. MODIFY and ADD
is_deeply sql(
  model('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci')),
  model('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin')),
), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL;' ],
  'MODIFY writes the collation of a column that is off the table default, after the type';

is_deeply sql(
  model('utf8mb4_unicode_ci', $id),
  model('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'latin1', co => 'latin1_bin')),
), [ 'ALTER TABLE `t` ADD COLUMN `title` varchar(100) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL;' ],
  'ADD COLUMN writes it too';

is_deeply sql(
  model('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin')),
  model('utf8mb4_unicode_ci', $id, col(title => 'varchar(200)', cs => 'utf8mb4', co => 'UTF8MB4_UNICODE_CI')),
), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(200) NOT NULL;' ],
  'a column on the table default (case aside) is written without, as before';

# 2. one part only
is_deeply sql(
  model('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci')),
  model('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'latin1', co => undef)),
), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(100) CHARACTER SET latin1 NOT NULL;' ],
  'a character set alone is written alone';

# 3. unknown table default
is_deeply sql(
  model(undef, $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci')),
  model(undef, $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin')),
), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL;' ],
  'without a table default the collation of the column is written';
is_deeply sql(
  model(undef, $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin')),
  model(undef, $id, col(title => 'varchar(200)', cs => undef, co => undef)),
), [ 'ALTER TABLE `t` MODIFY COLUMN `title` varchar(200) NOT NULL;' ],
  '... and a column that names none writes none';

# 4. a converted table, a column with a collation of its own
{
  my @old = ($id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin'), col(body => 'longtext', cs => 'utf8mb4', co => 'utf8mb4_bin'));
  my @new = ($id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci'), col(body => 'longtext', cs => 'utf8mb4', co => 'utf8mb4_general_ci'));
  is_deeply sql(model('utf8mb4_bin', @old), model('utf8mb4_unicode_ci', @new)), [
    'ALTER TABLE `t` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;',
    'ALTER TABLE `t` MODIFY COLUMN `body` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;',
  ], 'CONVERT TO gives every column the table collation; a column with one of its own is modified after it';
}

# 5. CREATE TABLE
{
  my $target = model('utf8mb4_unicode_ci', $id, col(title => 'varchar(100)', cs => 'utf8mb4', co => 'utf8mb4_bin'), col(note => 'varchar(10)', cs => 'utf8mb4', co => 'utf8mb4_unicode_ci'));
  my $source = { tables => {}, columns => {}, indexes => {}, foreign_keys => {} };
  my ($sql) = @{ sql($source, $target) };
  like $sql, qr/^  `title` varchar\(100\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,$/m, 'CREATE TABLE writes the collation of a column off the default';
  like $sql, qr/^  `note` varchar\(10\) NOT NULL$/m, '... and none for one on it';
}

done_testing;
