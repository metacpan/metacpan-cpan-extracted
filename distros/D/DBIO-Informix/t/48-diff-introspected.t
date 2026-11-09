use strict;
use warnings;
use Test::More;

# The diff has to work on what the introspector really produces (karr k20,
# measured against Informix 15.0.1): data_type and size are separate keys
# ('varchar' + 20, 'decimal' + [10,2]); a table that is created or dropped
# is not also added to or dropped from column by column.

use DBIO::Informix::Diff::Table;
use DBIO::Informix::Diff::Column;
use DBIO::Informix::ColumnDef qw(column_def_sql);

my @cols = (
  { column_name => 'id',    data_type => 'serial',  is_auto_increment => 1, not_null => 1, is_pk => 1, pk_position => 1 },
  { column_name => 'code',  data_type => 'varchar', size => 20, not_null => 1 },
  { column_name => 'price', data_type => 'decimal', size => [10, 2], default_value => '3.14' },
  { column_name => 'who',   data_type => 'char',    size => 8 },
  { column_name => 'n',     data_type => 'integer' },
);

# --- the size reaches the SQL: a bare VARCHAR is VARCHAR(1), DECIMAL is DECIMAL(16)
{
  my ($op) = DBIO::Informix::Diff::Table->diff({}, { t => { table_name => 't' } }, { t => \@cols });
  my $sql = $op->as_sql;
  like $sql, qr/code VARCHAR\(20\) NOT NULL/, 'create: varchar keeps its size';
  like $sql, qr/price DECIMAL\(10,2\) DEFAULT 3\.14/, 'create: decimal keeps precision and scale';
  like $sql, qr/who CHAR\(8\)/, 'create: char keeps its size';
  like $sql, qr/\bn integer\b/, 'create: a type without size is left as it is';

  my ($add) = DBIO::Informix::Diff::Column->diff(
    { t => [] }, { t => [ $cols[1] ] }, { t => 1 }, { t => 1 },
  );
  is $add->as_sql, 'ALTER TABLE t ADD (code VARCHAR(20) NOT NULL);', 'add column: varchar keeps its size';
}

# --- a created table is created, not also altered column by column
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    {}, { t => \@cols }, {}, { t => 1 },
  );
  is scalar @ops, 0, 'no ADD for the columns of a table that is created';
}

# --- a dropped table is dropped, not also stripped column by column
{
  my @ops = DBIO::Informix::Diff::Column->diff(
    { t => \@cols }, {}, { t => 1 }, {},
  );
  is scalar @ops, 0, 'no DROP COLUMN for the columns of a table that is dropped';
}

# --- Informix takes BOOLEAN and DATE literals quoted ('t', '01/02/2020');
# unquoted they are syntax errors
is column_def_sql(name => 'b', type => 'boolean', default_value => 't'), "b boolean DEFAULT 't'", 'boolean default quoted';
is column_def_sql(name => 'd', type => 'date', default_value => '01/02/2020'), "d date DEFAULT '01/02/2020'", 'date default quoted';

done_testing;
