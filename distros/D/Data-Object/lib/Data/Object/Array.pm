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

=head2 new

  # given 1..9

  my $array = Data::Object::Array->new(1..9);
  my $array = Data::Object::Array->new([1..9]);

The new method expects a list or array reference and returns a new class
instance.

=cut

=head2 self

  my $self = $array->self();

The self method returns the calling object (noop).

=cut

=head2 roles

  # given $array

  $array->roles;

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=cut

=head2 rules

  my $rules = $array->rules();

The rules method returns consumed rules.

=cut

=head2 all

  # given [2..5]

  $array->all('$value > 1'); # 1; true
  $array->all('$value > 3'); # 0; false|

The all method returns true if all of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=cut

=head2 any

  # given [2..5]

  $array->any('$value > 5'); # 0; false
  $array->any('$value > 3'); # 1; true

The any method returns true if any of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=cut

=head2 clear

  # given ['a'..'g']

  $array->clear; # []

The clear method is an alias to the empty method. This method returns a
L<Data::Object::Undef> object. This method is an alias to the empty method.
Note: This method modifies the array.

=cut

=head2 count

  # given [1..5]

  $array->count; # 5

The count method returns the number of elements within the array. This method
returns a L<Data::Object::Number> object.

=cut

=head2 defined

  # given [1,2,undef,4,5]

  $array->defined(2); # 0; false
  $array->defined(1); # 1; true

The defined method returns true if the element within the array at the index
specified by the argument meets the criteria for being defined, otherwise it
returns false. This method returns a L<Data::Object::Number> object.

=cut

=head2 delete

  # given [1..5]

  $array->delete(2); # 3

The delete method returns the value of the element within the array at the
index specified by the argument after removing it from the array. This method
returns a data type object to be determined after execution. Note: This method
modifies the array.

=cut

=head2 each

  # given ['a'..'g']

  $array->each(sub{
      my $index = shift; # 0
      my $value = shift; # a
      ...
  });

The each method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the index and value at
the current position in the loop. This method supports codification, i.e, takes
an argument which can be a codifiable string, a code reference, or a code data
type object. This method returns a L<Data::Object::Array> object.

=cut

=head2 each_key

  # given ['a'..'g']

  $array->each_key(sub{
      my $index = shift; # 0
      ...
  });

The each_key method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the index at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a L<Data::Object::Array> object.

=cut

=head2 each_n_values

  # given ['a'..'g']

  $array->each_n_values(4, sub{
      my $value_1 = shift; # a
      my $value_2 = shift; # b
      my $value_3 = shift; # c
      my $value_4 = shift; # d
      ...
  });

The each_n_values method iterates over each element in the array, executing
the code reference supplied in the argument, passing the routine the next n
values until all values have been seen. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Array> object.

=cut

=head2 each_value

  # given ['a'..'g']

  $array->each_value(sub{
      my $value = shift; # a
      ...
  });

The each_value method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a L<Data::Object::Array> object.

=cut

=head2 empty

  # given ['a'..'g']

  $array->empty; # []

The empty method drops all elements from the array. This method returns a
L<Data::Object::Array> object. Note: This method modifies the array.

=cut

=head2 eq

  # given $array

  $array->eq; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 exists

  # given [1,2,3,4,5]

  $array->exists(5); # 0; false
  $array->exists(0); # 1; true

The exists method returns true if the element within the array at the index
specified by the argument exists, otherwise it returns false. This method
returns a L<Data::Object::Number> object.

=cut

=head2 first

  # given [1..5]

  $array->first; # 1

The first method returns the value of the first element in the array. This
method returns a data type object to be determined after execution.

=cut

=head2 ge

  # given $array

  $array->ge; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 get

  # given [1..5]

  $array->get(0); # 1;

The get method returns the value of the element in the array at the index
specified by the argument. This method returns a data type object to be
determined after execution.

=cut

=head2 grep

  # given [1..5]

  $array->grep(sub{
      shift >= 3
  });

  # [3,4,5]

The grep method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing
the elements for which the argument evaluated true. This method supports
codification, i.e, takes an argument which can be a codifiable string, a code
reference, or a code data type object. This method returns a
L<Data::Object::Array> object.

=cut

=head2 gt

  # given $array

  $array->gt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 hash

  # given [1..5]

  $array->hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

The hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array. This method
returns a L<Data::Object::Hash> object.

=cut

=head2 hashify

  # given [1..5]

  $array->hashify; # {1=>1,2=>1,3=>1,4=>1,5=>1}
  $array->hashify(sub { shift % 2 }); # {1=>1,2=>0,3=>1,4=>0,5=>1}

