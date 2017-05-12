package Cikl::DataTypes::TestClass;
use base qw(Test::Class);
use strict;
use warnings;
use Test::More;
use Mouse::Util::TypeConstraints;

sub testing_class { die("testing_class not implemented!") }
sub get_constraint { 
  my $self = shift;
  find_type_constraint($self->testing_class()); 
}

sub check_type : Test {
  my $self = shift;
  isa_ok($self->get_constraint(), 'Mouse::Meta::TypeConstraint');
}

sub check_name : Test {
  my $self = shift;

  is($self->get_constraint()->name, $self->testing_class(), 
      "The typeconstraint should be named " . $self->testing_class());
}

# Make sure we don't run this test helper directly.
Cikl::DataTypes::TestClass->SKIP_CLASS(1);

1;
