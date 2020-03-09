use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::Types

=cut

=abstract

Data-Object Type Constraints

=cut

=synopsis

  package main;

  use Data::Object::Types;

  1;

=cut

=description

This package provides type constraints for L<Data::Object>.

=cut

=type ArgsObj

  ArgsObj

=type-library ArgsObj

Data::Object::Types

=type-composite ArgsObj

  InstanceOf["Data::Object::Args"]

=type-parent ArgsObj

  Object

=type-example-1 ArgsObj

  # package ArgsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Args';

  package main;

  bless {}, 'ArgsExample';

=cut

=type ArgsObject

  ArgsObject

=type-library ArgsObject

Data::Object::Types

=type-composite ArgsObject

  InstanceOf["Data::Object::Args"]

=type-parent ArgsObject

  Object

=type-example-1 ArgsObject

  # package ArgsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Args';

  package main;

  bless {}, 'ArgsExample';

=cut

=type ArrayObj

  ArrayObj

=type-library ArrayObj

Data::Object::Types

=type-composite ArrayObj

  InstanceOf["Data::Object::Array"]

=type-parent ArrayObj

  Object

=type-coercion-1 ArrayObj

  # coerce from ArrayRef

  []

=type-example-1 ArrayObj

  # package ArrayExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Array';

  package main;

  bless [], 'ArrayExample';

=cut

=type ArrayObject

  ArrayObject

=type-library ArrayObject

Data::Object::Types

=type-composite ArrayObject

  InstanceOf["Data::Object::Array"]

=type-parent ArrayObject

  Object

=type-coercion-1 ArrayObject

  # coerce from ArrayRef

  []

=type-example-1 ArrayObject

  # package ArrayExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Array';

  package main;

  bless [], 'ArrayExample';

=cut

=type BoolObj

  BoolObj

=type-library BoolObj

Data::Object::Types

=type-composite BoolObj

  InstanceOf["Data::Object::Boolean"]

=type-parent BoolObj

  Object

=type-example-1 BoolObj

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=cut

=type BoolObject

  BoolObject

=type-library BoolObject

Data::Object::Types

=type-composite BoolObject

  InstanceOf["Data::Object::Boolean"]

=type-parent BoolObject

  Object

=type-example-1 BoolObject

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=cut

=type BooleanObj

  BooleanObj

=type-library BooleanObj

Data::Object::Types

=type-composite BooleanObj

  InstanceOf["Data::Object::Boolean"]

=type-parent BooleanObj

  Object

=type-example-1 BooleanObj

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=cut

=type BooleanObject

  BooleanObject

=type-library BooleanObject

Data::Object::Types

=type-composite BooleanObject

  InstanceOf["Data::Object::Boolean"]

=type-parent BooleanObject

  Object

=type-example-1 BooleanObject

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=cut

=type CliObj

  CliObj

=type-library CliObj

Data::Object::Types

=type-composite CliObj

  InstanceOf["Data::Object::Cli"]

=type-parent CliObj

  Object

=type-example-1 CliObj

  # package CliExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Cli';

  package main;

  bless {}, 'CliExample';

=cut

=type CliObject

  CliObject

=type-library CliObject

Data::Object::Types

=type-composite CliObject

  InstanceOf["Data::Object::Cli"]

=type-parent CliObject

  Object

=type-example-1 CliObject

  # package CliExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Cli';

  package main;

  bless {}, 'CliExample';

=cut

=type CodeObj

  CodeObj

=type-library CodeObj

Data::Object::Types

=type-composite CodeObj

  InstanceOf["Data::Object::Code"]

=type-parent CodeObj

  Object

=type-coercion-1 CodeObj

  # coerce from CodeRef

  sub{}

=type-example-1 CodeObj

  # package CodeExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Code';

  package main;

  bless sub{}, 'CodeExample';

=cut

=type CodeObject

  CodeObject

=type-library CodeObject

Data::Object::Types

=type-composite CodeObject

  InstanceOf["Data::Object::Code"]

=type-parent CodeObject

  Object

=type-coercion-1 CodeObject

  # coerce from CodeRef

  sub{}

=type-example-1 CodeObject

  # package CodeExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Code';

  package main;

  bless sub{}, 'CodeExample';

=cut

=type DataObj

  DataObj

=type-library DataObj

Data::Object::Types

