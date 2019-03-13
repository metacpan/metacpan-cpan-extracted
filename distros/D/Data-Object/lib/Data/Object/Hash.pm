package Data::Object::Hash;

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
  '%{}'    => 'self',
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

  unless (ref($arg) eq 'HASH') {
    croak('Instantiation Error: Not a HashRef');
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

sub clear {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Hash::Clear';

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
    my $func = 'Data::Object::Func::Hash::Count';

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
    my $func = 'Data::Object::Func::Hash::Defined';

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
    my $func = 'Data::Object::Func::Hash::Delete';

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
    my $func = 'Data::Object::Func::Hash::Each';

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
    my $func = 'Data::Object::Func::Hash::EachKey';

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
    my $func = 'Data::Object::Func::Hash::EachNValues';

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
    my $func = 'Data::Object::Func::Hash::EachValue';

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
    my $func = 'Data::Object::Func::Hash::Empty';

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
    my $func = 'Data::Object::Func::Hash::Eq';

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
    my $func = 'Data::Object::Func::Hash::Exists';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub filter_exclude {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Hash::FilterExclude';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub filter_include {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Hash::FilterInclude';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub fold {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Hash::Fold';

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
    my $func = 'Data::Object::Func::Hash::Ge';

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
    my $func = 'Data::Object::Func::Hash::Get';

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
    my $func = 'Data::Object::Func::Hash::Grep';

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
    my $func = 'Data::Object::Func::Hash::Gt';

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
    my $func = 'Data::Object::Func::Hash::Head';

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
    my $func = 'Data::Object::Func::Hash::Invert';

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
    my $func = 'Data::Object::Func::Hash::Iterator';

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
    my $func = 'Data::Object::Func::Hash::Join';

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
    my $func = 'Data::Object::Func::Hash::Keys';

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
    my $func = 'Data::Object::Func::Hash::Le';

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
    my $func = 'Data::Object::Func::Hash::Length';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub list {
  my ($self) = @_;

  my @retv = (map cast($_), %$self);

  return wantarray ? (@retv) : cast([@retv]);
}

sub lookup {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Hash::Lookup';

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
    my $func = 'Data::Object::Func::Hash::Lt';

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
    my $func = 'Data::Object::Func::Hash::Map';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub merge {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Hash::Merge';

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
    my $func = 'Data::Object::Func::Hash::Ne';

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
    my $func = 'Data::Object::Func::Hash::Pairs';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub reset {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Hash::Reset';

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
    my $func = 'Data::Object::Func::Hash::Reverse';

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
    my $func = 'Data::Object::Func::Hash::Set';

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
    my $func = 'Data::Object::Func::Hash::Slice';

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
    my $func = 'Data::Object::Func::Hash::Sort';

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
    my $func = 'Data::Object::Func::Hash::Tail';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub unfold {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Hash::Unfold';

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
    my $func = 'Data::Object::Func::Hash::Values';

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

Data::Object::Hash

=cut

=head1 ABSTRACT

Data-Object Hash Class

=cut

=head1 SYNOPSIS

  use Data::Object::Hash;

  my $hash = Data::Object::Hash->new({1..4});

=cut

=head1 DESCRIPTION

Data::Object::Hash provides routines for operating on Perl 5 hash
references. Hash methods work on hash references. Users of these methods should
be aware of the methods that modify the array reference itself as opposed to
returning a new array reference. Unless stated, it may be safe to assume that
the following methods copy, modify and return new hash references based on their
function.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  # given 1..4

  my $hash = Data::Object::Hash->new(1..4);
  my $hash = Data::Object::Hash->new({1..4});

The new method expects a list or hash reference and returns a new class
instance.

=cut

=head2 self

  # given $hash

  my $self = $hash->self();

The self method returns the calling object (noop).

=cut

=head2 roles

  # given $hash

  $hash->roles;

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=cut

=head2 rules

  my $rules = $hash->rules();

The rules method returns consumed rules.

=cut

=head2 clear

  # given {1..8}

  $hash->clear; # {}

The clear method is an alias to the empty method. This method returns a
L<Data::Object::Hash> object. This method is an alias to the empty method.

=cut

=head2 count

  # given {1..4}

  my $count = $hash->count; # 2

The count method returns the total number of keys defined. This method returns
a L<Data::Object::Number> object.

=cut

=head2 defined

  # given {1..8,9,undef}

  $hash->defined(1); # 1; true
  $hash->defined(0); # 0; false
  $hash->defined(9); # 0; false

The defined method returns true if the value matching the key specified in the
argument if defined, otherwise returns false. This method returns a
L<Data::Object::Number> object.

=cut

=head2 delete

  # given {1..8}

  $hash->delete(1); # 2

The delete method returns the value matching the key specified in the argument
and returns the value. This method returns a data type object to be determined
after execution.

=cut

=head2 each

  # given {1..8}

  $hash->each(sub{
      my $key   = shift; # 1
      my $value = shift; # 2
  });

The each method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the key and value at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a L<Data::Object::Hash> object.

=cut

=head2 each_key

  # given {1..8}

  $hash->each_key(sub{
      my $key = shift; # 1
  });

The each_key method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the key at the current
position in the loop. This method supports codification, i.e, takes an argument
which can be a codifiable string, a code reference, or a code data type object.
This method returns a L<Data::Object::Hash> object.

=cut

=head2 each_n_values

  # given {1..8}

  $hash->each_n_values(4, sub {
      my $value_1 = shift; # 2
      my $value_2 = shift; # 4
      my $value_3 = shift; # 6
      my $value_4 = shift; # 8
      ...
  });

The each_n_values method iterates over each element in the hash, executing the
code reference supplied in the argument, passing the routine the next n values
until all values have been seen. This method supports codification, i.e, takes
an argument which can be a codifiable string, a code reference, or a code data
type object. This method returns a L<Data::Object::Hash> object.

=cut

=head2 each_value

  # given {1..8}

  $hash->each_value(sub {
      my $value = shift; # 2
  });

The each_value method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the value at the current
position in the loop. This method supports codification, i.e, takes an argument
which can be a codifiable string, a code reference, or a code data type object.
This method returns a L<Data::Object::Hash> object.

=cut

=head2 empty

  # given {1..8}

  $hash->empty; # {}

The empty method drops all elements from the hash. This method returns a
L<Data::Object::Hash> object. Note: This method modifies the hash.

=cut

=head2 eq

  # given $hash

  $hash->eq; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 exists

  # given {1..8,9,undef}

  $hash->exists(1); # 1; true
  $hash->exists(0); # 0; false

The exists method returns true if the value matching the key specified in the
argument exists, otherwise returns false. This method returns a
L<Data::Object::Number> object.

=cut

=head2 filter_exclude

  # given {1..8}

  $hash->filter_exclude(1,3); # {5=>6,7=>8}

The filter_exclude method returns a hash reference consisting of all key/value
pairs in the hash except for the pairs whose keys are specified in the
arguments. This method returns a L<Data::Object::Hash> object.

=cut

=head2 filter_include

  # given {1..8}

  $hash->filter_include(1,3); # {1=>2,3=>4}

The filter_include method returns a hash reference consisting of only key/value
pairs whose keys are specified in the arguments. This method returns a
L<Data::Object::Hash> object.

=cut

=head2 fold

  # given {3,[4,5,6],7,{8,8,9,9}}

  $hash->fold; # {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

The fold method returns a single-level hash reference consisting of key/value
pairs whose keys are paths (using dot-notation where the segments correspond to
nested hash keys and array indices) mapped to the nested values. This method
returns a L<Data::Object::Hash> object.

=cut

=head2 ge

  # given $hash

  $hash->ge; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 get

  # given {1..8}

  $hash->get(5); # 6

The get method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. This method returns a data
type object to be determined after execution.

=cut

=head2 grep

  # given {1..4}

  $hash->grep(sub {
      shift >= 3
  });

  # {3=>5}

The grep method iterates over each key/value pair in the hash, executing the
code reference supplied in the argument, passing the routine the key and value
at the current position in the loop and returning a new hash reference
containing the elements for which the argument evaluated true. This method
supports codification, i.e, takes an argument which can be a codifiable string,
a code reference, or a code data type object. This method returns a
L<Data::Object::Hash> object.

=cut

=head2 gt

  # given $hash

  $hash->gt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 head

  # given $hash

  $hash->head; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 invert

  # given {1..8,9,undef,10,''}

  $hash->invert; # {''=>10,2=>1,4=>3,6=>5,8=>7}

The invert method returns the hash after inverting the keys and values
respectively. Note, keys with undefined values will be dropped, also, this
method modifies the hash. This method returns a L<Data::Object::Hash> object.
Note: This method modifies the hash.

=cut

=head2 iterator

  # given {1..8}

  my $iterator = $hash->iterator;
  while (my $value = $iterator->next) {
      say $value; # 2
  }

The iterator method returns a code reference which can be used to iterate over
the hash. Each time the iterator is executed it will return the values of the
next element in the hash until all elements have been seen, at which point
the iterator will return an undefined value. This method returns a
L<Data::Object::Code> object.

=cut

=head2 join

  # given $hash

  $hash->join; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 keys

  # given {1..8}

  $hash->keys; # [1,3,5,7]

The keys method returns an array reference consisting of all the keys in the
hash. This method returns a L<Data::Object::Array> object.

=cut

=head2 le

  # given $hash

  $hash->le; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 length

  # given {1..8}

  my $length = $hash->length; # 4

The length method returns the number of keys in the hash. This method
return a L<Data::Object::Number> object.

=cut

=head2 list

  # given $hash

  my $list = $hash->list;

The list method returns a shallow copy of the underlying hash reference as an
array reference. This method return a L<Data::Object::Array> object.

=cut

=head2 lookup

  # given {1..3,{4,{5,6,7,{8,9,10,11}}}}

  $hash->lookup('3.4.7'); # {8=>9,10=>11}
  $hash->lookup('3.4'); # {5=>6,7=>{8=>9,10=>11}}
  $hash->lookup(1); # 2

The lookup method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. The key can be a string which
references (using dot-notation) nested keys within the hash. This method will
return undefined if the value is undef or the location expressed in the argument
can not be resolved. Please note, keys containing dots (periods) are not
handled. This method returns a data type object to be determined after
execution.

=cut

=head2 lt

  # given $hash

  $hash->lt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 map

  # given {1..4}

  $hash->map(sub {
      shift + 1
  });

The map method iterates over each key/value in the hash, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new hash reference containing the
elements for which the argument returns a value or non-empty list. This method
returns a L<Data::Object::Hash> object.

=cut

=head2 merge

  # given {1..8}

  $hash->merge({7,7,9,9}); # {1=>2,3=>4,5=>6,7=>7,9=>9}

The merge method returns a hash reference where the elements in the hash and
the elements in the argument(s) are merged. This operation performs a deep
merge and clones the datasets to ensure no side-effects. The merge behavior
merges hash references only, all other data types are assigned with precendence
given to the value being merged. This method returns a L<Data::Object::Hash>
object.

=cut

=head2 ne

  # given $hash

  $hash->ne; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 pairs

  # given {1..8}

  $hash->pairs; # [[1,2],[3,4],[5,6],[7,8]]

The pairs method is an alias to the pairs_array method. This method returns a
L<Data::Object::Array> object. This method is an alias to the pairs_array
method.

=cut

=head2 reset

  # given {1..8}

  $hash->reset; # {1=>undef,3=>undef,5=>undef,7=>undef}

The reset method returns nullifies the value of each element in the hash. This
method returns a L<Data::Object::Hash> object. Note: This method modifies the
hash.

=cut

=head2 reverse

  # given {1..8,9,undef}

  $hash->reverse; # {8=>7,6=>5,4=>3,2=>1}

The reverse method returns a hash reference consisting of the hash's keys and
values inverted. Note, keys with undefined values will be dropped. This method
returns a L<Data::Object::Hash> object.

=cut

=head2 set

  # given {1..8}

  $hash->set(1,10); # 10
  $hash->set(1,12); # 12
  $hash->set(1,0); # 0

The set method returns the value of the element in the hash corresponding to
the key specified by the argument after updating it to the value of the second
argument. This method returns a data type object to be determined after
execution.

=cut

=head2 slice

  # given {1..8}

  my $slice = $hash->slice(1,5); # {1=>2,5=>6}

The slice method returns a hash reference containing the elements in the hash
at the key(s) specified in the arguments. This method returns a
L<Data::Object::Hash> object.

=cut

=head2 sort

  # given $hash

  $hash->sort; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 tail

  # given $hash

  $hash->tail; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=cut

=head2 unfold

  # given {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

  $hash->unfold; # {3=>[4,5,6],7,{8,8,9,9}}

The unfold method processes previously folded hash references and returns an
unfolded hash reference where the keys, which are paths (using dot-notation
where the segments correspond to nested hash keys and array indices), are used
to created nested hash and/or array references. This method returns a
L<Data::Object::Hash> object.

=cut

=head2 values

  # given {1..8}

  $hash->values; # [2,4,6,8]
  $hash->values(1,3); # [2,4]

The values method returns an array reference consisting of the values of the
elements in the hash. This method returns a L<Data::Object::Array> object.

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
