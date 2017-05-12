use strict;
use warnings;

use Test::More tests => 1;

if (1 == 0) {
  # the line below artificially populates DBIx::DataModel::Schema namespace
  # at compile time, even if never executed. So the previous implementation
  # of Utils::define_class got tricked by this case.
  require DBIx::DataModel::Schema::Foo::Bar;
}

require DBIx::DataModel;

DBIx::DataModel->Schema('HR')
    ->Table(Employee   => T_Employee   => qw/emp_id/)
    ->Table(Department => T_Department => qw/dpt_id/)
    ->Table(Activity   => T_Activity   => qw/act_id/);


ok(scalar(keys %{HR::}), "class HR is defined");

