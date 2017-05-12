use strict;
use warnings;

use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use DBIx::DataModel -compatibility=> undef;

use constant NTESTS  => 2;
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


  my $stmt = HR->table('Employee')->select(
    -columns   => [qw/emp_id firstname lastname/],
    -where     => {d_birth => '01.01.1950'},
    -union     => [-where  => {d_spouse => '01.01.1950'}],
    -result_as => 'statement',
   );

  my $rows = $stmt->all;
  sqlLike(<<__EOSQL__, [qw/01.01.1950 01.01.1950/], "sql union");
    SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_birth = ? ) 
    UNION 
    SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_spouse = ? )
__EOSQL__


  my $n = $stmt->row_count;
  sqlLike(<<__EOSQL__, [qw/01.01.1950 01.01.1950/], "sql count from union");
    SELECT COUNT(*) FROM (
      SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_birth = ? )
      UNION 
      SELECT emp_id, firstname, lastname FROM T_Employee WHERE ( d_spouse = ? )
    ) AS count_wrapper
__EOSQL__

}