=type-composite DataObj

  InstanceOf["Data::Object::Data"]

=type-parent DataObj

  Object

=type-example-1 DataObj

  # package DataExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Data';

  package main;

  bless {}, 'DataExample';

=cut

=type DataObject

  DataObject

=type-library DataObject

Data::Object::Types

=type-composite DataObject

  InstanceOf["Data::Object::Data"]

=type-parent DataObject

  Object

=type-example-1 DataObject

  # package DataExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Data';

  package main;

  bless {}, 'DataExample';

=cut

=type DoArgs

  DoArgs

=type-library DoArgs

Data::Object::Types

=type-composite DoArgs

  InstanceOf["Data::Object::Args"]

=type-parent DoArgs

  Object

=type-example-1 DoArgs

  # package ArgsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Args';

  package main;

  bless {}, 'ArgsExample';

=cut

=type DoArray

  DoArray

=type-library DoArray

Data::Object::Types

=type-composite DoArray

  InstanceOf["Data::Object::Array"]

=type-parent DoArray

  Object

=type-coercion-1 DoArray

  # coerce from ArrayRef

  []

=type-example-1 DoArray

  # package ArrayExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Array';

  package main;

  bless [], 'ArrayExample';

=cut

=type DoBoolean

  DoBoolean

=type-library DoBoolean

Data::Object::Types

=type-composite DoBoolean

  InstanceOf["Data::Object::Boolean"]

=type-parent DoBoolean

  Object

=type-example-1 DoBoolean

  # package BooleanExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Boolean';

  package main;

  my $bool = 1;

  bless \$bool, 'BooleanExample';

=cut

=type DoCli

  DoCli

=type-library DoCli

Data::Object::Types

=type-composite DoCli

  InstanceOf["Data::Object::Cli"]

=type-parent DoCli

  Object

=type-example-1 DoCli

  # package CliExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Cli';

  package main;

  bless {}, 'CliExample';

=cut

=type DoCode

  DoCode

=type-library DoCode

Data::Object::Types

=type-composite DoCode

  InstanceOf["Data::Object::Code"]

=type-parent DoCode

  Object

=type-coercion-1 DoCode

  # coerce from CodeRef

  sub{}

=type-example-1 DoCode

  # package CodeExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Code';

  package main;

  bless sub{}, 'CodeExample';

=cut

=type DoData

  DoData

=type-library DoData

Data::Object::Types

=type-composite DoData

  InstanceOf["Data::Object::Data"]

=type-parent DoData

  Object

=type-example-1 DoData

  # package DataExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Data';

  package main;

  bless {}, 'DataExample';

=cut

=type DoDumpable

  DoDumpable

=type-library DoDumpable

Data::Object::Types

=type-composite DoDumpable

  ConsumerOf["Data::Object::Role::Dumpable"]

=type-parent DoDumpable

  Object

=type-example-1 DoDumpable

  # package DumpableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Dumpable';

  package main;

  bless {}, 'DumpableExample';

=cut

=type DoException

  DoException

=type-library DoException

Data::Object::Types

=type-composite DoException

  InstanceOf["Data::Object::Exception"]

=type-parent DoException

  Object

=type-example-1 DoException

  # package ExceptionExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Exception';

  package main;

  bless {}, 'ExceptionExample';

=cut

=type DoFloat

  DoFloat

=type-library DoFloat

Data::Object::Types

=type-composite DoFloat

  InstanceOf["Data::Object::Float"]

=type-parent DoFloat

  Object

=type-coercion-1 DoFloat

  # coerce from LaxNum

  123

=type-coercion-2 DoFloat

  # coerce from Str

  '123'

=type-coercion-3 DoFloat

  # coerce from Num

  123

=type-example-1 DoFloat

  # package FloatExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Float';

  package main;

  my $float = 1.23;

  bless \$float, 'FloatExample';

=cut

=type DoFunc

  DoFunc

=type-library DoFunc

Data::Object::Types

=type-composite DoFunc

  InstanceOf["Data::Object::Func"]

=type-parent DoFunc

  Object

=type-example-1 DoFunc

  # package FuncExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Func';

  package main;

  bless {}, 'FuncExample';

=cut

=type DoHash

  DoHash

=type-library DoHash

Data::Object::Types

=type-composite DoHash

  InstanceOf["Data::Object::Hash"]

