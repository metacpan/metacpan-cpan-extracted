package CLI::Base;
use strict;

use strict;
use Carp;
use CLI   qw(INTEGER FLOAT STRING SSTRING TIME DEGREE
             BOOLEAN typeStr);
use Astro::Time qw(str2turn);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $name = shift;
  my $value = shift;
  my $type = shift;

  my $self  = {
	       NAME => $name,
	       TYPE => $type,
	       VALUE => $value,
	       FUNC => undef,
	       MIN => undef,
	       MAX => undef
	      };
  bless ($self, $class);

  return $self;
}

sub value {
  my $self = shift;
  if (@_) {$self->{VALUE} = shift }
  return $self->{VALUE};
}

sub type {
  my $self = shift;
  if (@_) { $self->{TYPE} = shift }
  return $self->{TYPE};
}

sub name {
  my $self = shift;
  if (@_) { $self->{NAME} = shift }
  return $self->{NAME};
}

sub function {
  my $self = shift;
  if (@_) { $self->{FUNC} = shift }
  return $self->{FUNC};
}

sub min {
  my $self = shift;
  if (@_) { 
    my $type = $self->type();
    if (!($type == INTEGER || $type == FLOAT ||
          $type == TIME || $type == DEGREE)) {
      carp 'Cannot set minimum value for type ', typeStr($self->type()), "\n";
      return undef;
    }
    $self->{MIN} = shift;
  }
  return $self->{MIN};
}

sub max {
  my $self = shift;
  if (@_) { 
    my $type = $self->type();
    if (!($type == INTEGER || $type == FLOAT || 
          $type == TIME || $type == DEGREE)) {
      carp 'Cannot set maximum value for type ', $self->type(), "\n";
      return undef;
    }
    $self->{MAX} = shift;
  }
  return $self->{MAX};
}

sub parse {
  my $self = shift;
  my $string = shift;

  my $name = $self->{NAME};

  carp "Could not parse \"$name $string\"";

}

1;

