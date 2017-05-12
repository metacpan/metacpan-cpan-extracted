package Cikl::Models::Address::TestClass;
use base qw(Test::Class);
use strict;
use warnings;
use Test::More;
use Mouse::Util::TypeConstraints;

sub testing_class { die("testing_class not implemented!") }

sub safe_generate { 
  my $self = shift;
  my $value = shift;
  return eval { $self->generate($value) };
}

sub generate {
  my $self = shift;
  my $value = shift;
  return $self->testing_class()->new(value => $value);
}

sub generate_normalized {
  my $self = shift;
  my $value = shift;
  return $self->testing_class()->new_normalized(value => $value);
}

# Make sure we don't run this test helper directly.
__PACKAGE__->SKIP_CLASS(1);

1;

