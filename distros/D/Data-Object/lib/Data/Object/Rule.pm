package Data::Object::Rule;

use strict;
use warnings;

use Data::Object;

use parent 'Moo::Role';

our $VERSION = '0.96'; # VERSION

# BUILD
# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Rule

=cut

=head1 ABSTRACT

Data-Object Class Requirements

=cut

=head1 SYNOPSIS

  package Persona;

  use Data::Object 'Rule';

  requires 'id';
  requires 'fname';
  requires 'lname';
  requires 'created';
  requires 'updated';

  around created() {
    # do something ...
    return $self->$orig;
  }

  around updated() {
    # do something ...
    return $self->$orig;
  }

  1;

=cut

=head1 DESCRIPTION

Data::Object::Rule allows you to specify rules for the consuming class.

=cut