=type-parent DoHash

  Object

=type-coercion-1 DoHash

  # coerce from HashRef

  {}

=type-example-1 DoHash

  # package HashExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Hash';

  package main;

  bless {}, 'HashExample';

=cut

=type DoImmutable

  DoImmutable

=type-library DoImmutable

Data::Object::Types

=type-composite DoImmutable

  ConsumerOf["Data::Object::Role::Immutable"]

=type-parent DoImmutable

  Object

=type-example-1 DoImmutable

  # package ImmutableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Immutable';

  package main;

  bless {}, 'ImmutableExample';

=cut

=type DoNum

  DoNum

=type-library DoNum

Data::Object::Types

=type-composite DoNum

  InstanceOf["Data::Object::Number"]

=type-parent DoNum

  Object

=type-coercion-1 DoNum

  # coerce from LaxNum

  123

=type-coercion-2 DoNum

  # coerce from Str

  '123'

=type-coercion-3 DoNum

  # coerce from Num

  123

=type-coercion-4 DoNum

  # coerce from StrictNum

  123

=type-coercion-5 DoNum

  # coerce from Int

  99999

=type-example-1 DoNum

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=cut

=type DoOpts

  DoOpts

=type-library DoOpts

Data::Object::Types

=type-composite DoOpts

  InstanceOf["Data::Object::Opts"]

=type-parent DoOpts

  Object

=type-example-1 DoOpts

  # package OptsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Opts';

  package main;

  bless {}, 'OptsExample';

=cut

=type DoRegexp

  DoRegexp

=type-library DoRegexp

Data::Object::Types

=type-composite DoRegexp

  InstanceOf["Data::Object::Regexp"]

=type-parent DoRegexp

  Object

=type-coercion-1 DoRegexp

  # coerce from RegexpRef

  qr//

=type-example-1 DoRegexp

  # package RegexpExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Regexp';

  package main;

  bless {}, 'RegexpExample';

=cut

=type DoReplace

  DoReplace

=type-library DoReplace

Data::Object::Types

=type-composite DoReplace

  InstanceOf["Data::Object::Replace"]

=type-parent DoReplace

  Object

=type-example-1 DoReplace

  # package ReplaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Replace';

  package main;

  bless {}, 'ReplaceExample';

=cut

=type DoScalar

  DoScalar

=type-library DoScalar

Data::Object::Types

=type-composite DoScalar

  InstanceOf["Data::Object::Scalar"]

=type-parent DoScalar

  Object

=type-coercion-1 DoScalar

  # coerce from ScalarRef

  do { my $i = 0; \$i }

=type-example-1 DoScalar

  # package ScalarExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Scalar';

  package main;

  my $scalar = 'abc';

  bless \$scalar, 'ScalarExample';

=cut

=type DoSearch

  DoSearch

=type-library DoSearch

Data::Object::Types

=type-composite DoSearch

  InstanceOf["Data::Object::Search"]

=type-parent DoSearch

  Object

=type-example-1 DoSearch

  # package SearchExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Search';

  package main;

  bless {}, 'SearchExample';

=cut

=type DoSpace

  DoSpace

=type-library DoSpace

Data::Object::Types

=type-composite DoSpace

  InstanceOf["Data::Object::Space"]

=type-parent DoSpace

  Object

=type-coercion-1 DoSpace

  # coerce from Str

  'abc'

=type-example-1 DoSpace

  # package SpaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Space';

  package main;

  bless {}, 'SpaceExample';

=cut

=type DoStashable

  DoStashable

=type-library DoStashable

Data::Object::Types

=type-composite DoStashable

  ConsumerOf["Data::Object::Role::Stashable"]

=type-parent DoStashable

  Object

=type-example-1 DoStashable

  # package StashableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Stashable';

  package main;

  bless {}, 'StashableExample';

=cut

=type DoState

  DoState

=type-library DoState

Data::Object::Types

=type-composite DoState

  InstanceOf["Data::Object::State"]

=type-parent DoState

  Object

=type-example-1 DoState

  # package StateExample;

  # use Data::Object::Class;

  # extends 'Data::Object::State';

  package main;

  bless {}, 'StateExample';

=cut

=type DoStr

  DoStr

=type-library DoStr

Data::Object::Types

=type-composite DoStr

  InstanceOf["Data::Object::String"]

=type-parent DoStr

  Object

