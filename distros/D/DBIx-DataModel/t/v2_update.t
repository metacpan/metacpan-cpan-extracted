use strict;
use warnings;

use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use DBIx::DataModel -compatibility=> undef;

use constant NTESTS  => 6;
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


  my $dt     = "01.02.1234 12:34";
  my $emp_id = 9876;

  # update using verbatim SQL
  HR->table('Employee')->update(
    $emp_id,
    {DT_field => \ ["TO_DATE(?, 'DD.MM.YYYY HH24:MI')", $dt]},
  );
  sqlLike("UPDATE T_Employee SET DT_field = TO_DATE(?, 'DD.MM.YYYY HH24:MI') "
         . "WHERE ( emp_id = ? )",
          [$dt, $emp_id],
          "update from function");

  # other subreferences should warn but be removed automatically
  HR->table('Employee')->update(
    $emp_id, {foo => 123, skip1 => {bar => 456}, skip2 => bless({}, "Foo")},
  );
  sqlLike("UPDATE T_Employee SET foo = ? WHERE ( emp_id = ? )",
          [123, $emp_id],
          "skip sub-references");


  # update an unblessed record
  my $record = {emp_id => $emp_id, foo => 'bar'};
  HR->table('Employee')->update($record);
  sqlLike("UPDATE T_Employee SET foo = ? WHERE emp_id = ?",
          ['bar', $emp_id],
          "class update unblessed");

  # update a blessed record, 
  $record = bless {emp_id => $emp_id, foo => 'bar'}, 'HR::Employee';
  HR->table('Employee')->update($record);
  sqlLike("UPDATE T_Employee SET foo = ? WHERE emp_id = ?",
          ['bar', $emp_id],
          "class update blessed");

  # direct call on a object instance, without args
  my $obj = bless {emp_id => $emp_id, foo => 'bar'}, 'HR::Employee';
  $obj->update();
  sqlLike("UPDATE T_Employee SET foo = ? WHERE emp_id = ?",
          ['bar', $emp_id],
          "obj update without args");

  # direct call on a object instance, with args
  # $obj = bless {emp_id => $emp_id, foo => 'bar'}, 'HR::Employee';
  $obj->update({bar => 987});
  sqlLike("UPDATE T_Employee SET bar = ? WHERE emp_id = ?",
          [987, $emp_id],
          "obj update with args");



}


