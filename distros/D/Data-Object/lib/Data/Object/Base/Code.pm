package Data::Object::Base::Code;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed';

use parent 'Data::Object::Base';

our $VERSION = '0.99'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  my $role = 'Data::Object::Role::Detract';

  if (blessed($data) && $data->can('does') && $data->does($role)) {
    $data = $data->detract;
  }

  unless (ref($data) eq 'CODE') {
    croak('Instantiation Error: Not a CodeRef');
  }

  return bless $data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::Code

=cut

=head1 ABSTRACT

Data-Object Abstract Code Class

=cut

=head1 SYNOPSIS

  package My::Code;

  use parent 'Data::Object::Base::Code';

  my $code = My::Code->new(sub { shift + 1 });

=cut

=head1 DESCRIPTION

Data::Object::Base::Code provides routines for operating on Perl 5 code
references.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(CodeRef $arg1) : Object

The new method expects a code reference and returns a new class instance.

=over 4

=item new example

  # given sub { shift + 1 }

  my $code = Data::Object::Base::Code->new(sub { shift + 1 });

=back

=cut
