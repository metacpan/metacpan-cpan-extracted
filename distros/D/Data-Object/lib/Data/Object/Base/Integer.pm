package Data::Object::Base::Integer;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed', 'looks_like_number';

use parent 'Data::Object::Base';

our $VERSION = '0.99'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  my $role = 'Data::Object::Role::Detract';

  if (blessed($data) && $data->can('does') && $data->does($role)) {
    $data = $data->detract;
  }

  $data = "$data" if $data;

  if (defined $data) {
    $data =~ s/^\+//; # not keen on this but ...
  }

  if (!defined($data) || ref($data)) {
    croak('Instantiation Error: Not an Integer');
  }

  if (!looks_like_number($data)) {
    croak('Instantiation Error: Not an Integer');
  }

  $data += 0 unless $data =~ /[a-zA-Z]/;

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::Integer

=cut

=head1 ABSTRACT

Data-Object Abstract Integer Class

=cut

=head1 SYNOPSIS

  package My::Integer;

  use parent 'Data::Object::Base::Integer';

  my $integer = My::Integer->new(9);

=cut

=head1 DESCRIPTION

Data::Object::Base::Integer provides routines for operating on Perl 5 integer
data.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Int $arg1) : Object

The new method expects a number and returns a new class instance.

=over 4

=item new example

  # given 9

  package My::Integer;

  use parent 'Data::Object::Base::Integer';

  my $integer = My::Integer->new(9);

=back

=cut
