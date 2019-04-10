package Data::Object::Code;

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
  Data::Object::Role::Throwable
);

map with($_), my @rules = qw(
  Data::Object::Rule::Defined
);

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  '&{}'    => 'self',
  fallback => 1
);

use parent 'Data::Object::Base::Code';

our $VERSION = '0.96'; # VERSION

# BUILD
# METHODS

sub self {
  return shift;
}

sub roles {
  return cast([@roles]);
}

sub rules {
  return cast([@rules]);
}

# DISPATCHERS

sub call {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Code::Call';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub compose {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Code::Compose';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub conjoin {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Code::Conjoin';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub curry {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Code::Curry';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub defined {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Code::Defined';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub disjoin {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Code::Disjoin';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub next {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Code::Next';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub rcurry {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Code::Rcurry';

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

Data::Object::Code

=cut

=head1 ABSTRACT

Data-Object Code Class

=cut

=head1 SYNOPSIS

  use Data::Object::Code;

  my $code = Data::Object::Code->new(sub { shift + 1 });

=cut

=head1 DESCRIPTION

Data::Object::Code provides routines for operating on Perl 5 code
references. Code methods work on code references.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 call

  call(Any $arg1) : Any

The call method executes and returns the result of the code. This method returns
a data type object to be determined after execution.

=over 4

=item call example

  # given sub { (shift // 0) + 1 }

  $code->call; # 1
  $code->call(0); # 1
  $code->call(1); # 2
  $code->call(2); # 3

=back

=cut

=head2 compose

  compose(CodeRef $arg1, Any $arg2) : CodeObject

The compose method creates a code reference which executes the first argument
(another code reference) using the result from executing the code as it's
argument, and returns a code reference which executes the created code reference
passing it the remaining arguments when executed. This method returns a
L<Data::Object::Code> object.

=over 4

=item compose example

  # given sub { [@_] }

  $code = $code->compose($code, 1,2,3);
  $code->(4,5,6); # [[1,2,3,4,5,6]]

  # this can be confusing, here's what's really happening:
  my $listing = sub {[@_]}; # produces an arrayref of args
  $listing->($listing->(@args)); # produces a listing within a listing
  [[@args]] # the result

=back

=cut

=head2 conjoin

  conjoin(CodeRef $arg1) : CodeObject

The conjoin method creates a code reference which execute the code and the
argument in a logical AND operation having the code as the lvalue and the
argument as the rvalue. This method returns a L<Data::Object::Code> object.

=over 4

=item conjoin example

  # given sub { $_[0] % 2 }

  $code = $code->conjoin(sub { 1 });
  $code->(0); # 0
  $code->(1); # 1
  $code->(2); # 0
  $code->(3); # 1
  $code->(4); # 0

=back

=cut

=head2 curry

  curry(CodeRef $arg1) : CodeObject

The curry method returns a code reference which executes the code passing it
the arguments and any additional parameters when executed. This method returns a
L<Data::Object::Code> object.

=over 4

=item curry example

  # given sub { [@_] }

  $code = $code->curry(1,2,3);
  $code->(4,5,6); # [1,2,3,4,5,6]

=back

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given $code

  $code->defined; # 1

=back

=cut

=head2 disjoin

  disjoin(CodeRef $arg1) : CodeRef

The disjoin method creates a code reference which execute the code and the
argument in a logical OR operation having the code as the lvalue and the
argument as the rvalue. This method returns a L<Data::Object::Code> object.

=over 4

=item disjoin example

  # given sub { $_[0] % 2 }

  $code = $code->disjoin(sub { -1 });
  $code->(0); # -1
  $code->(1); #  1
  $code->(2); # -1
  $code->(3); #  1
  $code->(4); # -1

=back

=cut

=head2 next

  next(Any $arg1) : Any

The next method is an alias to the call method. The naming is especially useful
(i.e. helps with readability) when used with closure-based iterators. This
method returns a L<Data::Object::Code> object. This method is an alias to the
call method.

=over 4

=item next example

  $code->next;

=back

=cut

=head2 rcurry

  rcurry(Any $arg1) : CodeObject

The rcurry method returns a code reference which executes the code passing it
the any additional parameters and any arguments when executed. This method
returns a L<Data::Object::Code> object.

=over 4

=item rcurry example

  # given sub { [@_] }

  $code = $code->rcurry(1,2,3);
  $code->(4,5,6); # [4,5,6,1,2,3]

=back

=cut

=head2 roles

  roles() : ArrayRef

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=over 4

=item roles example

  # given $code

  $code->roles;

=back

=cut

=head2 rules

  rules() : ArrayRef

The rules method returns consumed rules.

=over 4

=item rules example

  my $rules = $code->rules();

=back

=cut

=head2 self

  self() : Object

The self method returns the calling object (noop).

=over 4

=item self example

  my $self = $code->self();

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

L<Data::Object::Role::Throwable>

=back

=head1 RULES

This package adheres to the requirements in the folowing rule(s):

=cut

=over 4

=item *

L<Data::Object::Rule::Defined>

=back
