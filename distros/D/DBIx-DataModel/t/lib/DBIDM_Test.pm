package DBIDM_Test;

use strict;
use warnings;
use DBIx::DataModel;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];
use Test::More;
use DBI;
use DBD::Mock 1.39;

use Exporter  qw/import/;
our @EXPORT_OK = qw/sqlLike die_ok HR_connect $dbh/;


# define "HR" schema with a few tables and associations
DBIx::DataModel->Schema(HR => {  # HR=Human Resources
  no_update_columns            => {d_modif => 1, user_id => 1},
  sql_no_inner_after_left_join => 1,
})
->Table(Employee   => T_Employee   => qw/emp_id/, {
    no_update_columns => {last_login => 1},
  })
->Table(Department => T_Department => qw/dpt_id/)
->Table(Activity   => T_Activity   => qw/act_id/)
->Composition([qw/Employee   employee   1 /],
              [qw/Activity   activities * /])
->Association([qw/Department department 1 /],
              [qw/Activity   activities * /])
;


# open a connection to a mock database
our $dbh = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1, AutoCommit => 1});


# closure on the $dbh : testing the generated SQL.
# takes a list of SQL regex and bind params, and a test msg; checks
# if those match with the DBD::Mock history.
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



sub HR_connect {HR->dbh($dbh)};


# die_ok : succeeds if the supplied coderef dies with an exception
sub die_ok(&) {
  my $code=shift;
  eval {$code->()};
  my $err = $@;
  $err =~ s/ at .*//;
  ok($err, $err);
}

1;

