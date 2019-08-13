package Data::Object::Base::Float;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed', 'looks_like_number';

use parent 'Data::Object::Base';

our $VERSION = '0.97'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  my $role = 'Data::Object::Role::Detract';

  if (blessed($data) && $data->can('does') && $data->does($role)) {
    $data = $data->detract;
  }

  if (defined $data) {
    $data =~ s/^\+//; # not keen on this but ...
  }

  if (!defined($data) || ref($data)) {
    croak('Instantiation Error: Not a Float');
  }

  if (!looks_like_number($data)) {
    croak('Instantiation Error: Not a Float');
  }

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::Float

=cut

=head1 ABSTRACT

Data-Object Abstract Float Class

=cut

=head1 SYNOPSIS

  package My::Float;

  use parent 'Data::Object::Base::Float';

  my $float = My::Float->new(9.9999);

=cut

=head1 DESCRIPTION

Data::Object::Base::Float provides routines for operating on Perl 5
floating-point data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Num $arg1) : Object

The new method expects a floating-point number and returns a new class instance.

=over 4

=item new example

  # given 9.9999

  package My::Float;

  use parent 'Data::Object::Base::Float';

  my $float = My::Float->new(9.9999);

=back

=cut