=type-coercion-1 DoStr

  # coerce from Str

  'abc'

=type-example-1 DoStr

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=cut

=type DoStruct

  DoStruct

=type-library DoStruct

Data::Object::Types

=type-composite DoStruct

  InstanceOf["Data::Object::Struct"]

=type-parent DoStruct

  Object

=type-example-1 DoStruct

  # package StructExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Struct';

  package main;

  bless {}, 'StructExample';

=cut

=type DoThrowable

  DoThrowable

=type-library DoThrowable

Data::Object::Types

=type-composite DoThrowable

  ConsumerOf["Data::Object::Role::Throwable"]

=type-parent DoThrowable

  Object

=type-example-1 DoThrowable

  # package ThrowableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Throwable';

  package main;

  bless {}, 'ThrowableExample';

=cut

=type DoUndef

  DoUndef

=type-library DoUndef

Data::Object::Types

=type-composite DoUndef

  InstanceOf["Data::Object::Undef"]

=type-parent DoUndef

  Object

=type-coercion-1 DoUndef

  # coerce from Undef

  undef

=type-example-1 DoUndef

  # package UndefExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Undef';

  my $undef = undef;

  bless \$undef, 'UndefExample';

=cut

=type DoVars

  DoVars

=type-library DoVars

Data::Object::Types

=type-composite DoVars

  InstanceOf["Data::Object::Vars"]

=type-parent DoVars

  Object

=type-example-1 DoVars

  # package VarsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Vars';

  package main;

  bless {}, 'VarsExample';

=cut

=type Dumpable

  Dumpable

=type-library Dumpable

Data::Object::Types

=type-composite Dumpable

  ConsumerOf["Data::Object::Role::Dumpable"]

=type-parent Dumpable

  Object

=type-example-1 Dumpable

  # package DumpableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Dumpable';

  package main;

  bless {}, 'DumpableExample';

=cut

=type ExceptionObj

  ExceptionObj

=type-library ExceptionObj

Data::Object::Types

=type-composite ExceptionObj

  InstanceOf["Data::Object::Exception"]

=type-parent ExceptionObj

  Object

=type-example-1 ExceptionObj

  # package ExceptionExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Exception';

  package main;

  bless {}, 'ExceptionExample';

=cut

=type ExceptionObject

  ExceptionObject

=type-library ExceptionObject

Data::Object::Types

=type-composite ExceptionObject

  InstanceOf["Data::Object::Exception"]

=type-parent ExceptionObject

  Object

=type-example-1 ExceptionObject

  # package ExceptionExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Exception';

  package main;

  bless {}, 'ExceptionExample';

=cut

=type FloatObj

  FloatObj

=type-library FloatObj

Data::Object::Types

=type-composite FloatObj

  InstanceOf["Data::Object::Float"]

=type-parent FloatObj

  Object

=type-coercion-1 FloatObj

  # coerce from Num

  123

=type-coercion-2 FloatObj

  # coerce from LaxNum

  123

=type-coercion-3 FloatObj

  # coerce from Str

  '1.23'

=type-example-1 FloatObj

  # package FloatExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Float';

  package main;

  my $float = 1.23;

  bless \$float, 'FloatExample';

=cut

=type FloatObject

  FloatObject

=type-library FloatObject

Data::Object::Types

=type-composite FloatObject

  InstanceOf["Data::Object::Float"]

=type-parent FloatObject

  Object

=type-coercion-1 FloatObject

  # coerce from Num

  123

=type-coercion-2 FloatObject

  # coerce from LaxNum

  123

=type-coercion-3 FloatObject

  # coerce from Str

  '1.23'

=type-example-1 FloatObject

  # package FloatExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Float';

  package main;

  my $float = 1.23;

  bless \$float, 'FloatExample';

=cut

=type FuncObj

  FuncObj

=type-library FuncObj

Data::Object::Types

=type-composite FuncObj

  InstanceOf["Data::Object::Func"]

=type-parent FuncObj

  Object

=type-example-1 FuncObj

  # package FuncExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Func';

  package main;

  bless {}, 'FuncExample';

=cut

=type FuncObject

  FuncObject

=type-library FuncObject

Data::Object::Types

=type-composite FuncObject

  InstanceOf["Data::Object::Func"]

=type-parent FuncObject

  Object

