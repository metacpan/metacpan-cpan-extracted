package Data::Object::Array;

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
  Data::Object::Rule::Collection
  Data::Object::Rule::Comparison
  Data::Object::Rule::Defined
  Data::Object::Rule::List
);

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  '@{}'    => 'self',
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

  unless (ref($arg) eq 'ARRAY') {
    croak('Instantiation Error: Not a ArrayRef');
  }

  return bless $arg, $class;
}

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

sub all {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::All';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub any {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Any';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub clear {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Clear';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub count {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Count';

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
    my $func = 'Data::Object::Func::Array::Defined';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub delete {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Delete';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub each {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Each';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub each_key {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::EachKey';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub each_n_values {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::EachNValues';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub each_value {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::EachValue';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub empty {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Empty';

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
    my $func = 'Data::Object::Func::Array::Eq';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub exists {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Exists';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub first {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::First';

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
    my $func = 'Data::Object::Func::Array::Ge';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub get {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Get';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub grep {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Grep';

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
    my $func = 'Data::Object::Func::Array::Gt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub hash {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Hash';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub hashify {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Hashify';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub head {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Head';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub invert {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Invert';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub iterator {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Iterator';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub join {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Join';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub keyed {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Keyed';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub keys {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Keys';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub last {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Last';

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
    my $func = 'Data::Object::Func::Array::Le';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub length {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Length';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub list {
  my ($self) = @_;

  my @retv = (map cast($_), @$self);

  return wantarray ? (@retv) : cast([@retv]);
}

sub lt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Lt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub map {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Map';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub max {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Max';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub min {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Min';

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
    my $func = 'Data::Object::Func::Array::Ne';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub none {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::None';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub nsort {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Nsort';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub one {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::One';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub pairs {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Pairs';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub pairs_array {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::PairsArray';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub pairs_hash {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::PairsHash';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub part {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Part';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub pop {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Pop';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub push {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Push';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub random {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Random';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub reverse {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Reverse';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub rotate {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Rotate';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub rnsort {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Rnsort';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub rsort {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Rsort';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub set {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Set';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub shift {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Shift';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub size {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Size';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub slice {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Slice';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub sort {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Sort';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub sum {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Sum';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub tail {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Tail';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub unique {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Unique';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub unshift {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Unshift';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub values {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Array::Values';

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

Data::Object::Array

=cut

=head1 ABSTRACT

Data-Object Array Class

=cut

=head1 SYNOPSIS

  use Data::Object::Array;

  my $array = Data::Object::Array->new([1..9]);

=cut

=head1 DESCRIPTION

Data::Object::Array provides routines for operating on Perl 5 array
references. Array methods work on array references. Users of these methods
should be aware of the methods that modify the array reference itself as opposed
to returning a new array reference. Unless stated, it may be safe to assume that
the following methods copy, modify and return new array references based on
their function.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 all

  all(CodeRef $arg1, Any @args) : NumObject

The all method returns true if all of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=over 4

=item all example

  # given [2..5]

  $array->all('$value > 1'); # 1; true
  $array->all('$value > 3'); # 0; false|

=back

=cut

=head2 any

  any(CodeRef $arg1, Any @args) : NumObject

The any method returns true if any of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=over 4

=item any example

  # given [2..5]

  $array->any('$value > 5'); # 0; false
  $array->any('$value > 3'); # 1; true

=back

=cut

=head2 clear

  clear() : Object

The clear method is an alias to the empty method. This method returns a
L<Data::Object::Undef> object. This method is an alias to the empty method.
Note: This method modifies the array.

=over 4

=item clear example

  # given ['a'..'g']

  $array->clear; # []

=back

=cut

=head2 count

  count() : NumObject

The count method returns the number of elements within the array. This method
returns a L<Data::Object::Number> object.

=over 4

=item count example

  # given [1..5]

  $array->count; # 5

=back

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the element within the array at the index
specified by the argument meets the criteria for being defined, otherwise it
returns false. This method returns a L<Data::Object::Number> object.

=over 4

=item defined example

  # given [1,2,undef,4,5]

  $array->defined(2); # 0; false
  $array->defined(1); # 1; true

=back

=cut

=head2 delete

  delete(Int $arg1) : Any

The delete method returns the value of the element within the array at the
index specified by the argument after removing it from the array. This method
returns a data type object to be determined after execution. Note: This method
modifies the array.

=over 4

=item delete example

  # given [1..5]

  $array->delete(2); # 3

=back

=cut

=head2 each

  each(CodeRef $arg1, Any @args) : Object

The each method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the index and value at
the current position in the loop. This method supports codification, i.e, takes
an argument which can be a codifiable string, a code reference, or a code data
type object. This method returns a L<Data::Object::Array> object.

=over 4

=item each example

  # given ['a'..'g']

  $array->each(sub{
      my $index = shift; # 0
      my $value = shift; # a
      ...
  });

=back

=cut

=head2 each_key

  each_key(CodeRef $arg1, Any @args) : Object

The each_key method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the index at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a L<Data::Object::Array> object.

=over 4

=item each_key example

  # given ['a'..'g']

  $array->each_key(sub{
      my $index = shift; # 0
      ...
  });

=back

=cut

=head2 each_n_values

  each_n_values(Num $arg1, CodeRef $arg2, Any @args) : Object

The each_n_values method iterates over each element in the array, executing
the code reference supplied in the argument, passing the routine the next n
values until all values have been seen. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Array> object.

=over 4

=item each_n_values example

  # given ['a'..'g']

  $array->each_n_values(4, sub{
      my $value_1 = shift; # a
      my $value_2 = shift; # b
      my $value_3 = shift; # c
      my $value_4 = shift; # d
      ...
  });

=back

=cut

=head2 each_value

  each_key(CodeRef $arg1, Any @args) : Object

The each_value method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a L<Data::Object::Array> object.

=over 4

=item each_value example

  # given ['a'..'g']

  $array->each_value(sub{
      my $value = shift; # a
      ...
  });

=back

=cut

=head2 empty

  empty() : Object

The empty method drops all elements from the array. This method returns a
L<Data::Object::Array> object. Note: This method modifies the array.

=over 4

=item empty example

  # given ['a'..'g']

  $array->empty; # []

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item eq example

  # given $array

  $array->eq; # exception thrown

=back

=cut

=head2 exists

  exists(Int $arg1) : NumObject

The exists method returns true if the element within the array at the index
specified by the argument exists, otherwise it returns false. This method
returns a L<Data::Object::Number> object.

=over 4

=item exists example

  # given [1,2,3,4,5]

  $array->exists(5); # 0; false
  $array->exists(0); # 1; true

=back

=cut

=head2 first

  first() : Any

The first method returns the value of the first element in the array. This
method returns a data type object to be determined after execution.

=over 4

=item first example

  # given [1..5]

  $array->first; # 1

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item ge example

  # given $array

  $array->ge; # exception thrown

=back

=cut

=head2 get

  get(Int $arg1) : Any

The get method returns the value of the element in the array at the index
specified by the argument. This method returns a data type object to be
determined after execution.

=over 4

=item get example

  # given [1..5]

  $array->get(0); # 1;

=back

=cut

=head2 grep

  grep(CodeRef $arg1, Any @args) : ArrayObject

The grep method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing
the elements for which the argument evaluated true. This method supports
codification, i.e, takes an argument which can be a codifiable string, a code
reference, or a code data type object. This method returns a
L<Data::Object::Array> object.

=over 4

=item grep example

  # given [1..5]

  $array->grep(sub{
      shift >= 3
  });

  # [3,4,5]

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item gt example

  # given $array

  $array->gt; # exception thrown

=back

=cut

=head2 hash

  hash() : HashObject

The hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array. This method
returns a L<Data::Object::Hash> object.

=over 4

=item hash example

  # given [1..5]

  $array->hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

=back

=cut

=head2 hashify

  hashify(CodeRef $arg1, Any $arg2) : HashObject

The hashify method returns a hash reference where the elements of array become
the hash keys and the corresponding values are assigned a value of 1. This
method supports codification, i.e, takes an argument which can be a codifiable
string, a code reference, or a code data type object. Note, undefined elements
will be dropped. This method returns a L<Data::Object::Hash> object.

=over 4

=item hashify example

  # given [1..5]

  $array->hashify; # {1=>1,2=>1,3=>1,4=>1,5=>1}
  $array->hashify(sub { shift % 2 }); # {1=>1,2=>0,3=>1,4=>0,5=>1}

=back

=cut

=head2 head

  head() : Any

The head method returns the value of the first element in the array. This
method returns a data type object to be determined after execution.

=over 4

=item head example

  # given [9,8,7,6,5]

  my $head = $array->head; # 9

=back

=cut

=head2 invert

  invert() : Any

The invert method returns an array reference containing the elements in the
array in reverse order. This method returns a L<Data::Object::Array> object.

=over 4

=item invert example

  # given [1..5]

  $array->invert; # [5,4,3,2,1]

=back

=cut

=head2 iterator

  iterator() : CodeObject

The iterator method returns a code reference which can be used to iterate over
the array. Each time the iterator is executed it will return the next element
in the array until all elements have been seen, at which point the iterator
will return an undefined value. This method returns a L<Data::Object::Code>
object.

=over 4

=item iterator example

  # given [1..5]

  my $iterator = $array->iterator;
  while (my $value = $iterator->next) {
      say $value; # 1
  }

=back

=cut

=head2 join

  join(Str $arg1) : StrObject

The join method returns a string consisting of all the elements in the array
joined by the join-string specified by the argument. Note: If the argument is
omitted, an empty string will be used as the join-string. This method returns a
L<Data::Object::String> object.

=over 4

=item join example

  # given [1..5]

  $array->join; # 12345
  $array->join(', '); # 1, 2, 3, 4, 5

=back

=cut

=head2 keyed

  keyed(Str $arg1) : HashObject

The keyed method returns a hash reference where the arguments become the keys,
and the elements of the array become the values. This method returns a
L<Data::Object::Hash> object.

=over 4

=item keyed example

  # given [1..5]

  $array->keyed('a'..'d'); # {a=>1,b=>2,c=>3,d=>4}

=back

=cut

=head2 keys

  keys() : ArrayObject

The keys method returns an array reference consisting of the indicies of the
array. This method returns a L<Data::Object::Array> object.

=over 4

=item keys example

  # given ['a'..'d']

  $array->keys; # [0,1,2,3]

=back

=cut

=head2 last

  last() : Any

The last method returns the value of the last element in the array. This method
returns a data type object to be determined after execution.

=over 4

=item last example

  # given [1..5]

  $array->last; # 5

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item le example

  # given $array

  $array->le; # exception thrown

=back

=cut

=head2 length

  length() : NumObject

The length method returns the number of elements in the array. This method
returns a L<Data::Object::Number> object.

=over 4

=item length example

  # given [1..5]

  $array->length; # 5

=back

=cut

=head2 list

  list() : ArrayObject

The list method returns a shallow copy of the underlying array reference as an
array reference. This method return a L<Data::Object::Array> object.

=over 4

=item list example

  # given $array

  my $list = $array->list;

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item lt example

  # given $array

  $array->lt; # exception thrown

=back

=cut

=head2 map

  map(CodeRef $arg1, Any $arg2) : ArrayObject

The map method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing
the elements for which the argument returns a value or non-empty list. This
method returns a L<Data::Object::Array> object.

=over 4

=item map example

  # given [1..5]

  $array->map(sub{
      shift + 1
  });

  # [2,3,4,5,6]

=back

=cut

=head2 max

  max() : Any

The max method returns the element in the array with the highest numerical
value. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=over 4

=item max example

  # given [8,9,1,2,3,4,5]

  $array->max; # 9

=back

=cut

=head2 min

  min() : Any

The min method returns the element in the array with the lowest numerical
value. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=over 4

=item min example

  # given [8,9,1,2,3,4,5]

  $array->min; # 1

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item ne example

  # given $array

  $array->ne; # exception thrown

=back

=cut

=head2 new

  new(ArrayRef $arg1) : ArrayObject

The new method expects a list or array reference and returns a new class
instance.

=over 4

=item new example

  # given 1..9

  my $array = Data::Object::Array->new(1..9);
  my $array = Data::Object::Array->new([1..9]);

=back

=cut

=head2 none

  none(CodeRef $arg1, Any $arg2) : NumObject

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=over 4

=item none example

  # given [2..5]

  $array->none('$value <= 1'); # 1; true
  $array->none('$value <= 2'); # 0; false

=back

=cut

=head2 nsort

  nsort() : ArrayObject

The nsort method returns an array reference containing the values in the array
sorted numerically. This method returns a L<Data::Object::Array> object.

=over 4

=item nsort example

  # given [5,4,3,2,1]

  $array->nsort; # [1,2,3,4,5]

=back

=cut

=head2 one

  one(CodeRef $arg1, Any $arg2) : NumObject

The one method returns true if only one of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=over 4

=item one example

  # given [2..5]

  $array->one('$value == 5'); # 1; true
  $array->one('$value == 6'); # 0; false

=back

=cut

=head2 pairs

  pairs() : ArrayObject

The pairs method is an alias to the pairs_array method. This method returns a
L<Data::Object::Array> object. This method is an alias to the pairs_array
method.

=over 4

=item pairs example

  # given [1..5]

  $array->pairs; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

=back

=cut

=head2 pairs_array

  pairs() : ArrayObject

The pairs_array method returns an array reference consisting of array references
where each sub-array reference has two elements corresponding to the index and
value of each element in the array. This method returns a L<Data::Object::Array>
object.

=over 4

=item pairs_array example

  # given [1..5]

  $array->pairs_array; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

=back

=cut

=head2 pairs_hash

  pairs() : ArrayObject

The pairs_hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array. This method
returns a L<Data::Object::Hash> object.

=over 4

=item pairs_hash example

  # given [1..5]

  $array->pairs_hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

=back

=cut

=head2 part

  part(CodeRef $arg1, Any $arg2) : Tuple[ArrayRef, ArrayRef]

The part method iterates over each element in the array, executing the
code reference supplied in the argument, using the result of the code reference
to partition to array into two distinct array references. This method returns
an array reference containing exactly two array references. This method supports
codification, i.e, takes an argument which can be a codifiable string, a code
reference, or a code data type object. This method returns a
L<Data::Object::Array> object.

=over 4

=item part example

  # given [1..10]

  $array->part(sub { shift > 5 }); # [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]]

=back

=cut

=head2 pop

  pop() : Any

The pop method returns the last element of the array shortening it by one. Note,
this method modifies the array. This method returns a data type object to be
determined after execution. Note: This method modifies the array.

=over 4

=item pop example

  # given [1..5]

  $array->pop; # 5

=back

=cut

=head2 push

  push(Any $arg1) : Any

The push method appends the array by pushing the agruments onto it and returns
itself. This method returns a data type object to be determined after execution.
Note: This method modifies the array.

=over 4

=item push example

  # given [1..5]

  $array->push(6,7,8); # [1,2,3,4,5,6,7,8]

=back

=cut

=head2 random

  random() : NumObject

The random method returns a random element from the array. This method returns a
data type object to be determined after execution.

=over 4

=item random example

  # given [1..5]

  $array->random; # 4

=back

=cut

=head2 reverse

  reverse() : ArrayObject

The reverse method returns an array reference containing the elements in the
array in reverse order. This method returns a L<Data::Object::Array> object.

=over 4

=item reverse example

  # given [1..5]

  $array->reverse; # [5,4,3,2,1]

=back

=cut

=head2 rnsort

  rnsort() : ArrayObject

The rnsort method returns an array reference containing the values in the
array sorted numerically in reverse. This method returns a
L<Data::Object::Array> object.

=over 4

=item rnsort example

  # given [5,4,3,2,1]

  $array->rnsort; # [5,4,3,2,1]

=back

=cut

=head2 roles

  roles() : ArrayRef

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=over 4

=item roles example

  # given $array

  $array->roles;

=back

=cut

=head2 rotate

  rotate() : ArrayObject

The rotate method rotates the elements in the array such that first elements
becomes the last element and the second element becomes the first element each
time this method is called. This method returns a L<Data::Object::Array> object.
Note: This method modifies the array.

=over 4

=item rotate example

  # given [1..5]

  $array->rotate; # [2,3,4,5,1]
  $array->rotate; # [3,4,5,1,2]
  $array->rotate; # [4,5,1,2,3]

=back

=cut

=head2 rsort

  rsort() : ArrayObject

The rsort method returns an array reference containing the values in the array
sorted alphanumerically in reverse. This method returns a L<Data::Object::Array>
object.

=over 4

=item rsort example

  # given ['a'..'d']

  $array->rsort; # ['d','c','b','a']

=back

=cut

=head2 rules

  rules() : ArrayRef

The rules method returns consumed rules.

=over 4

=item rules example

  my $rules = $array->rules();

=back

=cut

=head2 self

  self() : Object

The self method returns the calling object (noop).

=over 4

=item self example

  my $self = $array->self();

=back

=cut

=head2 set

  set(Str $arg1, Any $arg2) : Any

The set method returns the value of the element in the array at the index
specified by the argument after updating it to the value of the second argument.
This method returns a data type object to be determined after execution. Note:
This method modifies the array.

=over 4

=item set example

  # given [1..5]

  $array->set(4,6); # [1,2,3,4,6]

=back

=cut

=head2 shift

  shift() : Any

The shift method returns the first element of the array shortening it by one.
This method returns a data type object to be determined after execution. Note:
This method modifies the array.

=over 4

=item shift example

  # given [1..5]

  $array->shift; # 1

=back

=cut

=head2 size

  size() : NumObject

The size method is an alias to the length method. This method returns a
L<Data::Object::Number> object. This method is an alias to the length method.

=over 4

=item size example

  # given [1..5]

  $array->size; # 5

=back

=cut

=head2 slice

  slice(Any $arg1) : Any

The slice method returns an array reference containing the elements in the
array at the index(es) specified in the arguments. This method returns a
L<Data::Object::Array> object.

=over 4

=item slice example

  # given [1..5]

  $array->slice(2,4); # [3,5]

=back

=cut

=head2 sort

  sort() : ArrayObject

The sort method returns an array reference containing the values in the array
sorted alphanumerically. This method returns a L<Data::Object::Array> object.

=over 4

=item sort example

  # given ['d','c','b','a']

  $array->sort; # ['a','b','c','d']

=back

=cut

=head2 sum

  sum() : NumObject

The sum method returns the sum of all values for all numerical elements in the
array. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=over 4

=item sum example

  # given [1..5]

  $array->sum; # 15

=back

=cut

=head2 tail

  tail() : Any

The tail method returns an array reference containing the second through the
last elements in the array omitting the first. This method returns a
L<Data::Object::Array> object.

=over 4

=item tail example

  # given [1..5]

  $array->tail; # [2,3,4,5]

=back

=cut

=head2 unique

  unique() : ArrayObject

The unique method returns an array reference consisting of the unique elements
in the array. This method returns a L<Data::Object::Array> object.

=over 4

=item unique example

  # given [1,1,1,1,2,3,1]

  $array->unique; # [1,2,3]

=back

=cut

=head2 unshift

  unshift() : Any

The unshift method prepends the array by pushing the agruments onto it and
returns itself. This method returns a data type object to be determined after
execution. Note: This method modifies the array.

=over 4

=item unshift example

  # given [1..5]

  $array->unshift(-2,-1,0); # [-2,-1,0,1,2,3,4,5]

=back

=cut

=head2 values

  values(Str $arg1) : ArrayObject

The values method returns an array reference consisting of the elements in the
array. This method essentially copies the content of the array into a new
container. This method returns a L<Data::Object::Array> object.

=over 4

=item values example

  # given [1..5]

  $array->values; # [1,2,3,4,5]

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

=item *

L<Data::Object::Role::Type>

=back

=head1 RULES

This package adheres to the requirements in the folowing rule(s):

=cut

=over 4

=item *

L<Data::Object::Rule::Collection>

=item *

L<Data::Object::Rule::Comparison>

=item *

L<Data::Object::Rule::Defined>

=item *

L<Data::Object::Rule::List>

=back
