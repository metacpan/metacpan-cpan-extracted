use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Deploy;
use DBIO::MSSQL::Diff::Column;

# karr k81. A NOT NULL column without a default added to a table that holds
# rows, and a column made NOT NULL over a NULL, are refused before the first
# statement. The server refuses both (Msg 4901, Msg 515); inside the
# transaction of _execute_ddl that error dooms the transaction, core discards
# the handle and the caller got "Cannot allocate statement when disconnected"
# (live: t/118-conformance-diff-live.t). An empty table and a column without a
# NULL pass.

{
  package T121::Diff;
  sub new { bless { ops => $_[1] }, $_[0] }
  sub operations { $_[0]{ops} }
}
{
  package T121::Dbh;
  sub new { bless { rows => $_[1], log => [] }, $_[0] }
  sub selectrow_array { push @{ $_[0]{log} }, $_[1]; $_[0]{rows} ? 1 : undef }
}

my $deploy = bless {}, 'DBIO::MSSQL::Deploy';

sub add {
  DBIO::MSSQL::Diff::Column->new(action => 'add', table_name => 'base',
    column_name => 'code', new_info => { not_null => 1, @_ });
}
sub alter {
  my ($old_nn, $new_nn) = @_;
  DBIO::MSSQL::Diff::Column->new(action => 'alter', table_name => 'opt',
    column_name => 'c', old_info => { data_type => 'nvarchar', size => 20, not_null => $old_nn },
    new_info => { data_type => 'nvarchar', size => 20, not_null => $new_nn });
}
sub check {
  my ($rows, @ops) = @_;
  my $dbh = T121::Dbh->new($rows);
  my $ok = eval { $deploy->_refuse_unfillable(T121::Diff->new(\@ops), $dbh); 1 };
  return ($ok, $@, $dbh);
}

{
  my ($ok, $err, $dbh) = check(1, add());
  ok !$ok, 'NOT NULL column without default over rows: refused';
  isa_ok $err, 'DBIO::Exception';
  like "$err", qr/refuses to add the column base\.code/, 'names table and column';
  like "$err", qr/\bbase\b/, 'names the table';
  like $dbh->{log}[0], qr/\ASELECT TOP 1 1 FROM base\z/, 'asks the table for a row';
}
{
  my ($ok) = check(0, add());
  ok $ok, 'NOT NULL column without default, empty table: passes';
}
{
  my ($ok, $err, $dbh) = check(1, add(default_value => '0'));
  ok $ok, 'NOT NULL column with a default: passes';
  is_deeply $dbh->{log}, [], '... and the table is not asked';
}
{
  my ($ok) = check(1, DBIO::MSSQL::Diff::Column->new(action => 'add', table_name => 'base',
    column_name => 'x', new_info => { not_null => 0 }));
  ok $ok, 'a nullable column: passes';
}
{
  my ($ok, $err, $dbh) = check(1, alter(0, 1));
  ok !$ok, 'column becomes NOT NULL over a NULL: refused';
  like "$err", qr/refuses to make the column opt\.c NOT NULL/, 'names table and column';
  like $dbh->{log}[0], qr/\ASELECT TOP 1 1 FROM opt WHERE c IS NULL\z/,
    'asks for a NULL in that column';
}
{
  my ($ok) = check(0, alter(0, 1));
  ok $ok, 'column becomes NOT NULL, no NULL in it: passes';
}
{
  my ($ok, $err, $dbh) = check(1, alter(1, 1), alter(0, 0));
  ok $ok, 'NOT NULL stays / NULL stays: passes';
  is_deeply $dbh->{log}, [], '... and nothing is asked';
}

done_testing;
