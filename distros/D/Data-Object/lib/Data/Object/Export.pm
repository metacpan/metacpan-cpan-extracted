package Data::Object::Export;

use strict;
use warnings;

use Carp;
use Scalar::Util;

use parent 'Exporter';

our $VERSION = '0.97'; # VERSION

# BUILD

our @CORE = (
  'cast',
  'const',
  'deduce',
  'deduce_deep',
  'deduce_type',
  'detract',
  'detract_deep',
  'dispatch',
  'dump',
  'immutable',
  'load',
  'prototype',
  'throw'
);

our @DATA = (
  'data_any',
  'data_array',
  'data_code',
  'data_data',
  'data_dispatch',
  'data_exception',
  'data_float',
  'data_hash',
  'data_integer',
  'data_number',
  'data_regexp',
  'data_scalar',
  'data_space',
  'data_string',
  'data_undef'
);

our @TYPE = (
  'type_any',
  'type_array',
  'type_code',
  'type_data',
  'type_dispatch',
  'type_exception',
  'type_float',
  'type_hash',
  'type_integer',
  'type_number',
  'type_regexp',
  'type_scalar',
  'type_space',
  'type_string',
  'type_undef'
);

our @PLUS = (
  @Carp::EXPORT,
  'class_file',
  'class_name',
  'class_path',
  'library',
  'namespace',
  'path_class',
  'path_name',
  'registry',
  'reify',
  'typify'
);

our @EXPORT = (
  'do'
);

our @EXPORT_OK = (
  @CORE,
  @DATA,
  @TYPE,
  @PLUS
);

our %EXPORT_TAGS = (
  core => [@CORE],
  data => [@DATA],
  type => [@TYPE],
  all  => [@EXPORT_OK],
  plus => [@PLUS]
);

# PROXY

sub do {
  unless (grep length, grep defined, @_) {
    croak "Null filename used";
  }

  return CORE::do($_[0]) if @_ < 2;

  my $point;

  my $routine = shift;
  my $package = __PACKAGE__;

  # it's fun to do bad things {0_0}
  unless ($package && $routine) {
    croak "Can't make call without a package and function";
  }

  unless ($point = $package->can($routine)) {
    croak "Function ($routine) not callable on package ($package)";
  }

  goto $point;
}

# JUMPERS

