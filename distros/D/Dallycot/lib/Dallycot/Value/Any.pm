package Dallycot::Value::Any;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Base class for most value types

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value';

use Carp qw(croak);
use Promises qw(deferred);

sub value {
  my ($self) = @_;

  return $self->[0];
}

sub is_defined { return 1 }

sub successor {
  my ($self) = @_;

  my $d = deferred;

  $d->reject( $self->type . " has no successor" );

  return $d->promise;
}

sub predecessor {
  my ($self) = @_;

  my $d = deferred;

  $d->reject( $self->type . " has no predecessor" );

  return $d->promise;
}

sub to_string {
  my ($self) = @_;
  return $self->id;
}

sub negated {
  my($self) = @_;

  my $class = ref $self || $self;
  $class =~ /::([^:]+)$/;
  croak "negation is not supported for $1";
}

1;