=type-example-1 FuncObject

  # package FuncExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Func';

  package main;

  bless {}, 'FuncExample';

=cut

=type HashObj

  HashObj

=type-library HashObj

Data::Object::Types

=type-composite HashObj

  InstanceOf["Data::Object::Hash"]

=type-parent HashObj

  Object

=type-coercion-1 HashObj

  # coerce from HashRef

  {}

=type-example-1 HashObj

  # package HashExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Hash';

  package main;

  bless {}, 'HashExample';

=cut

=type HashObject

  HashObject

=type-library HashObject

Data::Object::Types

=type-composite HashObject

  InstanceOf["Data::Object::Hash"]

=type-parent HashObject

  Object

=type-coercion-1 HashObject

  # coerce from HashRef

  {}

=type-example-1 HashObject

  # package HashExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Hash';

  package main;

  bless {}, 'HashExample';

=cut

=type Immutable

  Immutable

=type-library Immutable

Data::Object::Types

=type-composite Immutable

  ConsumerOf["Data::Object::Role::Immutable"]

=type-parent Immutable

  Object

=type-example-1 Immutable

  # package ImmutableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Immutable';

  package main;

  bless {}, 'ImmutableExample';

=cut

=type NumObj

  NumObj

=type-library NumObj

Data::Object::Types

=type-composite NumObj

  InstanceOf["Data::Object::Number"]

=type-parent NumObj

  Object

=type-coercion-1 NumObj

  # coerce from LaxNum

  123

=type-coercion-2 NumObj

  # coerce from Str

  '123'

=type-coercion-3 NumObj

  # coerce from Int

  99999

=type-coercion-4 NumObj

  # coerce from Num

  123

=type-coercion-5 NumObj

  # coerce from StrictNum

  123

=type-example-1 NumObj

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=cut

=type NumObject

  NumObject

=type-library NumObject

Data::Object::Types

=type-composite NumObject

  InstanceOf["Data::Object::Number"]

=type-parent NumObject

  Object

=type-coercion-1 NumObject

  # coerce from Num

  123

=type-coercion-2 NumObject

  # coerce from StrictNum

  123

=type-coercion-3 NumObject

  # coerce from Int

  99999

=type-coercion-4 NumObject

  # coerce from LaxNum

  123

=type-coercion-5 NumObject

  # coerce from Str

  '123'

=type-example-1 NumObject

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=cut

=type NumberObj

  NumberObj

=type-library NumberObj

Data::Object::Types

=type-composite NumberObj

  InstanceOf["Data::Object::Number"]

=type-parent NumberObj

  Object

=type-coercion-1 NumberObj

  # coerce from Int

  99999

=type-coercion-2 NumberObj

  # coerce from StrictNum

  123

=type-coercion-3 NumberObj

  # coerce from Num

  123

=type-coercion-4 NumberObj

  # coerce from Str

  '123'

=type-coercion-5 NumberObj

  # coerce from LaxNum

  123

=type-example-1 NumberObj

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=cut

=type NumberObject

  NumberObject

=type-library NumberObject

Data::Object::Types

=type-composite NumberObject

  InstanceOf["Data::Object::Number"]

=type-parent NumberObject

  Object

=type-coercion-1 NumberObject

  # coerce from Int

  99999

=type-coercion-2 NumberObject

  # coerce from StrictNum

  123

=type-coercion-3 NumberObject

  # coerce from Num

  123

=type-coercion-4 NumberObject

  # coerce from Str

  '123'

=type-coercion-5 NumberObject

  # coerce from LaxNum

  123

=type-example-1 NumberObject

  # package NumberExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Number';

  package main;

  my $num = 123;

  bless \$num, 'NumberExample';

=cut

=type OptsObj

  OptsObj

=type-library OptsObj

Data::Object::Types

=type-composite OptsObj

  InstanceOf["Data::Object::Opts"]

=type-parent OptsObj

  Object

=type-example-1 OptsObj

  # package OptsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Opts';

  package main;

  bless {}, 'OptsExample';

=cut

=type OptsObject

  OptsObject

=type-library OptsObject

Data::Object::Types

=type-composite OptsObject

  InstanceOf["Data::Object::Opts"]

=type-parent OptsObject

  Object

=type-example-1 OptsObject

  # package OptsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Opts';

  package main;

  bless {}, 'OptsExample';

=cut

