package Data::Object::Base::Regexp;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed';

use parent 'Data::Object::Base';

our $VERSION = '0.97'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  my $role = 'Data::Object::Role::Detract';

  if (blessed($data) && $data->can('does') && $data->does($role)) {
    $data = $data->detract;
  }

  if (!defined($data) || !re::is_regexp($data)) {
    croak('Instantiation Error: Not a RegexpRef');
  }

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::Regexp

=cut

=head1 ABSTRACT

Data-Object Abstract Regexp Class

=cut

=head1 SYNOPSIS

  package My::Regexp;

  use parent 'Data::Object::Base::Regexp';

  my $re = My::Regexp->new(qr(\w+));

=cut

=head1 DESCRIPTION

Data::Object::Base::Regexp provides routines for operating on Perl 5 regular
expressions.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(RegexpRef $arg1) : Object

The new method expects a regular-expression object and returns a new class
instance.

=over 4

=item new example

  # given qr(something to match against)

  package My::Regexp;

  use parent 'Data::Object::Base::Regexp';

  my $re = My::Regexp->new(qr(something to match against));

=back

=cut
