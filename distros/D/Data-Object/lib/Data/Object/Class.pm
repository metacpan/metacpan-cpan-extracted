package Data::Object::Class;

use strict;
use warnings;

use parent 'Moo';

# BUILD
# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::Class

=cut

=head1 ABSTRACT

Data-Object Class Declaration

=cut

=head1 SYNOPSIS

  package Person;

  use Data::Object 'Class';

  extends 'Identity';

  has fullname => (
    is => 'ro',
    isa => 'Str'
  );

  1;

=cut

=head1 DESCRIPTION

Data::Object::Class modifies the consuming package making it a class.

=cut
