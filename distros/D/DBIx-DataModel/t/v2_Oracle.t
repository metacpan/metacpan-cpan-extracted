use strict;
use warnings;

use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use DBIx::DataModel -compatibility=> undef;

use constant NTESTS  => 12;
use Test::More tests => NTESTS;


SKIP: {
  eval "use DBD::Oracle; 1"
    or skip "DBD::Oracle is not installed", NTESTS;

  # declare datamodel
  eval "use DBIx::DataModel::Statement::Oracle; 1";
  DBIx::DataModel->Schema(
    'ORA',
    statement_class => 'DBIx::DataModel::Statement::Oracle'
   )->Table(All_tables => ALL_TABLES => qw/TABLE_NAME OWNER/);

  # connect to DB
  $ENV{DBI_DSN}
    or skip "ENV{DBI_DSN} is not defined", NTESTS;
  my $dbh = DBI->connect(undef, undef, undef, 
                         {RaiseError => 1, AutoCommit => 1});
  ORA->dbh($dbh);
  my $source = ORA->table('All_tables');

  # initial data through regular API (to be compared with limit/offset API)
  my $tables = $source->select(-columns   => 'TABLE_NAME',
                               -order_by  => 'TABLE_NAME',);

  # test scrollable cursors
  my $slice = $source->select(-columns   => 'TABLE_NAME',
                              -order_by  => 'TABLE_NAME',
                              -limit     => 3);
  is_deeply($slice, [@{$tables}[0..2]],  "-limit without offset");

  $slice = $source->select(-columns   => 'TABLE_NAME',
                           -order_by  => 'TABLE_NAME',
                           -offset    => 0,
                           -limit     => 3);
  is_deeply($slice, [@{$tables}[0..2]], "-limit with offset 0");

  $slice = $source->select(-columns   => 'TABLE_NAME',
                           -order_by  => 'TABLE_NAME',
                           -offset    => 1,
                           -limit     => 3);
  is_deeply($slice, [@{$tables}[1..3]], "-limit with offset 1");

  $slice = $source->select(-columns   => 'TABLE_NAME',
                           -order_by  => 'TABLE_NAME',
                           -offset    => 2,
                           -limit     => 3);
  is_deeply($slice, [@{$tables}[2..4]], "-limit with offset 2");


  $slice = $source->select(-columns   => 'TABLE_NAME',
                           -order_by  => 'TABLE_NAME',
                           -page_index => 3,
                           -page_size  => 3);
  is_deeply($slice, [@{$tables}[6..8]], "-page_size/page_index");

  $slice = $source->select(-columns   => 'TABLE_NAME',
                           -order_by  => 'TABLE_NAME',
                           -offset    => scalar(@$tables)-2,
                           -limit     => 5);
  is_deeply($slice, [@{$tables}[-2 .. -1]], "-limit/-offset at end of data");


  my $row = $source->select(-columns   => 'TABLE_NAME',
                            -order_by  => 'TABLE_NAME',
                            -offset    => 2,
                            -result_as => 'firstrow');
  is_deeply($row, $tables->[2], "offset 2, single row");

 
  my $stmt = $source->select(-columns   => 'TABLE_NAME',
                             -order_by  => 'TABLE_NAME',
                             -offset    => 2,
                             -result_as => 'fast_statement');
  $row = $stmt->next;
  is_deeply($row, $tables->[2], "offset 2, reusable row (1/2)");
  $row = $stmt->next;
  is_deeply($row, $tables->[3], "offset 2, reusable row (2/2)");

  # row count
  is($stmt->row_count, scalar(@$tables), "row_count");
  $row = $stmt->next;
  is_deeply($row, $tables->[4], "next() after row_count()");


  # limit
  $stmt = $source->select(-columns   => 'TABLE_NAME',
                          -order_by  => 'TABLE_NAME',
                          -offset    => 2,
                          -limit     => 3,
                          -result_as => 'statement');
  my $rows = $stmt->next(10);
  is_deeply($rows, [@$tables[2,3,4]], "limit")
}


