# NAME

Data::Object

# ABSTRACT

Object-Orientation for Perl 5

# SYNOPSIS

    package main;

    use Data::Object;

    my $array = Box Array [1..4];

    # my $iterator = $array->iterator;

    # $iterator->next; # 1

# DESCRIPTION

This package automatically exports and provides constructor functions for
creating chainable data type objects from raw Perl data types.

# LIBRARIES

This package uses type constraints from:

[Data::Object::Types](https://metacpan.org/pod/Data::Object::Types)

# FUNCTIONS

This package implements the following functions:

## args

    Args(HashRef $data) : InstanceOf["Data::Object::Args"]

The Args function returns a [Data::Object::Args](https://metacpan.org/pod/Data::Object::Args) object.

- Args example #1

        package main;

        use Data::Object 'Args';

        my $args = Args; # [...]

- Args example #2

        package main;

        my $args = Args {
          subcommand => 0
        };

        # $args->subcommand;

## array

    Array(ArrayRef $data) : InstanceOf["Data::Object::Array"]

The Array function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) which wraps a
[Data::Object::Array](https://metacpan.org/pod/Data::Object::Array) object.

- Array example #1

        package main;

        my $array = Array; # []

- Array example #2

        package main;

        my $array = Array [1..4];

## boolean

    Boolean(Bool $data) : BooleanObject

The Boolean function returns a [Data::Object::Boolean](https://metacpan.org/pod/Data::Object::Boolean) object representing a
true or false value.

- Boolean example #1

        package main;

        my $boolean = Boolean;

- Boolean example #2

        package main;

        my $boolean = Boolean 0;

## box

    Box(Any $data) : InstanceOf["Data::Object::Box"]

The Box function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) object representing a data type
object which is automatically deduced.

- Box example #1

        package main;

        my $box = Box;

- Box example #2

        package main;

        my $box = Box 123;

- Box example #3

        package main;

        my $box = Box [1..4];

- Box example #4

        package main;

        my $box = Box {1..4};

## code

    Code(CodeRef $data) : InstanceOf["Data::Object::Code"]

The Code function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) which wraps a
[Data::Object::Code](https://metacpan.org/pod/Data::Object::Code) object.

- Code example #1

        package main;

        my $code = Code;

- Code example #2

        package main;

        my $code = Code sub { shift };

## data

    Data(Str $file) : InstanceOf["Data::Object::Data"]

The Data function returns a [Data::Object::Data](https://metacpan.org/pod/Data::Object::Data) object.

- Data example #1

        package main;

        use Data::Object 'Data';

        my $data = Data;

- Data example #2

        package main;

        my $data = Data 't/Data_Object.t';

        # $data->contents(...);

## error

    Error(Str | HashRef) : InstanceOf["Data::Object::Exception"]

The Error function returns a [Data::Object::Exception](https://metacpan.org/pod/Data::Object::Exception) object.

- Error example #1

        package main;

        use Data::Object 'Error';

        my $error = Error;

        # die $error;

- Error example #2

        package main;

        my $error = Error 'Oops!';

        # die $error;

- Error example #3

        package main;

        my $error = Error {
          message => 'Oops!',
          context => { time => time }
        };

        # die $error;

## false

    False() : BooleanObject

The False function returns a [Data::Object::Boolean](https://metacpan.org/pod/Data::Object::Boolean) object representing a
false value.

- False example #1

        package main;

        my $false = False;

## float

    Float(Num $data) : InstanceOf["Data::Object::Float"]

The Float function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) which wraps a
[Data::Object::Float](https://metacpan.org/pod/Data::Object::Float) object.

- Float example #1

        package main;

        my $float = Float;

- Float example #2

        package main;

        my $float = Float '0.0';

## hash

    Hash(HashRef $data) : InstanceOf["Data::Object::Hash"]

The Hash function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) which wraps a
[Data::Object::Hash](https://metacpan.org/pod/Data::Object::Hash) object.

- Hash example #1

        package main;

        my $hash = Hash;

- Hash example #2

        package main;

        my $hash = Hash {1..4};

## name

    Name(Str $data) : InstanceOf["Data::Object::Name"]

The Name function returns a [Name::Object::Name](https://metacpan.org/pod/Name::Object::Name) object.

- Name example #1

        package main;

        use Data::Object 'Name';

        my $name = Name 'Example Title';

        # $name->package;

## number

    Number(Num $data) : InstanceOf["Data::Object::Number"]

The Number function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) which wraps a
[Data::Object::Number](https://metacpan.org/pod/Data::Object::Number) object.

- Number example #1

        package main;

        my $number = Number;

- Number example #2

        package main;

        my $number = Number 123;

## opts

    Opts(HashRef $data) : InstanceOf["Data::Object::Opts"]

The Opts function returns a [Data::Object::Opts](https://metacpan.org/pod/Data::Object::Opts) object.

- Opts example #1

        package main;

        use Data::Object 'Opts';

        my $opts = Opts;

- Opts example #2

        package main;

        my $opts = Opts {
          spec => ['files|f=s']
        };

        # $opts->files; [...]

## regexp

    Regexp(RegexpRef $data) : InstanceOf["Data::Object::Regexp"]

The Regexp function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) which wraps a
[Data::Object::Regexp](https://metacpan.org/pod/Data::Object::Regexp) object.

- Regexp example #1

        package main;

        my $regexp = Regexp;

- Regexp example #2

        package main;

        my $regexp = Regexp qr/.*/;

## scalar

    Scalar(Ref $data) : InstanceOf["Data::Object::Scalar"]

The Scalar function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) which wraps a
[Data::Object::Scalar](https://metacpan.org/pod/Data::Object::Scalar) object.

- Scalar example #1

        package main;

        my $scalar = Scalar;

- Scalar example #2

        package main;

        my $scalar = Scalar \*main;

## space

    Space(Str $data) : InstanceOf["Data::Object::Space"]

The Space function returns a [Data::Object::Space](https://metacpan.org/pod/Data::Object::Space) object.

- Space example #1

        package main;

        use Data::Object 'Space';

        my $space = Space 'Example Namespace';

## string

    String(Str $data) : InstanceOf["Data::Object::String"]

The String function returns a [Data::Object::Box](https://metacpan.org/pod/Data::Object::Box) which wraps a
[Data::Object::String](https://metacpan.org/pod/Data::Object::String) object.

- String example #1

        package main;

        my $string = String;

- String example #2

        package main;

        my $string = String 'abc';

## struct

    Struct(HashRef $data) : InstanceOf["Data::Object::Struct"]

The Struct function returns a [Data::Object::Struct](https://metacpan.org/pod/Data::Object::Struct) object.

- Struct example #1

        package main;

        use Data::Object 'Struct';

        my $struct = Struct;

- Struct example #2

        package main;

        my $struct = Struct {
          name => 'example',
          time => time
        };

## true

    True() : BooleanObject

The True function returns a [Data::Object::Boolean](https://metacpan.org/pod/Data::Object::Boolean) object representing a true
value.

- True example #1

        package main;

        my $true = True;

## undef

    Undef() : InstanceOf["Data::Object::Undef"]

The Undef function returns a [Data::Object::Undef](https://metacpan.org/pod/Data::Object::Undef) object representing the
_undefined_ value.

- Undef example #1

        package main;

        my $undef = Undef;

## vars

    Vars() : InstanceOf["Data::Object::Vars"]

The Vars function returns a [Data::Object::Vars](https://metacpan.org/pod/Data::Object::Vars) object representing the
available environment variables.

- Vars example #1

        package main;

        use Data::Object 'Vars';

        my $vars = Vars;

- Vars example #2

        package main;

        my $vars = Vars {
          user => 'USER'
        };

        # $vars->user; # $USER

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object/wiki)

[Project](https://github.com/iamalnewkirk/data-object)

[Initiatives](https://github.com/iamalnewkirk/data-object/projects)

[Milestones](https://github.com/iamalnewkirk/data-object/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object/issues)
