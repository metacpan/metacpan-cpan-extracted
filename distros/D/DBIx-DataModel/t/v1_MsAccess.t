use strict;
use warnings;
no warnings 'uninitialized';
use DBI;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use constant N_DBI_MOCK_TESTS => 2;
use constant N_BASIC_TESTS    => 1;

use Test::More tests => (N_BASIC_TESTS + N_DBI_MOCK_TESTS);

sub die_ok(&) { my $code=shift; eval {$code->()}; ok($@, $@);}

use_ok("DBIx::DataModel", -compatibility=> 1.0);
DBIx::DataModel->Schema('HR', sqlDialect => 'MsAccess');
  
    HR->Table(Employee   => T_Employee   => qw/emp_id/);
    HR->Table(Department => T_Department => qw/dpt_id/);
    HR->Table(Activity   => T_Activity   => qw/act_id/);

  HR->Composition([qw/Employee   employee   1 /],
                  [qw/Activity   activities * /]);
  HR->Association([qw/Activity   activities * dpt_id/],
		  [qw/Department department 1 dpt_id/]);

  HR->ColumnType(Date => 
     fromDB   => sub {$_[0] =~ s/(\d\d\d\d)-(\d\d)-(\d\d)/$3.$2.$1/},
     toDB     => sub {$_[0] =~ s/(\d\d)\.(\d\d)\.(\d\d\d\d)/$3-$2-$1/},
     validate => sub {$_[0] =~ m/(\d\d)\.(\d\d)\.(\d\d\d\d)/});;

  HR::Employee->ColumnType(Date => qw/d_birth/);
  HR::Activity->ColumnType(Date => qw/d_begin d_end/);

  HR->NoUpdateColumns(qw/d_modif user_id/);
  HR::Employee->NoUpdateColumns(qw/last_login/);

  HR::Employee->ColumnHandlers(lastname => normalizeName => sub {
			    $_[0] =~ s/\w+/\u\L$&/g
			  });

  HR::Employee->AutoExpand(qw/activities/);


SKIP: {
  my $dbh;
  eval {$dbh = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1})};
  skip "DBD::Mock does not seem to be installed", N_DBI_MOCK_TESTS
    if $@ or not $dbh;


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


  HR->dbh($dbh);

  my $emp = HR::Employee->blessFromDB({emp_id => 999});



  my $view = HR->join(qw/Employee activities department/);

  $view->select("lastname, dpt_name", {gender => 'F'});
  sqlLike('SELECT lastname, dpt_name ' .
	  'FROM t_employee LEFT OUTER JOIN (t_activity ' .
	  'LEFT OUTER JOIN (t_department) ' .
	  'ON t_activity.dpt_id=t_department.dpt_id) ' .
	  'ON t_employee.emp_id=t_activity.emp_id ' .
	  'WHERE (gender = ?)',
          ['F'], 'schema join (MsAccess)');


  $emp->join(qw/activities department/)
      ->select({gender => 'F'});
  sqlLike('SELECT * ' .
	  'FROM t_activity ' .
	  'INNER JOIN (t_department) ' .
	  'ON t_activity.dpt_id=t_department.dpt_id ' .
	  'WHERE (emp_id = ? AND gender = ?)', 
          [999, 'F'], 
	  'instance join (MsAccess)');

};


