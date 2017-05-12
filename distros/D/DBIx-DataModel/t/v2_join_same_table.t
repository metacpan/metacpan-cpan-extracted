use strict;
use warnings;

use DBIx::DataModel -compatibility=> undef;
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

  my @to_join = qw/Employee <=> activities <=> department
                            <=> activities|other_act <=> employee|colleague/;
  my @cols = qw/Employee.emp_id colleague.emp_id|colleague_id/;

  $dbh->{mock_add_resultset} = [ [qw/emp_id  colleague_id/],
                                 [qw/1 2/],
                                 [qw/1 3/],
                                 [qw/1 4/],
                                 [qw/2 1/],
                                ];

  my $first_colleague = HR->join(@to_join)->select(
    -columns   => \@cols,
    -result_as => 'firstrow',
   );

  # check that methonds inherited through multiple inheritance works are OK
  is($first_colleague->can('activities'), HR::Employee->can('activities'));
  is($first_colleague->can('department'), HR::Activity->can('department'));
}