=type RegexpObj

  RegexpObj

=type-library RegexpObj

Data::Object::Types

=type-composite RegexpObj

  InstanceOf["Data::Object::Regexp"]

=type-parent RegexpObj

  Object

=type-coercion-1 RegexpObj

  # coerce from RegexpRef

  qr//

=type-example-1 RegexpObj

  # package RegexpExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Regexp';

  package main;

  bless {}, 'RegexpExample';

=cut

=type RegexpObject

  RegexpObject

=type-library RegexpObject

Data::Object::Types

=type-composite RegexpObject

  InstanceOf["Data::Object::Regexp"]

=type-parent RegexpObject

  Object

=type-coercion-1 RegexpObject

  # coerce from RegexpRef

  qr//

=type-example-1 RegexpObject

  # package RegexpExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Regexp';

  package main;

  bless {}, 'RegexpExample';

=cut

=type ReplaceObj

  ReplaceObj

=type-library ReplaceObj

Data::Object::Types

=type-composite ReplaceObj

  InstanceOf["Data::Object::Replace"]

=type-parent ReplaceObj

  Object

=type-example-1 ReplaceObj

  # package ReplaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Replace';

  package main;

  bless {}, 'ReplaceExample';

=cut

=type ReplaceObject

  ReplaceObject

=type-library ReplaceObject

Data::Object::Types

=type-composite ReplaceObject

  InstanceOf["Data::Object::Replace"]

=type-parent ReplaceObject

  Object

=type-example-1 ReplaceObject

  # package ReplaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Replace';

  package main;

  bless {}, 'ReplaceExample';

=cut

=type ScalarObj

  ScalarObj

=type-library ScalarObj

Data::Object::Types

=type-composite ScalarObj

  InstanceOf["Data::Object::Scalar"]

=type-parent ScalarObj

  Object

=type-coercion-1 ScalarObj

  # coerce from ScalarRef

  do { my $i = 0; \$i }

=type-example-1 ScalarObj

  # package ScalarExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Scalar';

  package main;

  my $scalar = 'abc';

  bless \$scalar, 'ScalarExample';

=cut

=type ScalarObject

  ScalarObject

=type-library ScalarObject

Data::Object::Types

=type-composite ScalarObject

  InstanceOf["Data::Object::Scalar"]

=type-parent ScalarObject

  Object

=type-coercion-1 ScalarObject

  # coerce from ScalarRef

  do { my $i = 0; \$i }

=type-example-1 ScalarObject

  # package ScalarExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Scalar';

  package main;

  my $scalar = 'abc';

  bless \$scalar, 'ScalarExample';

=cut

=type SearchObj

  SearchObj

=type-library SearchObj

Data::Object::Types

=type-composite SearchObj

  InstanceOf["Data::Object::Search"]

=type-parent SearchObj

  Object

=type-example-1 SearchObj

  # package SearchExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Search';

  package main;

  bless {}, 'SearchExample';

=cut

=type SearchObject

  SearchObject

=type-library SearchObject

Data::Object::Types

=type-composite SearchObject

  InstanceOf["Data::Object::Search"]

=type-parent SearchObject

  Object

=type-example-1 SearchObject

  # package SearchExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Search';

  package main;

  bless {}, 'SearchExample';

=cut

=type SpaceObj

  SpaceObj

=type-library SpaceObj

Data::Object::Types

=type-composite SpaceObj

  InstanceOf["Data::Object::Space"]

=type-parent SpaceObj

  Object

=type-coercion-1 SpaceObj

  # coerce from Str

  'abc'

=type-example-1 SpaceObj

  # package SpaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Space';

  package main;

  bless {}, 'SpaceExample';

=cut

=type SpaceObject

  SpaceObject

=type-library SpaceObject

Data::Object::Types

=type-composite SpaceObject

  InstanceOf["Data::Object::Space"]

=type-parent SpaceObject

  Object

=type-coercion-1 SpaceObject

  # coerce from Str

  'abc'

=type-example-1 SpaceObject

  # package SpaceExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Space';

  package main;

  bless {}, 'SpaceExample';

=cut

=type Stashable

  Stashable

=type-library Stashable

Data::Object::Types

=type-composite Stashable

  ConsumerOf["Data::Object::Role::Stashable"]

=type-parent Stashable

  Object

