package TestsFor::Cikl::DataTypes::Integer;
use lib 'testlib';
use base qw(Cikl::DataTypes::TestClass);
use strict;
use warnings;
use Test::More;

use Cikl::DataTypes::Integer;

sub testing_class { "Cikl::DataTypes::Integer"; }

sub test_validation : Test(5) {
  my $self = shift;
  my $type = $self->get_constraint();
  ok($type->check(0), "0 is a valid Integer");
  ok($type->check(1), "1 is a valid Integer");
  ok(!$type->check("0"), "'0' is not a valid Integer");
  ok(!$type->check("73"), "'73' is not a valid Integer");
  ok(!$type->check("1.7"), "'1.7' is not a valid Integer");
}

sub test_coercion : Test(5) {
  my $self = shift;
  my $type = $self->get_constraint();
  is($type->coerce(0), 0, "0 => 0");
  is($type->coerce(73), 73, "73 => 73");
  is($type->coerce(2331.234), 2331, "2331.234 => 2331");
  is($type->coerce("1234"), 1234, "'1234' => 1234");
  is($type->coerce("77.66"), 77, "'77.66' => 77");
}

Test::Class->runtests;

