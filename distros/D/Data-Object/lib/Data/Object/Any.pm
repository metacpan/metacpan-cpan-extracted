package Data::Object::Any;

use Try::Tiny;
use Role::Tiny::With;

use Data::Object::Export qw(
  cast
  croak
  load
);

map with($_), my @roles = qw(
  Data::Object::Role::Detract
  Data::Object::Role::Dumper
  Data::Object::Role::Output
  Data::Object::Role::Throwable
);

map with($_), my @rules = qw(
  Data::Object::Rule::Comparison
  Data::Object::Rule::Defined
);

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  fallback => 1
);

use parent 'Data::Object::Base::Any';

our $VERSION = '0.99'; # VERSION

# BUILD
# METHODS

sub roles {
  return cast([@roles]);
}

sub rules {
  return cast([@rules]);
}

# DISPATCHERS

sub defined {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Any::Defined';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub eq {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Any::Eq';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub gt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Any::Gt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ge {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Any::Ge';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub lt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Any::Lt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub le {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Any::Le';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ne {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Any::Ne';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

1;

=encoding utf8

=head1 NAME

Data::Object::Any

=cut

=head1 ABSTRACT

Data-Object Any Class

=cut

=head1 SYNOPSIS

  use Data::Object::Any;

  my $any = Data::Object::Any->new(\*main);

=cut

=head1 DESCRIPTION

Data::Object::Any provides routines for operating on any Perl 5 data type.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 defined

  defined() : NumObject

The defined method returns truthy for defined data.

=over 4

=item defined example

  my $defined = $self->defined();

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

The eq method returns truthy if argument and object data are equal.

=over 4

=item eq example

  my $eq = $self->eq();

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

The ge method returns truthy if argument is greater or equal to the object data.

=over 4

=item ge example

  my $ge = $self->ge();

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

The gt method returns truthy if argument is greater then the object data.

=over 4

=item gt example

  my $gt = $self->gt();

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

The le method returns truthy if argument is lesser or equal to the object data.

=over 4

=item le example

  my $le = $self->le();

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

The lt method returns truthy if argument is lesser than the object data.

=over 4

=item lt example

  my $lt = $self->lt();

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

The ne method returns truthy if argument and object data are not equal.

=over 4

=item ne example

  my $ne = $self->ne();

=back

=cut

=head2 roles

  roles() : ArrayRef

The roles method returns consumed roles.

=over 4

=item roles example

  my $roles = $any->roles();

=back

=cut

=head2 rules

  rules() : ArrayRef

The rules method returns consumed rules.

=over 4

=item rules example

  my $rules = $any->rules();

=back

=cut

=head1 ROLES

This package inherits all behavior from the folowing role(s):

=cut

=over 4

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Dumper>

=item *

L<Data::Object::Role::Output>

=item *

L<Data::Object::Role::Throwable>

=back

=head1 RULES

This package adheres to the requirements in the folowing rule(s):

=cut

=over 4

=item *

L<Data::Object::Rule::Comparison>

=item *

L<Data::Object::Rule::Defined>

=back
