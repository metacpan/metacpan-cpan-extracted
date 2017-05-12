use strict;
use warnings;

use DBIx::DataModel -compatibility=> undef;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use constant NTESTS => 2;
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

  my ($sql, @bind) = HR->join(qw/Employee activities => department/)->select(
    -where => {firstname => 'Hector',
               dpt_name  => 'Music'},
    -where_on => {
       T_Activity   => {d_end => {"<" => '01.01.2001'}},
       T_Department => {dpt_head => 999},
     },
    -result_as => 'sql',
   );

  my $expected_sql = q{
     SELECT * FROM T_Employee 
       LEFT OUTER JOIN T_Activity
         ON T_Employee.emp_id = T_Activity.emp_id AND d_end < ?
       LEFT OUTER JOIN T_Department 
         ON T_Activity.dpt_id = T_Department.dpt_id AND dpt_head = ?
       WHERE dpt_name = ? AND firstname = ?
   };
  my @expected_bind = qw/01.01.2001 999 Music Hector/;
  is_same_sql_bind($sql, \@bind, $expected_sql, \@expected_bind);

  # same test again, to check for possible side-effects in metadata
  ($sql, @bind) = HR->join(qw/Employee activities => department/)->select(
    -where => {firstname => 'Hector',
               dpt_name  => 'Music'},
    -where_on => {
       T_Activity   => {d_end => {"<" => '01.01.2001'}},
       T_Department => {dpt_head => 999},
     },
    -result_as => 'sql',
   );
  is_same_sql_bind($sql, \@bind, $expected_sql, \@expected_bind);
}


