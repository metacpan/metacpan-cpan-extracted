package TestsFor::Cikl::DataTypes::LowerCaseStr;
use lib 'testlib';
use base qw(Cikl::DataTypes::TestClass);
use strict;
use warnings;
use Test::More;

use Cikl::DataTypes::LowerCaseStr;

sub testing_class { "Cikl::DataTypes::LowerCaseStr"; }

sub test_validation : Test(6) {
  my $self = shift;
  my $type = $self->get_constraint();

  ok($type->check("a"), "'a' is a valid LowerCaseStr");
  ok($type->check("1"), "'1' is a valid LowerCaseStr");
  ok($type->check(""), "'' is a valid LowerCaseStr");
  ok($type->check("\x{00E2}"), "'\x{00E2}' is a valid LowerCaseStr");
  ok(! $type->check('A'), "'A' is not a valid LowerCaseStr");
  ok(! $type->check("\x{00C2}"), "'\x{00C2}' is a valid LowerCaseStr");
}

Test::Class->runtests;

