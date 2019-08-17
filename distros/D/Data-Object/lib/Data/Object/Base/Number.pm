package Data::Object::Base::Number;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed', 'looks_like_number';

use parent 'Data::Object::Base';

our $VERSION = '0.98'; # VERSION

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
    croak('Instantiation Error: Not a Number');
  }

  if (!looks_like_number($data)) {
    croak('Instantiation Error: Not an Number');
  }

  $data += 0 unless $data =~ /[a-zA-Z]/;

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::Number

=cut

=head1 ABSTRACT

Data-Object Abstract Number Class

=cut

=head1 SYNOPSIS

  package My::Number;

  use parent 'Data::Object::Base::Number';

  my $number = My::Number->new(1_000_000);

=cut

=head1 DESCRIPTION

Data::Object::Base::Number provides routines for operating on Perl 5 numeric
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

  # given 1_000_000

  package My::Number;

  use parent 'Data::Object::Base::Number';

  my $number = My::Number->new(1_000_000);

=back

=cut