=type-example-1 Stashable

  # package StashableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Stashable';

  package main;

  bless {}, 'StashableExample';

=cut

=type StateObj

  StateObj

=type-library StateObj

Data::Object::Types

=type-composite StateObj

  InstanceOf["Data::Object::State"]

=type-parent StateObj

  Object

=type-example-1 StateObj

  # package StateExample;

  # use Data::Object::Class;

  # extends 'Data::Object::State';

  package main;

  bless {}, 'StateExample';

=cut

=type StateObject

  StateObject

=type-library StateObject

Data::Object::Types

=type-composite StateObject

  InstanceOf["Data::Object::State"]

=type-parent StateObject

  Object

=type-example-1 StateObject

  # package StateExample;

  # use Data::Object::Class;

  # extends 'Data::Object::State';

  package main;

  bless {}, 'StateExample';

=cut

=type StrObj

  StrObj

=type-library StrObj

Data::Object::Types

=type-composite StrObj

  InstanceOf["Data::Object::String"]

=type-parent StrObj

  Object

=type-coercion-1 StrObj

  # coerce from Str

  'abc'

=type-example-1 StrObj

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=cut

=type StrObject

  StrObject

=type-library StrObject

Data::Object::Types

=type-composite StrObject

  InstanceOf["Data::Object::String"]

=type-parent StrObject

  Object

=type-coercion-1 StrObject

  # coerce from Str

  'abc'

=type-example-1 StrObject

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=cut

=type StringObj

  StringObj

=type-library StringObj

Data::Object::Types

=type-composite StringObj

  InstanceOf["Data::Object::String"]

=type-parent StringObj

  Object

=type-coercion-1 StringObj

  # coerce from Str

  'abc'

=type-example-1 StringObj

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=cut

=type StringObject

  StringObject

=type-library StringObject

Data::Object::Types

=type-composite StringObject

  InstanceOf["Data::Object::String"]

=type-parent StringObject

  Object

=type-coercion-1 StringObject

  # coerce from Str

  'abc'

=type-example-1 StringObject

  # package StringExample;

  # use Data::Object::Class;

  # extends 'Data::Object::String';

  package main;

  my $string = 'abc';

  bless \$string, 'StringExample';

=cut

=type StructObj

  StructObj

=type-library StructObj

Data::Object::Types

=type-composite StructObj

  InstanceOf["Data::Object::Struct"]

=type-parent StructObj

  Object

=type-example-1 StructObj

  # package StructExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Struct';

  package main;

  bless {}, 'StructExample';

=cut

=type StructObject

  StructObject

=type-library StructObject

Data::Object::Types

=type-composite StructObject

  InstanceOf["Data::Object::Struct"]

=type-parent StructObject

  Object

=type-example-1 StructObject

  # package StructExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Struct';

  package main;

  bless {}, 'StructExample';

=cut

=type Throwable

  Throwable

=type-library Throwable

Data::Object::Types

=type-composite Throwable

  ConsumerOf["Data::Object::Role::Throwable"]

=type-parent Throwable

  Object

=type-example-1 Throwable

  # package ThrowableExample;

  # use Data::Object::Class;

  # with 'Data::Object::Role::Throwable';

  package main;

  bless {}, 'ThrowableExample';

=cut

=type UndefObj

  UndefObj

=type-library UndefObj

Data::Object::Types

=type-composite UndefObj

  InstanceOf["Data::Object::Undef"]

=type-parent UndefObj

  Object

=type-coercion-1 UndefObj

  # coerce from Undef

  undef

=type-example-1 UndefObj

  # package UndefExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Undef';

  package main;

  my $undef = undef;

  bless \$undef, 'UndefExample';

=cut

=type UndefObject

  UndefObject

=type-library UndefObject

Data::Object::Types

=type-composite UndefObject

  InstanceOf["Data::Object::Undef"]

=type-parent UndefObject

  Object

=type-coercion-1 UndefObject

  # coerce from Undef

  undef

=type-example-1 UndefObject

  # package UndefExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Undef';

  package main;

  my $undef = undef;

  bless \$undef, 'UndefExample';

=cut

=type VarsObj

  VarsObj

=type-library VarsObj

Data::Object::Types

=type-composite VarsObj

  InstanceOf["Data::Object::Vars"]

=type-parent VarsObj

  Object