The hashify method returns a hash reference where the elements of array become
the hash keys and the corresponding values are assigned a value of 1. This
method supports codification, i.e, takes an argument which can be a codifiable
string, a code reference, or a code data type object. Note, undefined elements
will be dropped. This method returns a L<Data::Object::Hash> object.

=cut

=head2 head

  # given [9,8,7,6,5]

  my $head = $array->head; # 9

The head method returns the value of the first element in the array. This
method returns a data type object to be determined after execution.

=cut

=head2 invert

  # given [1..5]

  $array->invert; # [5,4,3,2,1]

The invert method returns an array reference containing the elements in the
array in reverse order. This method returns a L<Data::Object::Array> object.

=cut

=head2 iterator

  # given [1..5]

  my $iterator = $array->iterator;
  while (my $value = $iterator->next) {
      say $value; # 1
  }

The iterator method returns a code reference which can be used to iterate over
the array. Each time the iterator is executed it will return the next element
in the array until all elements have been seen, at which point the iterator
will return an undefined value. This method returns a L<Data::Object::Code>
object.

=cut

=head2 join

  # given [1..5]

  $array->join; # 12345
  $array->join(', '); # 1, 2, 3, 4, 5

The join method returns a string consisting of all the elements in the array
joined by the join-string specified by the argument. Note: If the argument is
omitted, an empty string will be used as the join-string. This method returns a
L<Data::Object::String> object.

=cut

=head2 keyed

  # given [1..5]

  $array->keyed('a'..'d'); # {a=>1,b=>2,c=>3,d=>4}

The keyed method returns a hash reference where the arguments become the keys,
and the elements of the array become the values. This method returns a
L<Data::Object::Hash> object.

=cut

=head2 keys

  # given ['a'..'d']

  $array->keys; # [0,1,2,3]

The keys method returns an array reference consisting of the indicies of the
array. This method returns a L<Data::Object::Array> object.

=cut

=head2 last

  # given [1..5]

  $array->last; # 5

The last method returns the value of the last element in the array. This method
returns a data type object to be determined after execution.

=cut

=head2 le

  # given $array

  $array->le; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 length

  # given [1..5]

  $array->length; # 5

The length method returns the number of elements in the array. This method
returns a L<Data::Object::Number> object.

=cut

=head2 list

  # given $array

  my $list = $array->list;

The list method returns a shallow copy of the underlying array reference as an
array reference. This method return a L<Data::Object::Array> object.

=cut

=head2 lt

  # given $array

  $array->lt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 map

  # given [1..5]

  $array->map(sub{
      shift + 1
  });

  # [2,3,4,5,6]

The map method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing
the elements for which the argument returns a value or non-empty list. This
method returns a L<Data::Object::Array> object.

=cut

=head2 max

  # given [8,9,1,2,3,4,5]

  $array->max; # 9

The max method returns the element in the array with the highest numerical
value. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=cut

=head2 min

  # given [8,9,1,2,3,4,5]

  $array->min; # 1

The min method returns the element in the array with the lowest numerical
value. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=cut

=head2 ne

  # given $array

  $array->ne; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 none

  # given [2..5]

  $array->none('$value <= 1'); # 1; true
  $array->none('$value <= 2'); # 0; false

The none method returns true if none of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=cut

=head2 nsort

  # given [5,4,3,2,1]

  $array->nsort; # [1,2,3,4,5]

The nsort method returns an array reference containing the values in the array
sorted numerically. This method returns a L<Data::Object::Array> object.

=cut

=head2 one

  # given [2..5]

  $array->one('$value == 5'); # 1; true
  $array->one('$value == 6'); # 0; false

The one method returns true if only one of the elements in the array meet the
criteria set by the operand and rvalue. This method supports codification, i.e,
takes an argument which can be a codifiable string, a code reference, or a code
data type object. This method returns a L<Data::Object::Number> object.

=cut

=head2 pairs

  # given [1..5]

  $array->pairs; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

The pairs method is an alias to the pairs_array method. This method returns a
L<Data::Object::Array> object. This method is an alias to the pairs_array
method.

=cut

=head2 pairs_array

  # given [1..5]

  $array->pairs_array; # [[0,1],[1,2],[2,3],[3,4],[4,5]]

The pairs_array method returns an array reference consisting of array references
where each sub-array reference has two elements corresponding to the index and
value of each element in the array. This method returns a L<Data::Object::Array>
object.

=cut

=head2 pairs_hash

  # given [1..5]

  $array->pairs_hash; # {0=>1,1=>2,2=>3,3=>4,4=>5}

