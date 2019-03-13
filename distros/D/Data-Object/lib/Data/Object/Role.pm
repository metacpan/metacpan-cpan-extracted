package Data::Object::Role;

use strict;
use warnings;

use Data::Object;

use parent 'Moo::Role';

# BUILD
# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Role

=cut

=head1 ABSTRACT

Data-Object Role Declaration

=cut

=head1 SYNOPSIS

  package Persona;

  use Data::Object Role;

  with 'Relatable';

  has handle => (
    is => 'ro',
    isa => 'Str'
  );

  1;

=cut

=head1 DESCRIPTION

Data::Object::Role modifies the consuming package making it a role.

=cut
