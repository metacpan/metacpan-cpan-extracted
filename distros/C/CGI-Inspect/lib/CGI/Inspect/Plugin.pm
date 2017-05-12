package CGI::Inspect::Plugin;

use strict;

sub new {
  my ($class, %params) = @_;
  my $self = { %params };
  bless $self, $class;
  return $self;
}

sub manager {
  my ($self) = @_;
  return $self->{manager};
}

sub request {
  my ($self) = @_;
  return $self->manager->request;
}

sub param {
  my $self = shift;
  return $self->request->param(@_);
}

1;