The pairs_hash method returns a hash reference where each key and value pairs
corresponds to the index and value of each element in the array. This method
returns a L<Data::Object::Hash> object.

=cut

=head2 part

  # given [1..10]

  $array->part(sub { shift > 5 }); # [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]]

The part method iterates over each element in the array, executing the
code reference supplied in the argument, using the result of the code reference
to partition to array into two distinct array references. This method returns
an array reference containing exactly two array references. This method supports
codification, i.e, takes an argument which can be a codifiable string, a code
reference, or a code data type object. This method returns a
L<Data::Object::Array> object.

=cut

=head2 pop

  # given [1..5]

  $array->pop; # 5

The pop method returns the last element of the array shortening it by one. Note,
this method modifies the array. This method returns a data type object to be
determined after execution. Note: This method modifies the array.

=cut

=head2 push

  # given [1..5]

  $array->push(6,7,8); # [1,2,3,4,5,6,7,8]

The push method appends the array by pushing the agruments onto it and returns
itself. This method returns a data type object to be determined after execution.
Note: This method modifies the array.

=cut

=head2 random

  # given [1..5]

  $array->random; # 4

The random method returns a random element from the array. This method returns a
data type object to be determined after execution.

=cut

=head2 reverse

  # given [1..5]

  $array->reverse; # [5,4,3,2,1]

The reverse method returns an array reference containing the elements in the
array in reverse order. This method returns a L<Data::Object::Array> object.

=cut

=head2 rotate

  # given [1..5]

  $array->rotate; # [2,3,4,5,1]
  $array->rotate; # [3,4,5,1,2]
  $array->rotate; # [4,5,1,2,3]

The rotate method rotates the elements in the array such that first elements
becomes the last element and the second element becomes the first element each
time this method is called. This method returns a L<Data::Object::Array> object.
Note: This method modifies the array.

=cut

=head2 rnsort

  # given [5,4,3,2,1]

  $array->rnsort; # [5,4,3,2,1]

The rnsort method returns an array reference containing the values in the
array sorted numerically in reverse. This method returns a
L<Data::Object::Array> object.

=cut

=head2 rsort

  # given ['a'..'d']

  $array->rsort; # ['d','c','b','a']

The rsort method returns an array reference containing the values in the array
sorted alphanumerically in reverse. This method returns a L<Data::Object::Array>
object.

=cut

=head2 set

  # given [1..5]

  $array->set(4,6); # [1,2,3,4,6]

The set method returns the value of the element in the array at the index
specified by the argument after updating it to the value of the second argument.
This method returns a data type object to be determined after execution. Note:
This method modifies the array.

=cut

=head2 shift

  # given [1..5]

  $array->shift; # 1

The shift method returns the first element of the array shortening it by one.
This method returns a data type object to be determined after execution. Note:
This method modifies the array.

=cut

=head2 size

  # given [1..5]

  $array->size; # 5

The size method is an alias to the length method. This method returns a
L<Data::Object::Number> object. This method is an alias to the length method.

=cut

=head2 slice

  # given [1..5]

  $array->slice(2,4); # [3,5]

The slice method returns an array reference containing the elements in the
array at the index(es) specified in the arguments. This method returns a
L<Data::Object::Array> object.

=cut

=head2 sort

  # given ['d','c','b','a']

  $array->sort; # ['a','b','c','d']

The sort method returns an array reference containing the values in the array
sorted alphanumerically. This method returns a L<Data::Object::Array> object.

=cut

=head2 sum

  # given [1..5]

  $array->sum; # 15

The sum method returns the sum of all values for all numerical elements in the
array. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=cut

=head2 tail

  # given [1..5]

  $array->tail; # [2,3,4,5]

The tail method returns an array reference containing the second through the
last elements in the array omitting the first. This method returns a
L<Data::Object::Array> object.

=cut

=head2 unique

  # given [1,1,1,1,2,3,1]

  $array->unique; # [1,2,3]

The unique method returns an array reference consisting of the unique elements
in the array. This method returns a L<Data::Object::Array> object.

=cut

=head2 unshift

  # given [1..5]

  $array->unshift(-2,-1,0); # [-2,-1,0,1,2,3,4,5]

The unshift method prepends the array by pushing the agruments onto it and
returns itself. This method returns a data type object to be determined after
execution. Note: This method modifies the array.

=cut

=head2 values

  # given [1..5]

  $array->values; # [1,2,3,4,5]

The values method returns an array reference consisting of the elements in the
array. This method essentially copies the content of the array into a new
container. This method returns a L<Data::Object::Array> object.

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
