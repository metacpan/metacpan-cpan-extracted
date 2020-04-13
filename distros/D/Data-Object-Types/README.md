# NAME

Data::Object::Types

# ABSTRACT

Data-Object Type Constraints

# SYNOPSIS

    package main;

    use Data::Object::Types;

    1;

# DESCRIPTION

This package provides type constraints for [Data::Object](https://metacpan.org/pod/Data::Object).

# CONSTRAINTS

This package declares the following type constraints:

## argsobj

    ArgsObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- argsobj parent

        Object

- argsobj composition

        InstanceOf["Data::Object::Args"]

- argsobj example #1

        # package ArgsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Args';

        package main;

        bless {}, 'ArgsExample';

## argsobject

    ArgsObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- argsobject parent

        Object

- argsobject composition

        InstanceOf["Data::Object::Args"]

- argsobject example #1

        # package ArgsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Args';

        package main;

        bless {}, 'ArgsExample';

## arrayobj

    ArrayObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- arrayobj parent

        Object

- arrayobj composition

        InstanceOf["Data::Object::Array"]

- arrayobj coercion #1

        # coerce from ArrayRef

        []

- arrayobj example #1

        # package ArrayExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Array';

        package main;

        bless [], 'ArrayExample';

## arrayobject

    ArrayObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- arrayobject parent

        Object

- arrayobject composition

        InstanceOf["Data::Object::Array"]

- arrayobject coercion #1

        # coerce from ArrayRef

        []

- arrayobject example #1

        # package ArrayExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Array';

        package main;

        bless [], 'ArrayExample';

## boolobj

    BoolObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- boolobj parent

        Object

- boolobj composition

        InstanceOf["Data::Object::Boolean"]

- boolobj example #1

        # package BooleanExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Boolean';

        package main;

        my $bool = 1;

        bless \$bool, 'BooleanExample';

## boolobject

    BoolObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- boolobject parent

        Object

- boolobject composition

        InstanceOf["Data::Object::Boolean"]

- boolobject example #1

        # package BooleanExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Boolean';

        package main;

        my $bool = 1;

        bless \$bool, 'BooleanExample';

## booleanobj

    BooleanObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- booleanobj parent

        Object

- booleanobj composition

        InstanceOf["Data::Object::Boolean"]

- booleanobj example #1

        # package BooleanExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Boolean';

        package main;

        my $bool = 1;

        bless \$bool, 'BooleanExample';

## booleanobject

    BooleanObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- booleanobject parent

        Object

- booleanobject composition

        InstanceOf["Data::Object::Boolean"]

- booleanobject example #1

        # package BooleanExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Boolean';

        package main;

        my $bool = 1;

        bless \$bool, 'BooleanExample';

## cliobj

    CliObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- cliobj parent

        Object

- cliobj composition

        InstanceOf["Data::Object::Cli"]

- cliobj example #1

        # package CliExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Cli';

        package main;

        bless {}, 'CliExample';

## cliobject

    CliObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- cliobject parent

        Object

- cliobject composition

        InstanceOf["Data::Object::Cli"]

- cliobject example #1

        # package CliExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Cli';

        package main;

        bless {}, 'CliExample';

## codeobj

    CodeObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- codeobj parent

        Object

- codeobj composition

        InstanceOf["Data::Object::Code"]

- codeobj coercion #1

        # coerce from CodeRef

        sub{}

- codeobj example #1

        # package CodeExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Code';

        package main;

        bless sub{}, 'CodeExample';

## codeobject

    CodeObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- codeobject parent

        Object

- codeobject composition

        InstanceOf["Data::Object::Code"]

- codeobject coercion #1

        # coerce from CodeRef

        sub{}

- codeobject example #1

        # package CodeExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Code';

        package main;

        bless sub{}, 'CodeExample';

## dataobj

    DataObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dataobj parent

        Object

- dataobj composition

        InstanceOf["Data::Object::Data"]

- dataobj example #1

        # package DataExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Data';

        package main;

        bless {}, 'DataExample';

## dataobject

    DataObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dataobject parent

        Object

- dataobject composition

        InstanceOf["Data::Object::Data"]

- dataobject example #1

        # package DataExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Data';

        package main;

        bless {}, 'DataExample';

## doargs

    DoArgs

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doargs parent

        Object

- doargs composition

        InstanceOf["Data::Object::Args"]

- doargs example #1

        # package ArgsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Args';

        package main;

        bless {}, 'ArgsExample';

## doarray

    DoArray

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doarray parent

        Object

- doarray composition

        InstanceOf["Data::Object::Array"]

- doarray coercion #1

        # coerce from ArrayRef

        []

- doarray example #1

        # package ArrayExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Array';

        package main;

        bless [], 'ArrayExample';

## doboolean

    DoBoolean

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doboolean parent

        Object

- doboolean composition

        InstanceOf["Data::Object::Boolean"]

- doboolean example #1

        # package BooleanExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Boolean';

        package main;

        my $bool = 1;

        bless \$bool, 'BooleanExample';

## docli

    DoCli

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- docli parent

        Object

- docli composition

        InstanceOf["Data::Object::Cli"]

- docli example #1

        # package CliExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Cli';

        package main;

        bless {}, 'CliExample';

## docode

    DoCode

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- docode parent

        Object

- docode composition

        InstanceOf["Data::Object::Code"]

- docode coercion #1

        # coerce from CodeRef

        sub{}

- docode example #1

        # package CodeExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Code';

        package main;

        bless sub{}, 'CodeExample';

## dodata

    DoData

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dodata parent

        Object

- dodata composition

        InstanceOf["Data::Object::Data"]

- dodata example #1

        # package DataExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Data';

        package main;

        bless {}, 'DataExample';

## dodumpable

    DoDumpable

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dodumpable parent

        Object

- dodumpable composition

        ConsumerOf["Data::Object::Role::Dumpable"]

- dodumpable example #1

        # package DumpableExample;

        # use Data::Object::Class;

        # with 'Data::Object::Role::Dumpable';

        package main;

        bless {}, 'DumpableExample';

## doexception

    DoException

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doexception parent

        Object

- doexception composition

        InstanceOf["Data::Object::Exception"]

- doexception example #1

        # package ExceptionExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Exception';

        package main;

        bless {}, 'ExceptionExample';

## dofloat

    DoFloat

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dofloat parent

        Object

- dofloat composition

        InstanceOf["Data::Object::Float"]

- dofloat coercion #1

        # coerce from LaxNum

        123

- dofloat coercion #2

        # coerce from Str

        '123'

- dofloat coercion #3

        # coerce from Num

        123

- dofloat example #1

        # package FloatExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Float';

        package main;

        my $float = 1.23;

        bless \$float, 'FloatExample';

## dofunc

    DoFunc

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dofunc parent

        Object

- dofunc composition

        InstanceOf["Data::Object::Func"]

- dofunc example #1

        # package FuncExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Func';

        package main;

        bless {}, 'FuncExample';

## dohash

    DoHash

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dohash parent

        Object

- dohash composition

        InstanceOf["Data::Object::Hash"]

- dohash coercion #1

        # coerce from HashRef

        {}

- dohash example #1

        # package HashExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Hash';

        package main;

        bless {}, 'HashExample';

## doimmutable

    DoImmutable

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doimmutable parent

        Object

- doimmutable composition

        ConsumerOf["Data::Object::Role::Immutable"]

- doimmutable example #1

        # package ImmutableExample;

        # use Data::Object::Class;

        # with 'Data::Object::Role::Immutable';

        package main;

        bless {}, 'ImmutableExample';

## donum

    DoNum

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- donum parent

        Object

- donum composition

        InstanceOf["Data::Object::Number"]

- donum coercion #1

        # coerce from LaxNum

        123

- donum coercion #2

        # coerce from Str

        '123'

- donum coercion #3

        # coerce from Num

        123

- donum coercion #4

        # coerce from StrictNum

        123

- donum coercion #5

        # coerce from Int

        99999

- donum example #1

        # package NumberExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Number';

        package main;

        my $num = 123;

        bless \$num, 'NumberExample';

## doopts

    DoOpts

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doopts parent

        Object

- doopts composition

        InstanceOf["Data::Object::Opts"]

- doopts example #1

        # package OptsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Opts';

        package main;

        bless {}, 'OptsExample';

## doregexp

    DoRegexp

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doregexp parent

        Object

- doregexp composition

        InstanceOf["Data::Object::Regexp"]

- doregexp coercion #1

        # coerce from RegexpRef

        qr//

- doregexp example #1

        # package RegexpExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Regexp';

        package main;

        bless {}, 'RegexpExample';

## doreplace

    DoReplace

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doreplace parent

        Object

- doreplace composition

        InstanceOf["Data::Object::Replace"]

- doreplace example #1

        # package ReplaceExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Replace';

        package main;

        bless {}, 'ReplaceExample';

## doscalar

    DoScalar

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doscalar parent

        Object

- doscalar composition

        InstanceOf["Data::Object::Scalar"]

- doscalar coercion #1

        # coerce from ScalarRef

        do { my $i = 0; \$i }

- doscalar example #1

        # package ScalarExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Scalar';

        package main;

        my $scalar = 'abc';

        bless \$scalar, 'ScalarExample';

## dosearch

    DoSearch

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dosearch parent

        Object

- dosearch composition

        InstanceOf["Data::Object::Search"]

- dosearch example #1

        # package SearchExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Search';

        package main;

        bless {}, 'SearchExample';

## dospace

    DoSpace

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dospace parent

        Object

- dospace composition

        InstanceOf["Data::Object::Space"]

- dospace coercion #1

        # coerce from Str

        'abc'

- dospace example #1

        # package SpaceExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Space';

        package main;

        bless {}, 'SpaceExample';

## dostashable

    DoStashable

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dostashable parent

        Object

- dostashable composition

        ConsumerOf["Data::Object::Role::Stashable"]

- dostashable example #1

        # package StashableExample;

        # use Data::Object::Class;

        # with 'Data::Object::Role::Stashable';

        package main;

        bless {}, 'StashableExample';

## dostate

    DoState

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dostate parent

        Object

- dostate composition

        InstanceOf["Data::Object::State"]

- dostate example #1

        # package StateExample;

        # use Data::Object::Class;

        # extends 'Data::Object::State';

        package main;

        bless {}, 'StateExample';

## dostr

    DoStr

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dostr parent

        Object

- dostr composition

        InstanceOf["Data::Object::String"]

- dostr coercion #1

        # coerce from Str

        'abc'

- dostr example #1

        # package StringExample;

        # use Data::Object::Class;

        # extends 'Data::Object::String';

        package main;

        my $string = 'abc';

        bless \$string, 'StringExample';

## dostruct

    DoStruct

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dostruct parent

        Object

- dostruct composition

        InstanceOf["Data::Object::Struct"]

- dostruct example #1

        # package StructExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Struct';

        package main;

        bless {}, 'StructExample';

## dothrowable

    DoThrowable

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dothrowable parent

        Object

- dothrowable composition

        ConsumerOf["Data::Object::Role::Throwable"]

- dothrowable example #1

        # package ThrowableExample;

        # use Data::Object::Class;

        # with 'Data::Object::Role::Throwable';

        package main;

        bless {}, 'ThrowableExample';

## doundef

    DoUndef

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- doundef parent

        Object

- doundef composition

        InstanceOf["Data::Object::Undef"]

- doundef coercion #1

        # coerce from Undef

        undef

- doundef example #1

        # package UndefExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Undef';

        my $undef = undef;

        bless \$undef, 'UndefExample';

## dovars

    DoVars

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dovars parent

        Object

- dovars composition

        InstanceOf["Data::Object::Vars"]

- dovars example #1

        # package VarsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Vars';

        package main;

        bless {}, 'VarsExample';

## dumpable

    Dumpable

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- dumpable parent

        Object

- dumpable composition

        ConsumerOf["Data::Object::Role::Dumpable"]

- dumpable example #1

        # package DumpableExample;

        # use Data::Object::Class;

        # with 'Data::Object::Role::Dumpable';

        package main;

        bless {}, 'DumpableExample';

## exceptionobj

    ExceptionObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- exceptionobj parent

        Object

- exceptionobj composition

        InstanceOf["Data::Object::Exception"]

- exceptionobj example #1

        # package ExceptionExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Exception';

        package main;

        bless {}, 'ExceptionExample';

## exceptionobject

    ExceptionObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- exceptionobject parent

        Object

- exceptionobject composition

        InstanceOf["Data::Object::Exception"]

- exceptionobject example #1

        # package ExceptionExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Exception';

        package main;

        bless {}, 'ExceptionExample';

## floatobj

    FloatObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- floatobj parent

        Object

- floatobj composition

        InstanceOf["Data::Object::Float"]

- floatobj coercion #1

        # coerce from Num

        123

- floatobj coercion #2

        # coerce from LaxNum

        123

- floatobj coercion #3

        # coerce from Str

        '1.23'

- floatobj example #1

        # package FloatExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Float';

        package main;

        my $float = 1.23;

        bless \$float, 'FloatExample';

## floatobject

    FloatObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- floatobject parent

        Object

- floatobject composition

        InstanceOf["Data::Object::Float"]

- floatobject coercion #1

        # coerce from Num

        123

- floatobject coercion #2

        # coerce from LaxNum

        123

- floatobject coercion #3

        # coerce from Str

        '1.23'

- floatobject example #1

        # package FloatExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Float';

        package main;

        my $float = 1.23;

        bless \$float, 'FloatExample';

## funcobj

    FuncObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- funcobj parent

        Object

- funcobj composition

        InstanceOf["Data::Object::Func"]

- funcobj example #1

        # package FuncExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Func';

        package main;

        bless {}, 'FuncExample';

## funcobject

    FuncObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- funcobject parent

        Object

- funcobject composition

        InstanceOf["Data::Object::Func"]

- funcobject example #1

        # package FuncExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Func';

        package main;

        bless {}, 'FuncExample';

## hashobj

    HashObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- hashobj parent

        Object

- hashobj composition

        InstanceOf["Data::Object::Hash"]

- hashobj coercion #1

        # coerce from HashRef

        {}

- hashobj example #1

        # package HashExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Hash';

        package main;

        bless {}, 'HashExample';

## hashobject

    HashObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- hashobject parent

        Object

- hashobject composition

        InstanceOf["Data::Object::Hash"]

- hashobject coercion #1

        # coerce from HashRef

        {}

- hashobject example #1

        # package HashExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Hash';

        package main;

        bless {}, 'HashExample';

## immutable

    Immutable

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- immutable parent

        Object

- immutable composition

        ConsumerOf["Data::Object::Role::Immutable"]

- immutable example #1

        # package ImmutableExample;

        # use Data::Object::Class;

        # with 'Data::Object::Role::Immutable';

        package main;

        bless {}, 'ImmutableExample';

## numobj

    NumObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- numobj parent

        Object

- numobj composition

        InstanceOf["Data::Object::Number"]

- numobj coercion #1

        # coerce from LaxNum

        123

- numobj coercion #2

        # coerce from Str

        '123'

- numobj coercion #3

        # coerce from Int

        99999

- numobj coercion #4

        # coerce from Num

        123

- numobj coercion #5

        # coerce from StrictNum

        123

- numobj example #1

        # package NumberExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Number';

        package main;

        my $num = 123;

        bless \$num, 'NumberExample';

## numobject

    NumObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- numobject parent

        Object

- numobject composition

        InstanceOf["Data::Object::Number"]

- numobject coercion #1

        # coerce from Num

        123

- numobject coercion #2

        # coerce from StrictNum

        123

- numobject coercion #3

        # coerce from Int

        99999

- numobject coercion #4

        # coerce from LaxNum

        123

- numobject coercion #5

        # coerce from Str

        '123'

- numobject example #1

        # package NumberExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Number';

        package main;

        my $num = 123;

        bless \$num, 'NumberExample';

## numberobj

    NumberObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- numberobj parent

        Object

- numberobj composition

        InstanceOf["Data::Object::Number"]

- numberobj coercion #1

        # coerce from Int

        99999

- numberobj coercion #2

        # coerce from StrictNum

        123

- numberobj coercion #3

        # coerce from Num

        123

- numberobj coercion #4

        # coerce from Str

        '123'

- numberobj coercion #5

        # coerce from LaxNum

        123

- numberobj example #1

        # package NumberExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Number';

        package main;

        my $num = 123;

        bless \$num, 'NumberExample';

## numberobject

    NumberObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- numberobject parent

        Object

- numberobject composition

        InstanceOf["Data::Object::Number"]

- numberobject coercion #1

        # coerce from Int

        99999

- numberobject coercion #2

        # coerce from StrictNum

        123

- numberobject coercion #3

        # coerce from Num

        123

- numberobject coercion #4

        # coerce from Str

        '123'

- numberobject coercion #5

        # coerce from LaxNum

        123

- numberobject example #1

        # package NumberExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Number';

        package main;

        my $num = 123;

        bless \$num, 'NumberExample';

## optsobj

    OptsObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- optsobj parent

        Object

- optsobj composition

        InstanceOf["Data::Object::Opts"]

- optsobj example #1

        # package OptsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Opts';

        package main;

        bless {}, 'OptsExample';

## optsobject

    OptsObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- optsobject parent

        Object

- optsobject composition

        InstanceOf["Data::Object::Opts"]

- optsobject example #1

        # package OptsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Opts';

        package main;

        bless {}, 'OptsExample';

## regexpobj

    RegexpObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- regexpobj parent

        Object

- regexpobj composition

        InstanceOf["Data::Object::Regexp"]

- regexpobj coercion #1

        # coerce from RegexpRef

        qr//

- regexpobj example #1

        # package RegexpExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Regexp';

        package main;

        bless {}, 'RegexpExample';

## regexpobject

    RegexpObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- regexpobject parent

        Object

- regexpobject composition

        InstanceOf["Data::Object::Regexp"]

- regexpobject coercion #1

        # coerce from RegexpRef

        qr//

- regexpobject example #1

        # package RegexpExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Regexp';

        package main;

        bless {}, 'RegexpExample';

## replaceobj

    ReplaceObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- replaceobj parent

        Object

- replaceobj composition

        InstanceOf["Data::Object::Replace"]

- replaceobj example #1

        # package ReplaceExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Replace';

        package main;

        bless {}, 'ReplaceExample';

## replaceobject

    ReplaceObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- replaceobject parent

        Object

- replaceobject composition

        InstanceOf["Data::Object::Replace"]

- replaceobject example #1

        # package ReplaceExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Replace';

        package main;

        bless {}, 'ReplaceExample';

## scalarobj

    ScalarObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- scalarobj parent

        Object

- scalarobj composition

        InstanceOf["Data::Object::Scalar"]

- scalarobj coercion #1

        # coerce from ScalarRef

        do { my $i = 0; \$i }

- scalarobj example #1

        # package ScalarExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Scalar';

        package main;

        my $scalar = 'abc';

        bless \$scalar, 'ScalarExample';

## scalarobject

    ScalarObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- scalarobject parent

        Object

- scalarobject composition

        InstanceOf["Data::Object::Scalar"]

- scalarobject coercion #1

        # coerce from ScalarRef

        do { my $i = 0; \$i }

- scalarobject example #1

        # package ScalarExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Scalar';

        package main;

        my $scalar = 'abc';

        bless \$scalar, 'ScalarExample';

## searchobj

    SearchObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- searchobj parent

        Object

- searchobj composition

        InstanceOf["Data::Object::Search"]

- searchobj example #1

        # package SearchExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Search';

        package main;

        bless {}, 'SearchExample';

## searchobject

    SearchObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- searchobject parent

        Object

- searchobject composition

        InstanceOf["Data::Object::Search"]

- searchobject example #1

        # package SearchExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Search';

        package main;

        bless {}, 'SearchExample';

## spaceobj

    SpaceObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- spaceobj parent

        Object

- spaceobj composition

        InstanceOf["Data::Object::Space"]

- spaceobj coercion #1

        # coerce from Str

        'abc'

- spaceobj example #1

        # package SpaceExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Space';

        package main;

        bless {}, 'SpaceExample';

## spaceobject

    SpaceObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- spaceobject parent

        Object

- spaceobject composition

        InstanceOf["Data::Object::Space"]

- spaceobject coercion #1

        # coerce from Str

        'abc'

- spaceobject example #1

        # package SpaceExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Space';

        package main;

        bless {}, 'SpaceExample';

## stashable

    Stashable

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- stashable parent

        Object

- stashable composition

        ConsumerOf["Data::Object::Role::Stashable"]

- stashable example #1

        # package StashableExample;

        # use Data::Object::Class;

        # with 'Data::Object::Role::Stashable';

        package main;

        bless {}, 'StashableExample';

## stateobj

    StateObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- stateobj parent

        Object

- stateobj composition

        InstanceOf["Data::Object::State"]

- stateobj example #1

        # package StateExample;

        # use Data::Object::Class;

        # extends 'Data::Object::State';

        package main;

        bless {}, 'StateExample';

## stateobject

    StateObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- stateobject parent

        Object

- stateobject composition

        InstanceOf["Data::Object::State"]

- stateobject example #1

        # package StateExample;

        # use Data::Object::Class;

        # extends 'Data::Object::State';

        package main;

        bless {}, 'StateExample';

## strobj

    StrObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- strobj parent

        Object

- strobj composition

        InstanceOf["Data::Object::String"]

- strobj coercion #1

        # coerce from Str

        'abc'

- strobj example #1

        # package StringExample;

        # use Data::Object::Class;

        # extends 'Data::Object::String';

        package main;

        my $string = 'abc';

        bless \$string, 'StringExample';

## strobject

    StrObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- strobject parent

        Object

- strobject composition

        InstanceOf["Data::Object::String"]

- strobject coercion #1

        # coerce from Str

        'abc'

- strobject example #1

        # package StringExample;

        # use Data::Object::Class;

        # extends 'Data::Object::String';

        package main;

        my $string = 'abc';

        bless \$string, 'StringExample';

## stringobj

    StringObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- stringobj parent

        Object

- stringobj composition

        InstanceOf["Data::Object::String"]

- stringobj coercion #1

        # coerce from Str

        'abc'

- stringobj example #1

        # package StringExample;

        # use Data::Object::Class;

        # extends 'Data::Object::String';

        package main;

        my $string = 'abc';

        bless \$string, 'StringExample';

## stringobject

    StringObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- stringobject parent

        Object

- stringobject composition

        InstanceOf["Data::Object::String"]

- stringobject coercion #1

        # coerce from Str

        'abc'

- stringobject example #1

        # package StringExample;

        # use Data::Object::Class;

        # extends 'Data::Object::String';

        package main;

        my $string = 'abc';

        bless \$string, 'StringExample';

## structobj

    StructObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- structobj parent

        Object

- structobj composition

        InstanceOf["Data::Object::Struct"]

- structobj example #1

        # package StructExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Struct';

        package main;

        bless {}, 'StructExample';

## structobject

    StructObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- structobject parent

        Object

- structobject composition

        InstanceOf["Data::Object::Struct"]

- structobject example #1

        # package StructExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Struct';

        package main;

        bless {}, 'StructExample';

## throwable

    Throwable

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- throwable parent

        Object

- throwable composition

        ConsumerOf["Data::Object::Role::Throwable"]

- throwable example #1

        # package ThrowableExample;

        # use Data::Object::Class;

        # with 'Data::Object::Role::Throwable';

        package main;

        bless {}, 'ThrowableExample';

## undefobj

    UndefObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- undefobj parent

        Object

- undefobj composition

        InstanceOf["Data::Object::Undef"]

- undefobj coercion #1

        # coerce from Undef

        undef

- undefobj example #1

        # package UndefExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Undef';

        package main;

        my $undef = undef;

        bless \$undef, 'UndefExample';

## undefobject

    UndefObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- undefobject parent

        Object

- undefobject composition

        InstanceOf["Data::Object::Undef"]

- undefobject coercion #1

        # coerce from Undef

        undef

- undefobject example #1

        # package UndefExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Undef';

        package main;

        my $undef = undef;

        bless \$undef, 'UndefExample';

## varsobj

    VarsObj

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- varsobj parent

        Object

- varsobj composition

        InstanceOf["Data::Object::Vars"]

- varsobj example #1

        # package VarsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Vars';

        package main;

        bless {}, 'VarsExample';

## varsobject

    VarsObject

This type is defined in the [Data::Object::Types](https://metacpan.org/pod/Data::Object::Types) library.

- varsobject parent

        Object

- varsobject composition

        InstanceOf["Data::Object::Vars"]

- varsobject example #1

        # package VarsExample;

        # use Data::Object::Class;

        # extends 'Data::Object::Vars';

        package main;

        bless {}, 'VarsExample';

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-types/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-types/wiki)

[Project](https://github.com/iamalnewkirk/data-object-types)

[Initiatives](https://github.com/iamalnewkirk/data-object-types/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-types/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-types/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-types/issues)
