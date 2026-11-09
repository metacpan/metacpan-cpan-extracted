use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Deploy;
use DBIO::MSSQL::Diff::Column;

# core k399, ADR 0080: apply and upgrade are DBIO::Deploy::Base's; the driver
# takes part through _check_before_apply (the rows of the live tables) and
# answers `lossy` per column operation, so that a type change that can lose
# values runs only with allow_destructive.

# --- apply is not overridden ---------------------------------------------
is(DBIO::MSSQL::Deploy->can('apply'), DBIO::Deploy::Base->can('apply'),
  'apply is the base class apply');
is(DBIO::MSSQL::Deploy->can('upgrade'), DBIO::Deploy::Base->can('upgrade'),
  'upgrade is the base class upgrade');
ok(!exists &DBIO::MSSQL::Deploy::apply, 'the driver defines no apply of its own');

# --- _refuse_unfillable runs through _check_before_apply ------------------
{
  my @seen;
  no warnings 'redefine';
  local *DBIO::MSSQL::Deploy::_refuse_unfillable = sub { push @seen, [ @_[1, 2] ] };
  local *DBIO::MSSQL::Deploy::_dbh = sub { 'the-handle' };
  my $deploy = bless {}, 'DBIO::MSSQL::Deploy';
  $deploy->_check_before_apply('the-diff');
  is_deeply \@seen, [ [ 'the-diff', 'the-handle' ] ],
    '_check_before_apply asks _refuse_unfillable with the diff and the live handle';
}

# --- lossy answers of the column operation --------------------------------
sub alter {
  my ($old, $new) = @_;
  DBIO::MSSQL::Diff::Column->new(action => 'alter', table_name => 't',
    column_name => 'c', old_info => $old, new_info => $new);
}
sub lossy { alter(@_)->lossy ? 1 : 0 }

my @cases = (
  [ 'varchar widened',          0, { data_type => 'varchar',  size => 20 }, { data_type => 'varchar',  size => 40 } ],
  [ 'nvarchar widened',         0, { data_type => 'nvarchar', size => 20 }, { data_type => 'nvarchar', size => 40 } ],
  [ 'nvarchar to max',          0, { data_type => 'nvarchar', size => 20 }, { data_type => 'nvarchar', size => -1 } ],
  [ 'nvarchar narrowed',        1, { data_type => 'nvarchar', size => 40 }, { data_type => 'nvarchar', size => 20 } ],
  [ 'nvarchar max to length',   1, { data_type => 'nvarchar', size => -1 }, { data_type => 'nvarchar', size => 4000 } ],
  [ 'varchar to nvarchar',      0, { data_type => 'varchar',  size => 20 }, { data_type => 'nvarchar', size => 20 } ],
  [ 'nvarchar to varchar (same rendered type, no statement)', 0, { data_type => 'nvarchar', size => 20 }, { data_type => 'varchar',  size => 20 } ],
  [ 'varchar to nvarchar, narrower', 1, { data_type => 'varchar', size => 20 }, { data_type => 'nvarchar', size => 10 } ],
  [ 'int to bigint',            0, { data_type => 'int' },      { data_type => 'bigint' } ],
  [ 'smallint to int',          0, { data_type => 'smallint' }, { data_type => 'int' } ],
  [ 'bigint to int',            1, { data_type => 'bigint' },   { data_type => 'int' } ],
  [ 'int to varchar',           1, { data_type => 'int' },      { data_type => 'varchar', size => 20 } ],
  [ 'datetime to datetime2',    1, { data_type => 'datetime' }, { data_type => 'datetime2' } ],
  [ 'date to datetime2',        0, { data_type => 'date' },     { data_type => 'datetime2' } ],
  [ 'nullability alone',        0, { data_type => 'nvarchar', size => 20, not_null => 0 }, { data_type => 'nvarchar', size => 20, not_null => 1 } ],
  [ 'default alone',            0, { data_type => 'int', default_value => '((0))' }, { data_type => 'int', default_value => '1' } ],
);
is lossy($_->[2], $_->[3]), $_->[1], $_->[0] for @cases;

ok !DBIO::MSSQL::Diff::Column->new(action => 'add', table_name => 't', column_name => 'c',
  new_info => { data_type => 'int' })->lossy, 'an added column is not lossy';

done_testing;
