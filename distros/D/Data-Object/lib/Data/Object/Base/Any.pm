package Data::Object::Base::Any;

use strict;
use warnings;

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

  if (blessed($data) && $data->isa('Regexp') && $^V <= v5.12.0) {
    $data = do { \(my $q = qr/$data/) };
  }

  return bless ref($data) ? $data : \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Base::Any

=cut

=head1 ABSTRACT

Data-Object Abstract Any Class

=cut

=head1 SYNOPSIS

  package My::Any;

  use parent 'Data::Object::Base::Any';

  my $any = My::Any->new(\*main);

=cut

=head1 DESCRIPTION

Data::Object::Base::Any is an abstract base class for operating on any Perl 5 data type.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Any $arg1) : Object

Construct a new object.

=over 4

=item new example

  package My::Any;

  use parent 'Data::Object::Base::Any';

  my $any = My::Any->new(\*main);

=back

=cut
