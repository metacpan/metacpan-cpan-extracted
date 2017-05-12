use strict;
use warnings;

use DBIx::DataModel;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use constant NTESTS  => 2;
use Test::More tests => NTESTS;

DBIx::DataModel->Schema('HR') # Human Resources
->Table(Employee   => T_Employee   => qw/emp_id/)
->Table(Department => T_Department => qw/dpt_id/)
->Table(Activity   => T_Activity   => qw/act_id/)
->Composition([qw/Employee   employee   1 /],
              [qw/Activity   activities * /])
->Association([qw/Department department 1 /],
              [qw/Activity   activities * /]);

SKIP: {
  eval "use DBD::Mock 1.36; 1"
    or skip "DBD::Mock 1.36 does not seem to be installed", NTESTS;

  my $dbh = DBI->connect('DBI:Mock:', '', '', 
                         {RaiseError => 1, AutoCommit => 1});

  HR->dbh($dbh);

  sub sqlLike { # closure on $dbh
    my $msg = pop @_;

    for (my $hist_index = -(@_ / 2); $hist_index < 0; $hist_index++) {
      my ($sql, $bind)  = (shift, shift);
      my $hist = $dbh->{mock_all_history}[$hist_index];

      is_same_sql_bind($hist->statement, $hist->bound_params,
                       $sql,             $bind, "$msg [$hist_index]");
    }
    $dbh->{mock_clear_history} = 1;
  }

  # paging directly from initial request
  my $rows = HR->table('Employee')->select(
    -page_size => 10,
    -page_index => 3,
   );
  sqlLike('SELECT * FROM T_Employee LIMIT ? OFFSET ?', [10, 20], 'page 3 from initial request');



  $rows = HR->table('Employee')->select(
    -columns => [qw/foo bar/],
    -limit   => 0,
   );

  sqlLike('SELECT foo, bar FROM T_Employee LIMIT ? OFFSET ?', [0, 0], 'limit 0');



}


