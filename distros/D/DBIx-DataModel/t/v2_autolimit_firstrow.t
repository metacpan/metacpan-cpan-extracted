use strict;
use warnings;

use SQL::Abstract::Test import => [qw/is_same_sql_bind/];
use SQL::Abstract::More;

use DBIx::DataModel -compatibility=> undef;

use constant NTESTS  => 1;
use Test::More tests => NTESTS;


DBIx::DataModel->Schema('HR');
HR->Table(Employee   => T_Employee   => qw/emp_id/);
HR->singleton->autolimit_firstrow(1);


SKIP: {
  eval "use DBD::Mock 1.36; 1"
    or skip "DBD::Mock 1.36 does not seem to be installed", NTESTS;

  my $dbh = DBI->connect('DBI:Mock:', '', '', 
                         {RaiseError => 1, AutoCommit => 1});
  HR->dbh($dbh);

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

  HR->table('Employee')->select(
    -result_as => 'firstrow',
   );
  sqlLike("SELECT * FROM T_Employee LIMIT ? OFFSET ?",
          [1, 0],
          "autolimit");

}
