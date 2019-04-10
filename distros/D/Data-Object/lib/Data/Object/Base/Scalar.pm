package Data::Object::Base::Scalar;

use strict;
use warnings;

use Scalar::Util 'blessed';

use parent 'Data::Object::Base';

our $VERSION = '0.96'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  my $role = 'Data::Object::Role::Detract';

  if (blessed($data) && $data->can('does') && $data->does($role)) {
    $data = $data->detract;
  }

  if (blessed($data) && $data->isa('Regexp') && $^V <= v5.12.0) {
    $data = do { \(my $q = qr/$data/) };
  }

  return bless ref($data) ? $data : \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::Scalar

=cut

=head1 ABSTRACT

Data-Object Abstract Scalar Class

=cut

=head1 SYNOPSIS

  package My::Scalar;

  use parent 'Data::Object::Base::Scalar';

  my $scalar = My::Scalar->new(\*main);

=cut

=head1 DESCRIPTION

Data::Object::Base::Scalar provides routines for operating on Perl 5 scalar
objects.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(ScalarRef $arg1) : Object

The new method expects a scalar reference and returns a new class instance.

=over 4

=item new example

  # given \*main

  package My::Scalar;

  use parent 'Data::Object::Base::Scalar';

  my $scalar = My::Scalar->new(\*main);

=back

=cut
