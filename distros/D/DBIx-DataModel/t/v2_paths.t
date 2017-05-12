use strict;
use warnings;
no warnings 'uninitialized';

use DBIx::DataModel -compatibility=> undef;

use Test::More tests => 3;

DBIx::DataModel->Schema('HR') # Human Resources
->Table(Employee   => T_Employee   => qw/emp_id/)
->Table(Department => T_Department => qw/dpt_id/)
->Table(Activity   => T_Activity   => qw/act_id/)
->Composition([qw/Employee   employee   1 /],
              [qw/Activity   activities * /])
->Association([qw/Department department 1 /],
              [qw/Activity   activities * /]);


my $emp_meta = HR->table('Employee')->metadm;
my %paths = $emp_meta->path;
while (my ($path_name, $path)= each %paths) {
  my $opp     = $path->opposite;
  my $opp_opp = $opp->opposite;
  isa_ok($opp, 'DBIx::DataModel::Meta::Path', "opposite is a Path");
  isnt($path, $opp,                           "opposite is different");
  is($path, $opp_opp,                         "opposite of opposite")
}







