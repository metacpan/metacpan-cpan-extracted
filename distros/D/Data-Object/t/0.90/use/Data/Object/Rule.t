use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Rule

=abstract

Data-Object Class Requirements

=synopsis

  package Persona;

  use Data::Object Rule;

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

=description

Data::Object::Rule allows you to specify rules for the consuming class.

=cut

use_ok "Data::Object::Rule";

ok 1 and done_testing;
