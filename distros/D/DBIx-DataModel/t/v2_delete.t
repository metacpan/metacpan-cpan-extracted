use strict;
use warnings;

use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use DBIx::DataModel -compatibility=> undef;

use constant NTESTS  => 3;
use Test::More tests => NTESTS;

DBIx::DataModel->Schema('HR') # Human Resources
->Table(Employee   => T_Employee   => qw/emp_id/);

SKIP: {
  eval "use DBD::Mock 1.36; 1"
    or skip "DBD::Mock 1.36 does not seem to be installed", NTESTS;

  my $dbh = DBI->connect('DBI:Mock:', '', '', 
                         {RaiseError => 1, AutoCommit => 1});

  HR->dbh($dbh);

  # sqlLike : takes a list of SQL regex and bind params, and a test msg.

  # Checks if those match with the DBD::Mock history.

  sub sqlLike { # closure on $dbh
                # TODO : fix line number, should report the caller's line
    my $msg = pop @_;

    for (my $hist_index = -(@_ / 2); $hist_index < 0; $hist_index++) {
      my ($sql, $bind)  = (shift, shift);
      my $hist = $dbh->{mock_all_history}[$hist_index];

      is_same_sql_bind($hist->statement, $hist->bound_params,
                       $sql,             $bind, "$msg [$hist_index]");
    }
    $dbh->{mock_clear_history} = 1;
  }


  # delete
  my $emp_id = 123;
  HR->table('Employee')->delete($emp_id);
  sqlLike("DELETE FROM T_Employee WHERE emp_id = ? ", 
          [$emp_id],
          "delete");


  HR::Employee->delete($emp_id);
  sqlLike("DELETE FROM T_Employee WHERE emp_id = ? ", 
          [$emp_id],
          "delete");

  my $emp = bless {emp_id => $emp_id}, 'HR::Employee';
  $emp->delete;
  sqlLike("DELETE FROM T_Employee WHERE emp_id = ? ", 
          [$emp_id],
          "delete");

}


