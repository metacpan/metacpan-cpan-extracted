package Data::Object::State;

use strict;
use warnings;

use parent 'Data::Object::Class';

our $VERSION = '0.97'; # VERSION

# BUILD

sub import {
  my ($class, @args) = @_;

  my $target = caller;

  eval "package $target; use Data::Object::Class; 1;";

  no strict 'refs';

  *{"${target}::BUILD"} = $class->can('BUILD');
  *{"${target}::renew"} = $class->can('renew');

  return;
}

sub BUILD {
  my ($self, $args) = @_;

  my $class = ref($self) || $self;

  no strict 'refs';

  ${"${class}::data"} = {%$self, %$args} if !${"${class}::data"};

  $_[0] = bless ${"${class}::data"}, $class;

  return $class;
}

# METHODS

sub renew {
  my ($self, @args) = @_;

  my $class = ref($self) || $self;

  no strict 'refs';

  undef ${"${class}::data"};

  return $class->new(@args);
}

1;

=encoding utf8

=head1 NAME

Data::Object::State

=cut

=head1 ABSTRACT

Data-Object Singleton Declaration

=cut

=head1 SYNOPSIS

  package Registry;

  use Data::Object 'State';

  extends 'Environment';

=cut

=head1 DESCRIPTION

Data::Object::State modifies the consuming package makes it a singleton class.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 renew

  renew(Any @args) : Object

The renew method resets the state and returns a new singleton.

=over 4

=item renew example

  my $renew = $self->renew(@args);

=back

=cut