sub data_any {
  my $class = 'Data::Object::Any';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_array {
  my $class = 'Data::Object::Array';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_code {
  my $class = 'Data::Object::Code';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_data {
  my $class = 'Data::Object::Data';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_dispatch {
  my $class = 'Data::Object::Dispatch';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_exception {
  my $class = 'Data::Object::Exception';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_float {
  my $class = 'Data::Object::Float';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_hash {
  my $class = 'Data::Object::Hash';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_integer {
  my $class = 'Data::Object::Integer';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_number {
  my $class = 'Data::Object::Number';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_regexp {
  my $class = 'Data::Object::Regexp';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_scalar {
  my $class = 'Data::Object::Scalar';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_space {
  my $class = 'Data::Object::Space';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_string {
  my $class = 'Data::Object::String';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub data_undef {
  my $class = 'Data::Object::Undef';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub immutable {
  my $class = 'Data::Object::Immutable';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub library {
  my $class = 'Data::Object::Library';
  my $point = load($class)->can('meta');

  unshift @_, $class and goto $point;
}

sub prototype {
  my $class = 'Data::Object::Prototype';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub registry {
  my $class = 'Data::Object::Registry';
  my $point = load($class)->can('new');

  unshift @_, $class and goto $point;
}

sub reify {
  my ($from, $expr) = @_;

  my $class = registry()->obj($from);
  my $point = $class->can('lookup');

  @_ = ($class, $expr) and goto $point;
}

sub throw {
  my $class = 'Data::Object::Exception';
  my $point = load($class)->can('throw');

  unshift @_, $class and goto $point;
}

# FUNCTIONS

sub cast {
  goto &deduce_deep;
}

sub const {
  my ($name, $data) = @_;

  my $class = caller(0);
  my $fqsub = $name =~ /(::|')/ ? $name : "${class}::${name}";

  no strict 'refs';
  no warnings 'redefine';

  *{$fqsub} = sub () { (ref $data eq "CODE") ? goto &$data : $data };

  return $data;
}

sub dispatch {
  my ($class, $sub, @args) = @_;

  return if !$class;

  my $package;

  if (!Scalar::Util::blessed($class)) {
    load($class);
    $package = $class;
  } else {
    unshift @args, $class;
    $package = ref $class;
  }

  if (!$sub) {
    return sub {
      my $call = shift;
      my $next = $package->can($call);

      if (!$next && !$call) {
        die "Can't dispatch to $package without routine";
      }
      if (!$next && $call) {
        die "Can't create dispatcher for $call in $package";
      }

      goto $next;
    };
  }

  my $currier = $package->can($sub);

  if (!$currier) {
    die "Can't create dispatcher for $sub in $package";
  }

  return sub { unshift @_, @args if @args; goto $currier };
}

sub dump {
  require Data::Dumper;

  no warnings 'once';

 local $Data::Dumper::Indent = 1;
 local $Data::Dumper::Purity = 1;
 local $Data::Dumper::Quotekeys = 0;
 local $Data::Dumper::Deepcopy = 1;
 local $Data::Dumper::Deparse = 1;
 local $Data::Dumper::Sortkeys = 1;
 local $Data::Dumper::Terse = 0;
 local $Data::Dumper::Useqq = 1;

  return Data::Dumper::Dumper(@_);
}

sub load {
  my ($class) = @_;

  my $failed = !$class || $class !~ /^[\D](?:[\w:']*\w)?$/;
  my $loaded;

  croak "Invalid package name ($class)" if $failed;

  my $error = do {
    local $@;
    $loaded = $class->can('new') || eval "require $class; 1";
    $@;
  };

  croak "Error attempting to load $class: $error"
    if $error
    or $failed
    or not $loaded;

  return $class;
}

sub namespace {
  my ($package, $libname) = @_;

  my $registry = registry();

  my $namespace = path_class($libname);

  $registry->set($package, $namespace);

  return $namespace;
}

# DEDUCERS

sub deduce {
  my ($data) = @_;

  return data_undef($data) if not defined $data;
  return deduce_blessed($data) if Scalar::Util::blessed $data;
  return deduce_defined($data);
}

sub deduce_defined {
  my ($data) = @_;

  return deduce_references($data) if ref $data;
  return deduce_numberlike($data) if Scalar::Util::looks_like_number $data;
  return deduce_stringlike($data);
}

sub deduce_blessed {
  my ($data) = @_;

  return data_regexp($data) if $data->isa('Regexp');
  return $data;
}

sub deduce_references {
  my ($data) = @_;

  return data_array($data) if 'ARRAY' eq ref $data;
  return data_code($data) if 'CODE' eq ref $data;
  return data_hash($data) if 'HASH' eq ref $data;
  return data_scalar($data); # glob, etc
}

sub deduce_numberlike {
  my ($data) = @_;

  return data_float($data) if $data =~ /\./;
  return data_number($data) if $data =~ /^\d[_\d]*$/;
  return data_integer($data);
}

sub deduce_stringlike {
  my ($data) = @_;

  return data_string($data);
}

sub deduce_deep {
  my @data = map deduce($_), @_;

  for my $data (@data) {
    my $type = deduce_type($data);

    if ($type and $type eq 'HASH') {
      for my $i (keys %$data) {
        my $val = $data->{$i};
        $data->{$i} = ref($val) ? deduce_deep($val) : deduce($val);
      }
    }
    if ($type and $type eq 'ARRAY') {
      for (my $i = 0; $i < @$data; $i++) {
        my $val = $data->[$i];
        $data->[$i] = ref($val) ? deduce_deep($val) : deduce($val);
      }
    }
  }

  return wantarray ? (@data) : $data[0];
}

sub deduce_type {
  my ($data) = (deduce $_[0]);

  return "ANY" if $data->isa("Data::Object::Any");
  return "ARRAY" if $data->isa("Data::Object::Array");
  return "HASH" if $data->isa("Data::Object::Hash");
  return "CODE" if $data->isa("Data::Object::Code");
  return "FLOAT" if $data->isa("Data::Object::Float");
  return "NUMBER" if $data->isa("Data::Object::Number");
  return "INTEGER" if $data->isa("Data::Object::Integer");
  return "STRING" if $data->isa("Data::Object::String");
  return "SCALAR" if $data->isa("Data::Object::Scalar");
  return "REGEXP" if $data->isa("Data::Object::Regexp");
  return "UNDEF" if $data->isa("Data::Object::Undef");

  return undef;
}

sub detract {
  my ($data) = (deduce $_[0]);

  my $type = deduce_type $data;

INSPECT:
  return $data unless $type;

  return [@$data] if $type eq 'ARRAY';
  return {%$data} if $type eq 'HASH';
  return $$data if $type eq 'REGEXP';
  return $$data if $type eq 'FLOAT';
  return $$data if $type eq 'NUMBER';
  return $$data if $type eq 'INTEGER';
  return $$data if $type eq 'STRING';
  return undef  if $type eq 'UNDEF';

  if ($type eq 'ANY' or $type eq 'SCALAR') {
    $type = Scalar::Util::reftype($data) // '';

    return [@$data] if $type eq 'ARRAY';
    return {%$data} if $type eq 'HASH';
    return $$data if $type eq 'FLOAT';
    return $$data if $type eq 'INTEGER';
    return $$data if $type eq 'NUMBER';
    return $$data if $type eq 'REGEXP';
    return $$data if $type eq 'SCALAR';
    return $$data if $type eq 'STRING';
    return undef  if $type eq 'UNDEF';

    if ($type eq 'REF') {
      $type = deduce_type($data = $$data) and goto INSPECT;
    }
  }

  if ($type eq 'CODE') {
    return sub { goto $data };
  }

  return undef;
}

sub detract_deep {
  my @data = map detract($_), @_;

  for my $data (@data) {
    if ($data and 'HASH' eq ref $data) {
      for my $i (keys %$data) {
        my $val = $data->{$i};
        $data->{$i} = ref($val) ? detract_deep($val) : detract($val);
      }
    }
    if ($data and 'ARRAY' eq ref $data) {
      for (my $i = 0; $i < @$data; $i++) {
        my $val = $data->[$i];
        $data->[$i] = ref($val) ? detract_deep($val) : detract($val);
      }
    }
  }

  return wantarray ? (@data) : $data[0];
}

# MISCELLANOUS

sub class_file {
  my ($class) = @_;
  $class =~ s/::|'//g;
  $class =~ s/([A-Z])([A-Z]*)/$1 . lc $2/ge;
  return path_name($class);
}

sub class_name {
  my ($string) = @_;
  if ($string =~ /^[A-Z]/) {
    return $string;
  } else {
    my @parts = split '-', $string;
    return join '::', map { join('', map { ucfirst lc } split '_') } @parts;
  }
}

sub class_path {
  my ($class) = @_;
  return join '.', join('/', split(/::|'/, $class)), 'pm';
}

sub path_class {
  my ($path) = @_;
  return join '::', map class_name($_), grep {length} split /\W/, $path;
}

sub path_name {
  my ($string) = @_;
  if ($string !~ /^[A-Z]/) {
    return $string;
  } else {
    my @parts = map {
      join('_', map {lc} grep {length} split /([A-Z]{1}[^A-Z]*)/)
    } split '::', $string;
    return join '-', @parts;
  }
}

# ALIASES

{
  no warnings 'once';

  # aliases
  *any = *data_any;
  *array = *data_array;
  *code = *data_code;
  *data = *data_data;
  *dispatch = *data_dispatch;
  *exception = *data_exception;
  *float = *data_float;
  *hash = *data_hash;
  *integer = *data_integer;
  *number = *data_number;
  *regexp = *data_regexp;
  *scalar = *data_scalar;
  *space = *data_space;
  *string = *data_string;
  *undef = *data_undef;

  # aliases (backwards compatibility)
  *type_any = *data_any;
  *type_array = *data_array;
  *type_code = *data_code;
  *type_data = *data_data;
  *type_dispatch = *data_dispatch;
  *type_exception = *data_exception;
  *type_float = *data_float;
  *type_hash = *data_hash;
  *type_integer = *data_integer;
  *type_number = *data_number;
  *type_regexp = *data_regexp;
  *type_scalar = *data_scalar;
  *type_space = *data_space;
  *type_string = *data_string;
  *type_undef = *data_undef;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Export

=cut

=head1 ABSTRACT

Data-Object Exportable Functions

=cut

=head1 SYNOPSIS

  use Data::Object::Export 'cast';

  my $array = cast []; # Data::Object::Array

=cut

=head1 DESCRIPTION

Data::Object::Export is an exporter that provides various useful utility
functions and function-bundles.

=cut

=head1 EXPORTS

This package can export the following functions.

=cut

=head2 all

  use Data::Object::Export ':all';

The all export tag will export all exportable functions.

=cut

=head2 core

  use Data::Object::Export ':core';

The core export tag will export the exportable functions C<cast>, C<const>,
C<deduce>, C<deduce_deep>, C<deduce_type>, C<detract>, C<detract_deep>,
C<dispatch>, C<dump>, C<immutable>, C<load>, C<prototype>, and C<throw>
exclusively.


=cut

=head2 data

  use Data::Object::Export ':data';

The data export tag will export the exportable functions C<data_any>,
C<data_array>, C<data_code>, C<data_float>, C<data_hash>, C<data_integer>,
C<data_number>, C<data_regexp>, C<data_scalar>, C<data_string>, and
C<data_undef>.

=cut

=head2 plus

  use Data::Object::Export ':plus';

The plus export tag will export the exportable functions C<carp>, C<confess>
C<cluck> C<croak>, C<class_file>, C<class_name>, C<class_path>, C<library>,
C<namespace>, C<path_class>, C<path_name>, C<registry>, and C<reify>.

=cut

=head2 type

  use Data::Object::Export ':type';

The type export tag will export the exportable functions C<type_any>,
C<type_array>, C<type_code>, C<type_float>, C<type_hash>, C<type_integer>,
C<type_number>, C<type_regexp>, C<type_scalar>, C<type_string>, and
C<type_undef>.

=cut

=head2 vars

  use Data::Object::Export ':vars';

The vars export tag will export the exportable variable C<$dispatch>.

=cut

=head1 FUNCTIONS

This package implements the following functions.

=cut

=head2 cast

  cast(Any $arg1) : Any

The cast function returns a Data::Object for the data provided. If the data
passed is blessed then that same object will be returned.

=over 4

=item cast example

  # given [1..4]

  my $array = cast([1..4]); # Data::Object::Array

=back

=cut

=head2 class_file

  class_file(Str $arg1) : Str

The class_file function convertss a class name to a class file.

=over 4

=item class_file example

  # given 'Foo::Bar'

  class_file('Foo::Bar'); # foo_bar

=back

=cut

=head2 class_name

  class_name(Str $arg1) : Str

The class_name function converts a string to a class name.

=over 4

=item class_name example

  # given 'foo-bar'

  class_name('foo-bar'); # Foo::Bar

=back

=cut

=head2 class_path

  class_path(Str $arg1) : Str

The class_path function converts a class name to a class file.

=over 4

=item class_path example

  # given 'Foo::BarBaz'

  class_path('Foo::BarBaz'); 'Foo/BarBaz.pm'

=back

=cut

=head2 const

  const(Str $arg1, Any $arg2) : CodeRef

The const function creates a constant function using the name and expression
supplied to it. A constant function is a function that does not accept any
arguments and whose result(s) are deterministic.

=over 4

=item const example

  # given 1.098765;

  const VERSION => 1.098765;

=back

=cut

=head2 data_any

  data_any(Any $arg1) : Object

The data_any function returns a L<Data::Object::Any> instance which
wraps the provided data type and can be used to perform operations on the data.
The C<type_any> function is an alias to this function.

=over 4

=item data_any example

  # given 0;

  $object = data_any 0;
  $object->isa('Data::Object::Any');

=back

=cut

=head2 data_array

  data_array(ArrayRef $arg1) : ArrayObject

The data_array function returns a Data::Object::Array instance which wraps the
provided data type and can be used to perform operations on the data. The
type_array function is an alias to this function.

=over 4

=item data_array example

  # given [2..5];

  $data = data_array [2..5];
  $data->isa('Data::Object::Array');

=back

=cut

=head2 data_code

  data_code(CodeRef $arg1) : CodeObject

The data_code function returns a L<Data::Object::Code> instance which wraps the
provided data type and can be used to perform operations on the data. The
C<type_code> function is an alias to this function.

=over 4

=item data_code example

  # given sub { 1 };

  $object = data_code sub { 1 };
  $object->isa('Data::Object::Code');

=back

=cut

=head2 data_data

  data_data(Str $arg1) : Object

The data_data function returns a L<Data::Object::Data> instance which parses
pod-ish data in files and packages.

=over 4

=item data_data example

  # given Foo::Bar;

  $object = data_data 'Foo::Bar';
  $object->isa('Data::Object::Data');

=back

=cut

=head2 data_dispatch

  data_dispatch(Str $arg1) : Object

The data_dispatch function returns a L<Data::Object::Dispatch> instance which
extends L<Data::Object::Code> and dispatches to routines in the given package.

=over 4

=item data_dispatch example

  # given Foo::Bar;

  $object = data_dispatch 'Foo::Bar';
  $object->isa('Data::Object::Dispatch');

=back

=cut

=head2 data_exception

  data_exception(Any @args) : Object

The data_exception function returns a L<Data::Object::Exception> instance which can
be thrown.

=over 4

=item data_exception example

  # given {,...};

  $object = data_exception {,...};
  $object->isa('Data::Object::Exception');

=back

=cut

=head2 data_float

  data_float(Str $arg1) : FloatObject

The data_float function returns a L<Data::Object::Float> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_float> function is an alias to this function.

=over 4

=item data_float example

  # given 5.25;

  $object = data_float 5.25;
  $object->isa('Data::Object::Float');

=back

=cut

=head2 data_hash

  data_hash(HashRef $arg1) : HashObject

The data_hash function returns a L<Data::Object::Hash> instance which wraps the
provided data type and can be used to perform operations on the data. The
C<type_hash> function is an alias to this function.

=over 4

=item data_hash example

  # given {1..4};

  $object = data_hash {1..4};
  $object->isa('Data::Object::Hash');

=back

=cut

=head2 data_integer

  data_integer(Int $arg1) : IntObject

The data_integer function returns a L<Data::Object::Object> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_integer> function is an alias to this function.

=over 4

=item data_integer example

  # given -100;

  $object = data_integer -100;
  $object->isa('Data::Object::Integer');

=back

=cut

=head2 data_number

  data_number(Num $arg1) : NumObject

The data_number function returns a L<Data::Object::Number> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_number> function is an alias to this function.

=over 4

=item data_number example

  # given 100;

  $object = data_number 100;
  $object->isa('Data::Object::Number');

=back

=cut

=head2 data_regexp

  data_regexp(RegexpRef $arg1) : RegexpObject

The data_regexp function returns a L<Data::Object::Regexp> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_regexp> function is an alias to this function.

=over 4

=item data_regexp example

  # given qr/test/;

  $object = data_regexp qr/test/;
  $object->isa('Data::Object::Regexp');

=back

=cut

=head2 data_scalar

  data_scalar(Any $arg1) : ScalarObject

The data_scalar function returns a L<Data::Object::Scalar> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_scalar> function is an alias to this function.

=over 4

=item data_scalar example

  # given \*main;

  $object = data_scalar \*main;
  $object->isa('Data::Object::Scalar');

=back

=cut

=head2 data_space

  data_space(Str $arg1) : Object

The data_space function returns a L<Data::Object::Space> instance which
provides methods for operating on package and namespaces.

=over 4

=item data_space example

  # given Foo::Bar;

  $object = data_space 'Foo::Bar';
  $object->isa('Data::Object::Space');

=back

=cut

=head2 data_string

  data_string(Str $arg1) : StrObject

The data_string function returns a L<Data::Object::String> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_string> function is an alias to this function.

=over 4

=item data_string example

  # given 'abcdefghi';

  $object = data_string 'abcdefghi';
  $object->isa('Data::Object::String');

=back

=cut

=head2 data_undef

  data_undef(Undef $arg1) : UndefObject

The data_undef function returns a L<Data::Object::Undef> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_undef> function is an alias to this function.

=over 4

=item data_undef example

  # given undef;

  $object = data_undef undef;
  $object->isa('Data::Object::Undef');

=back

=cut

=head2 deduce

  deduce(Any $arg1) : Any

The deduce function returns a data type object instance based upon the deduced
type of data provided.

=over 4

=item deduce example

  # given qr/\w+/;

  $object = deduce qr/\w+/;
  $object->isa('Data::Object::Regexp');

=back

=cut

=head2 deduce_blessed

  deduce_blessed(Any $arg1) : Int

The deduce_blessed function returns truthy if the argument is blessed.

=over 4

=item deduce_blessed example

  # given $data

  deduce_blessed($data);

=back

=cut

=head2 deduce_deep

  deduce_deep(Any $arg1) : Any

The deduce_deep function returns a data type object. If the data provided is
complex, this function traverses the data converting all nested data to objects.
Note: Blessed objects are not traversed.

=over 4

=item deduce_deep example

  # given {1,2,3,{4,5,6,[-1]}}

  $deep = deduce_deep {1,2,3,{4,5,6,[-1]}};

  # Data::Object::Hash {
  #   1 => Data::Object::Number ( 2 ),
  #   3 => Data::Object::Hash {
  #      4 => Data::Object::Number ( 5 ),
  #      6 => Data::Object::Array [ Data::Object::Integer ( -1 ) ],
  #   },
  # }

=back

=cut

=head2 deduce_defined

  deduce_defined(Any $arg1) : Int

The deduce_defined function returns truthy if the argument is defined.

=over 4

=item deduce_defined example

  # given $data

  deduce_defined($data);

=back

=cut

=head2 deduce_numberlike

  deduce_numberlike(Any $arg1) : Int

The deduce_numberlike function returns truthy if the argument is numberlike.

=over 4

=item deduce_numberlike example

  # given $data

  deduce_numberlike($data);

=back

=cut

=head2 deduce_references

  deduce_references(Any $arg1) : Int

The deduce_references function returns a Data::Object object based on the type
of argument reference provided.

=over 4

=item deduce_references example

  # given $data

  deduce_references($data);

=back

=cut

=head2 deduce_stringlike

  deduce_stringlike(Any $arg1) : Int

The deduce_stringlike function returns truthy if the argument is stringlike.

=over 4

=item deduce_stringlike example

  # given $data

  deduce_stringlike($data);

=back

=cut

=head2 deduce_type

  deduce_type(Any $arg1) : Str

The deduce_type function returns a data type description for the type of data
provided, represented as a string in capital letters.

=over 4

=item deduce_type example

  # given qr/\w+/;

  $type = deduce_type qr/\w+/; # REGEXP

=back

=cut

=head2 detract

  detract(Any $arg1) : Any

The detract function returns a value of native type, based upon the underlying
reference of the data type object provided.

=over 4

=item detract example

  # given bless({1..4}, 'Data::Object::Hash');

  $object = detract $object; # {1..4}

=back

=cut

=head2 detract_deep

  detract_deep(Any $arg1) : Any

The detract_deep function returns a value of native type. If the data provided
is complex, this function traverses the data converting all nested data type
objects into native values using the objects underlying reference. Note:
Blessed objects are not traversed.

=over 4

=item detract_deep example

  # given {1,2,3,{4,5,6,[-1, 99, bless({}), sub { 123 }]}};

  my $object = deduce_deep $object;
  my $revert = detract_deep $object; # produces ...

  # {
  #   '1' => 2,
  #   '3' => {
  #     '4' => 5,
  #     '6' => [ -1, 99, bless({}, 'main'), sub { ... } ]
  #     }
  # }

=back

=cut

=head2 dispatch

  dispatch(Str $arg1) : Object

The dispatch function return a Data::Object::Dispatch object which is a handle
that let's you call into other packages.

=over 4

=item dispatch example

  my $dispatch = dispatch('main');

  # $dispatch->('run') calls main::run

=back

=cut

=head2 do

  do(Str $arg1, Any @args) : Any

The do function is a special constructor function that is automatically
exported into the consuming package. It overloads and extends the core C<do>
function, supporting the core functionality and adding a new feature, and
exists to dispatch to exportable Data-Object functions and other dispatchers.

=over 4

=item do example

  # given file syntax

  do 'file.pl'

  # given block syntax

  do { @{"${class}::ISA"} }

  # given func-args syntax

  do('any', [1..4]); # Data::Object::Any

=back

=cut

=head2 dump

  dump(Any $arg1) : Str

The dump function returns a string representation of the data passed.

=over 4

=item dump example

  # given {1..8}

  say dump {1..8};

=back

=cut

=head2 immutable

  immutable(Any $arg1) : Any

The immutable function makes the data type object provided immutable. This
function loads L<Data::Object::Immutable> and returns the object provided as an
argument.

=over 4

=item immutable example

  # given [1,2,3];

  $object = immutable data_array [1,2,3];
  $object->isa('Data::Object::Array); # via Data::Object::Immutable

=back

=cut

=head2 library

  library() : Object

The library function returns the default L<Type::Library> object where all core
type constraints are registered.

=over 4

=item library example

  library; # Type::Library

=back

=cut

=head2 load

  load(Str $arg1) : ClassName

The load function attempts to dynamically load a module and either dies or
returns the package name of the loaded module.

=over 4

=item load example

  # given 'List::Util';

  $package = load 'List::Util'; # List::Util if loaded

=back

=cut

=head2 namespace

  namespace(ClassName $arg1, ClassName $arg2) : Str

The namespace function registers a type library with a namespace in the
registry so that typed operations know where to look for type context-specific
constraints.

=over 4

=item namespace example

  # given Types::Standard

  namespace('App', 'Types::Standard');

=back

=cut

=head2 path_class

  path_class(Str $arg1) : Str

The path_class function converts a path to a class name.

=over 4

=item path_class example

  # given 'foo/bar_baz'

  path_class('foo/bar_baz'); # Foo::BarBaz

=back

=cut

=head2 path_name

  path_name(Str $arg1) : Str

The path_name function converts a class name to a path.

=over 4

=item path_name example

  # given 'Foo::BarBaz'

  path_name('Foo::BarBaz'); # foo-bar_baz

=back

=cut

=head2 prototype

  prototype(Any @args) : Object

The prototype function returns a prototype object which can be used to
generate classes, objects, and derivatives. This function loads
L<Data::Object::Prototype> and returns an object based on the arguments
provided.

=over 4

=item prototype example

  # given ('$name' => [is => 'ro']);

  my $proto  = data_prototype '$name' => [is => 'ro'];
  my $class  = $proto->create; # via Data::Object::Prototype
  my $object = $class->new(name => '...');

=back

=cut

=head2 registry

  registry() : Object

The registry function returns the registry singleton object where mapping
between namespaces and type libraries are registered.

=over 4

=item registry example

  registry; # Data::Object::Registry

=back

=cut

=head2 reify

  reify(Str $arg1) : Object

The reify function will construct a L<Type::Tiny> type constraint object for
the type expression provided.

=over 4

=item reify example

  # given 'Str';

  $type = reify 'Str'; # Type::Tiny

=back

=cut

=head2 throw

  throw(Any @args) : Object

The throw function will dynamically load and throw an exception object. This
function takes all arguments accepted by the L<Data::Object::Exception> class.

=over 4

=item throw example

  # given $message;

  throw $message; # An exception (...) was thrown in -e at line 1

=back

=cut
