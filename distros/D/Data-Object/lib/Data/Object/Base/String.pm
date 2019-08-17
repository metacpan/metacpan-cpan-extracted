package Data::Object::Base::String;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed';

use parent 'Data::Object::Base';

our $VERSION = '0.98'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  my $role = 'Data::Object::Role::Detract';

  if (blessed($data) && $data->can('does') && $data->does($role)) {
    $data = $data->detract;
  }

  $data = $data ? "$data" : "";

  if (!defined($data) || ref($data)) {
    croak('Instantiation Error: Not a String');
  }

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::String

=cut

=head1 ABSTRACT

Data-Object Abstract String Class

=cut

=head1 SYNOPSIS

  package My::String;

  use parent 'Data::Object::Base::String';

  my $string = My::String->new('abcedfghi');

=cut

=head1 DESCRIPTION

Data::Object::Base::String provides routines for operating on Perl 5 string
data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Str $arg1) : Object

The new method expects a string and returns a new class instance.

=over 4

=item new example

  # given abcedfghi

  package My::String;

  use parent 'Data::Object::Base::String';

  my $string = My::String->new('abcedfghi');

=back

=cut