=type-example-1 VarsObj

  # package VarsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Vars';

  package main;

  bless {}, 'VarsExample';

=cut

=type VarsObject

  VarsObject

=type-library VarsObject

Data::Object::Types

=type-composite VarsObject

  InstanceOf["Data::Object::Vars"]

=type-parent VarsObject

  Object

=type-example-1 VarsObject

  # package VarsExample;

  # use Data::Object::Class;

  # extends 'Data::Object::Vars';

  package main;

  bless {}, 'VarsExample';

=cut

BEGIN {
  {
    package Newable;

    sub new {
      bless(ref($_[1]) ? $_[1] : do { my $r = \$_[1]; $r }, $_[0]);
    }
  }
  {
    package Data::Object::Args;

    use base 'Newable';

    package ArgsExample;

    our @ISA = 'Data::Object::Args';
  }
  {
    package Data::Object::Array;

    use base 'Newable';

    package ArrayExample;

    our @ISA = 'Data::Object::Array';
  }
  {
    package Data::Object::Boolean;

    use base 'Newable';

    package BooleanExample;

    our @ISA = 'Data::Object::Boolean';
  }
  {
    package Data::Object::Cli;

    use base 'Newable';

    package CliExample;

    our @ISA = 'Data::Object::Cli';
  }
  {
    package Data::Object::Code;

    use base 'Newable';

    package CodeExample;

    our @ISA = 'Data::Object::Code';
  }
  {
    package Data::Object::Data;

    use base 'Newable';

    package DataExample;

    our @ISA = 'Data::Object::Data';
  }
  {
    package Data::Object::Exception;

    use base 'Newable';

    package ExceptionExample;

    our @ISA = 'Data::Object::Exception';
  }
  {
    package Data::Object::Float;

    use base 'Newable';

    package FloatExample;

    our @ISA = 'Data::Object::Float';
  }
  {
    package Data::Object::Func;

    use base 'Newable';

    package FuncExample;

    our @ISA = 'Data::Object::Func';
  }
  {
    package Data::Object::Hash;

    use base 'Newable';

    package HashExample;

    our @ISA = 'Data::Object::Hash';
  }
  {
    package Data::Object::Number;

    use base 'Newable';

    package NumberExample;

    our @ISA = 'Data::Object::Number';
  }
  {
    package Data::Object::Opts;

    use base 'Newable';

    package OptsExample;

    our @ISA = 'Data::Object::Opts';
  }
  {
    package Data::Object::Regexp;

    use base 'Newable';

    package RegexpExample;

    our @ISA = 'Data::Object::Regexp';
  }
  {
    package Data::Object::Replace;

    use base 'Newable';

    package ReplaceExample;

    our @ISA = 'Data::Object::Replace';
  }
  {
    package Data::Object::Scalar;

    use base 'Newable';

    package ScalarExample;

    our @ISA = 'Data::Object::Scalar';
  }
  {
    package Data::Object::Search;

    use base 'Newable';

    package SearchExample;

    our @ISA = 'Data::Object::Search';
  }
  {
    package Data::Object::Space;

    use base 'Newable';

    package SpaceExample;

    our @ISA = 'Data::Object::Space';
  }
  {
    package Data::Object::State;

    use base 'Newable';

    package StateExample;

    our @ISA = 'Data::Object::State';
  }
  {
    package Data::Object::String;

    use base 'Newable';

    package StringExample;

    our @ISA = 'Data::Object::String';
  }
  {
    package Data::Object::Struct;

    use base 'Newable';

    package StructExample;

    our @ISA = 'Data::Object::Struct';
  }
  {
    package Data::Object::Undef;

    use base 'Newable';

    package UndefExample;

    our @ISA = 'Data::Object::Undef';
  }
  {
    package Data::Object::Vars;

    use base 'Newable';

    package VarsExample;

    our @ISA = 'Data::Object::Vars';
  }
  {
    package DumpableExample;

    sub does {
      'Data::Object::Role::Dumpable' eq $_[1];
    }
  }
  {
    package ImmutableExample;

    sub does {
      'Data::Object::Role::Immutable' eq $_[1];
    }
  }
  {
    package StashableExample;

    sub does {
      'Data::Object::Role::Stashable' eq $_[1];
    }
  }
  {
    package ThrowableExample;

    sub does {
      'Data::Object::Role::Throwable' eq $_[1];
    }
  }
}

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
