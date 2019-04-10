package Data::Object::Base::Hash;

use strict;
use warnings;

use Carp 'croak';
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

  unless (ref($data) eq 'HASH') {
    croak('Instantiation Error: Not a HashRef');
  }

  return bless $data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::Hash

=cut

=head1 ABSTRACT

Data-Object Abstract Hash Class

=cut

=head1 SYNOPSIS

  package My::Hash;

  use parent 'Data::Object::Base::Hash';

  my $hash = My::Hash->new({1..4});

=cut

=head1 DESCRIPTION

Data::Object::Base::Hash provides routines for operating on Perl 5 hash
references.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(HashRef $arg1) : Object

The new method expects a list or hash reference and returns a new class
instance.

=over 4

=item new example

  # given 1..4

  package My::Hash;

  use parent 'Data::Object::Base::Hash';

  my $hash = My::Hash->new({1..4});

=back

=cut
