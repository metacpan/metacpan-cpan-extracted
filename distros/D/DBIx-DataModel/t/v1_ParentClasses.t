package Foo::Parent::Table;

our @ISA = qw/DBIx::DataModel::Table/;

package Foo::Parent::V1;

our @ISA = qw/DBIx::DataModel::View/;

package Foo::Parent::V2;

our @ISA = qw/DBIx::DataModel::View/;

package main;
use strict;
use warnings;
no warnings 'uninitialized';
use DBI;

use Test::More tests => 6;


use_ok("DBIx::DataModel", -compatibility=> 1.0);

DBIx::DataModel->Schema('HR', tableParent => 'Foo::Parent::Table',
                              viewParent  => [qw/Foo::Parent::V1
                                                 Foo::Parent::V2/]);

HR->Table(Employee   => T_Employee   => qw/emp_id/);
HR->Table(Department => T_Department => qw/dpt_id/);
HR->Table(Activity   => T_Activity   => qw/act_id/);

HR->Composition([qw/Employee   employee   1 /],
                [qw/Activity   activities * /]);
HR->Association([qw/Activity   activities * dpt_id/],
                [qw/Department department 1 dpt_id/]);

ok(HR::Employee->isa('Foo::Parent::Table'),     "isa table custom");
ok(HR::Employee->isa('DBIx::DataModel::Table'), "isa table base");

my $view = HR->join(qw/Employee activities department/);

SKIP: {
  skip "joins now belong to ::Join, not ::View", 3;

  ok($view->isa('Foo::Parent::V1'),       "isa view custom 1");
  ok($view->isa('Foo::Parent::V2'),       "isa view custom 2");
  ok($view->isa('DBIx::DataModel::View'), "isa view base");

}

