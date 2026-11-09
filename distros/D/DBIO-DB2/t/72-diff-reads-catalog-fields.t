use strict;
use warnings;

use Test::More;

use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Table;
use DBIO::DB2::Diff::Column;

# OFFLINE (karr k44, ADR 0013). A column of the model carries two descriptions:
# the normalized one (data_type, size, default_value -- what DBIO::Generate
# reads) and the catalog's own (catalog_type, catalog_size, catalog_default --
# what the diff renders and compares). The diff reads the second only. Each test
# here makes the two disagree on purpose, so it fails if an operation reads the
# wrong one.

sub col {
  my (%c) = @_;
  return { not_null => 0, %c };
}

sub model {
  my ($cols) = @_;
  return {
    tables       => { t => { table_name => 't', kind => 'table' } },
    columns      => { t => $cols },
    indexes      => {}, foreign_keys => {},
  };
}

sub ops_of {
  my ($source, $target) = @_;
  return @{ DBIO::DB2::Diff->new(source => $source, target => $target)->operations };
}

my $id = col(column_name => 'id', is_pk => 1, pk_position => 1, not_null => 1,
  data_type => 'integer', catalog_type => 'INTEGER', catalog_size => 4);

# 1. The normalized fields differ, the catalog's do not: no operation.
{
  my @ops = ops_of(
    model([ $id, col(column_name => 'n', data_type => 'varchar', size => 10,
                     default_value => 'a', catalog_type => 'VARCHAR', catalog_size => 10,
                     catalog_default => q{'a'}) ]),
    model([ $id, col(column_name => 'n', data_type => 'text', size => 99,
                     default_value => \'USER', catalog_type => 'VARCHAR', catalog_size => 10,
                     catalog_default => q{'a'}) ]),
  );
  is scalar @ops, 0, 'a difference in the normalized fields alone is no operation';
}

# 2. The catalog's differ, the normalized do not: the operation is built from
#    the catalog fields.
{
  my @ops = ops_of(
    model([ $id, col(column_name => 'n', data_type => 'varchar', size => 10,
                     catalog_type => 'VARCHAR', catalog_size => 10,
                     catalog_default => q{'old'}) ]),
    model([ $id, col(column_name => 'n', data_type => 'varchar', size => 10,
                     catalog_type => 'VARCHAR', catalog_size => 40,
                     catalog_default => q{'it''s'}) ]),
  );
  is scalar @ops, 1, 'a difference in the catalog fields is one operation';
  is $ops[0]->as_sql,
    qq{ALTER TABLE "t" ALTER COLUMN "n" SET DATA TYPE VARCHAR(40);\n}
  . qq{ALTER TABLE "t" ALTER COLUMN "n" SET DEFAULT 'it''s';},
    'type, size and default are written from catalog_type, catalog_size, catalog_default';
}

# 3. A created table and an added column render the catalog fields.
{
  my @cols = (
    $id,
    col(column_name => 'name', data_type => 'zzz', size => [ 1, 2 ], default_value => \'bogus',
        catalog_type => 'VARCHAR', catalog_size => 50, catalog_default => q{'x'}),
  );
  my @ops = ops_of({ tables => {}, columns => {}, indexes => {}, foreign_keys => {} }, model(\@cols));
  my $sql = $ops[0]->as_sql;
  like $sql, qr/"name" VARCHAR\(50\) DEFAULT 'x'/, 'CREATE TABLE writes the catalog fields';
  unlike $sql, qr/zzz|bogus/, '... and nothing of the normalized ones';

  my @add = ops_of(model([ $id ]), model(\@cols));
  is $add[0]->as_sql, q{ALTER TABLE "t" ADD COLUMN "name" VARCHAR(50) DEFAULT 'x';},
    'ADD COLUMN writes the catalog fields';
}

# 4. The reorg rule is about the catalog's type.
{
  my @ops = ops_of(
    model([ $id, col(column_name => 'n', data_type => 'varchar', size => 10,
                     catalog_type => 'INTEGER', catalog_size => 4) ]),
    model([ $id, col(column_name => 'n', data_type => 'varchar', size => 10,
                     catalog_type => 'BIGINT', catalog_size => 8) ]),
  );
  my ($col) = grep { $_->isa('DBIO::DB2::Diff::Column') } @ops;
  ok $col->reorg_recommended, 'reorg_recommended follows catalog_type (INTEGER to BIGINT)';
}

done_testing;
