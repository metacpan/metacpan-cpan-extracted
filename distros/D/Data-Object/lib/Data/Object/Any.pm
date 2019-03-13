package Data::Object::Any;

use Try::Tiny;

use Data::Object::Class;
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
  Data::Object::Role::Type
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

use parent 'Data::Object::Kind';

# BUILD

sub new {
  my ($class, $arg) = @_;

  my $role = 'Data::Object::Role::Type';

  if (Scalar::Util::blessed($arg)) {
    $arg = $arg->data if $arg->can('does') && $arg->does($role);
  }
  if (Scalar::Util::blessed($arg) && $arg->isa('Regexp') && $^V <= v5.12.0) {
    $arg = do { \(my $q = qr/$arg/) };
  }

  return bless ref($arg) ? $arg : \$arg, $class;
}

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

=head2 new

  my $any = Data::Object::Any->new(\*main);

Construct a new object.

=cut

=head2 roles

  my $roles = $any->roles();

The roles method returns consumed roles.

=cut

=head2 rules

  my $rules = $any->rules();

The rules method returns consumed rules.

=cut

=head2 defined

  my $defined = $self->defined();

The defined method returns truthy for defined data.

=cut

=head2 eq

  my $eq = $self->eq();

The eq method returns truthy if argument and object data are equal.

=cut

=head2 gt

  my $gt = $self->gt();

The gt method returns truthy if argument is greater then the object data.

=cut

=head2 ge

  my $ge = $self->ge();

The ge method returns truthy if argument is greater or equal to the object data.

=cut

=head2 lt

  my $lt = $self->lt();

The lt method returns truthy if argument is lesser than the object data.

=cut

=head2 le

  my $le = $self->le();

The le method returns truthy if argument is lesser or equal to the object data.

=cut

=head2 ne

  my $ne = $self->ne();

The ne method returns truthy if argument and object data are not equal.

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

=item *

L<Data::Object::Role::Type>

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
