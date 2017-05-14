package CLI::Command;
use CLI::Base;
@ISA = ("CLI::Base");

use CLI qw(TIME);

use Carp;
use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $name = shift;
  my $func = shift;

  my $self  = {
	       NAME => $name,
	       TYPE => undef,
	       VALUE => undef,
	       MIN => undef,
	       MAX => undef,
	       FUNC => $func
	      };
  bless ($self, $class);
  return $self;
}

sub parse {
  my $self = shift;
  my $value = shift;

  if (defined $self->function()) {
    &{$self->function()}($value);
  }
}

1;

