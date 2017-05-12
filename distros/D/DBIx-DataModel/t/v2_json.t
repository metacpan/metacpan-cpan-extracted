use strict;
use warnings;

use DBIx::DataModel -compatibility=> undef;

use constant NTESTS  => 3;
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
  eval "use JSON 2.0; 1"
    or skip "JSON 2.0 does not seem to be installed", NTESTS;

  eval "use DBD::Mock 1.36; 1"
    or skip "DBD::Mock 1.36 does not seem to be installed", NTESTS;

  my $dbh = DBI->connect('DBI:Mock:', '', '', 
                         {RaiseError => 1, AutoCommit => 1});

  HR->dbh($dbh);

  # fake data
  $dbh->{mock_add_resultset} = [ [qw/emp_id firstname lastname/],
                                 [qw/1      Hector    Berlioz/], ];
  my $emp = HR->table('Employee')->fetch(1);
  $dbh->{mock_add_resultset} = 
    [ [qw/act_id emp_id    d_begin       d_end   dpt_id/],
      [qw/     1      1 01.01.2001  02.02.2002       99/], ];
  $emp->expand('activities');

  my $json_converter = JSON->new->convert_blessed(1);
  my $json_text      = $json_converter->encode($emp);

  like($json_text, qr/"firstname":"Hector"/,   "json contains firstname");
  like($json_text, qr/"d_begin":"01.01.2001"/, "json contains nested d_begin");

  my $data_from_json = $json_converter->decode($json_text);
  is_deeply($emp, $data_from_json,             "json preserved nested strucure");
}


