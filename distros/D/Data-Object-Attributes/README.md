# NAME

Data::Object::Attributes

# ABSTRACT

Attribute Builder for Perl 5

# SYNOPSIS

    package Example;

    use Moo;

    use Data::Object::Attributes;

    has 'data';

    package main;

    my $example = Example->new;

# DESCRIPTION

This package provides options for defining class attributes. Specifically, this
package wraps the `has` attribute keyword and adds shortcuts and enhancements.
If no directives are specified, the attribute is declared as `read-write` and
`optional`.

# SCENARIOS

This package supports the following scenarios:

## has-bld

    package Example::HasBld;

    use Moo;
    use routines;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      bld => 1
    );

    method _build_data() {

      return time;
    }

    package main;

    my $example = Example::HasBld->new;

This package supports the `bld` and `builder` directives, expects a coderef
and builds the attribute value if it wasn't provided to the constructor. See
the [Moo](https://metacpan.org/pod/Moo) documentation for more details.

## has-clr

    package Example::HasClr;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      clr => 1
    );

    package main;

    my $example = Example::HasClr->new(data => time);

    # $example->clear_data;

This package supports the `clr` and `clearer` directives expects a coderef and
generates a clearer method. See the [Moo](https://metacpan.org/pod/Moo) documentation for more details.

## has-crc

    package Example::HasCrc;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      crc => fun($arg){'0'}
    );

    package main;

    my $example = Example::HasCrc->new(data => time);

This package supports the `crc` and `coerce` directives denotes whether an
attribute's value should be automatically coerced. See the [Moo](https://metacpan.org/pod/Moo) documentation
for more details.

## has-def

    package Example::HasDef;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      def => '0'
    );

    package main;

    my $example = Example::HasDef->new;

This package supports the `def` and `default` directives expects a coderef and
is used to build a default value if one is not provided to the constructor. See
the [Moo](https://metacpan.org/pod/Moo) documentation for more details.

## has-hnd

    package Example::Time;

    use Moo;
    use routines;

    method maketime() {

      return time;
    }

    package Example::HasHnd;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      hnd => ['maketime']
    );

    package main;

    my $example = Example::HasHnd->new(data => Example::Time->new);

This package supports the `hnd` and `handles` directives denotes the methods
created on the object which dispatch to methods available on the attribute's
object. See the [Moo](https://metacpan.org/pod/Moo) documentation for more details.

## has-is

    package Example::HasIs;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro'
    );

    package main;

    my $example = Example::HasIs->new(data => time);

This package supports the `is` directive, used to denote whether the attribute
is read-only or read-write. See the [Moo](https://metacpan.org/pod/Moo) documentation for more details.

## has-isa

    package Example::HasIsa;

    use Moo;
    use registry;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      isa => 'Str' # e.g. Types::Standard::Str
    );

    package main;

    my $example = Example::HasIsa->new(data => time);

This package supports the `isa` directive, used to define the type constraint
to validate the attribute against. See the [Moo](https://metacpan.org/pod/Moo) documentation for more
details.

## has-lzy

    package Example::HasLzy;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      def => fun(){time},
      lzy => 1
    );

    package main;

    my $example = Example::HasLzy->new;

This package supports the `lzy` and `lazy` directives denotes whether the
attribute will be constructed on-demand, or on-construction. See the [Moo](https://metacpan.org/pod/Moo)
documentation for more details.

## has-mod

    package Example::Has;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'rw',
      opt => 1
    );

    package Example::HasMod;

    use Moo;

    use Data::Object::Attributes;

    extends 'Example::Has';

    has data => (
      is => 'ro',
      req => 1,
      mod => 1
    );

    package main;

    my $example = Example::HasMod->new;

This package supports the `mod` and `modify` directives denotes whether a
pre-existing attribute's definition is being modified. This ability is not
supported by the [Moo](https://metacpan.org/pod/Moo) object superclass.

## has-new

    package Example::HasNew;

    use Moo;
    use routines;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      new => 1
    );

    fun new_data($self) {

      return time;
    }

    package main;

    my $example = Example::HasNew->new(data => time);

This package supports the `new` directive, if truthy, denotes that the
attribute will be constructed on-demand, i.e. is lazy, with a builder named
new\_{attribute}. This ability is not supported by the [Moo](https://metacpan.org/pod/Moo) object superclass.

## has-opt

    package Example::HasOpt;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      opt => 1
    );

    package main;

    my $example = Example::HasOpt->new(data => time);

This package supports the `opt` and `optional` directives, used to denote if
an attribute is optional or required. See the [Moo](https://metacpan.org/pod/Moo) documentation for more
details.

## has-pre

    package Example::HasPre;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      pre => 1
    );

    package main;

    my $example = Example::HasPre->new(data => time);

This package supports the `pre` and `predicate` directives expects a coderef
and generates a method for checking the existance of the attribute. See the
[Moo](https://metacpan.org/pod/Moo) documentation for more details.

## has-rdr

    package Example::HasRdr;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      rdr => 'get_data'
    );

    package main;

    my $example = Example::HasRdr->new(data => time);

This package supports the `rdr` and `reader` directives denotes the name of
the method to be used to "read" and return the attribute's value. See the
[Moo](https://metacpan.org/pod/Moo) documentation for more details.

## has-req

    package Example::HasReq;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      req => 1 # required
    );

    package main;

    my $example = Example::HasReq->new(data => time);

This package supports the `req` and `required` directives, used to denote if
an attribute is required or optional. See the [Moo](https://metacpan.org/pod/Moo) documentation for more
details.

## has-tgr

    package Example::HasTgr;

    use Moo;
    use routines;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      tgr => 1
    );

    method _trigger_data() {
      $self->{triggered} = 1;

      return $self;
    }

    package main;

    my $example = Example::HasTgr->new(data => time);

This package supports the `tgr` and `trigger` directives expects a coderef and
is executed whenever the attribute's value is changed. See the [Moo](https://metacpan.org/pod/Moo)
documentation for more details.

## has-use

    package Example::HasUse;

    use Moo;
    use routines;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      use => ['service', 'time']
    );

    method service($type, @args) {
      $self->{serviced} = 1;

      return time if $type eq 'time';
    }

    package main;

    my $example = Example::HasUse->new;

This package supports the `use` directive denotes that the attribute will be
constructed on-demand, i.e. is lazy, using a custom builder meant to perform
service construction. This directive exists to provide a simple dependency
injection mechanism for class attributes. This ability is not supported by the
[Moo](https://metacpan.org/pod/Moo) object superclass.

## has-wkr

    package Example::HasWkr;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      wkr => 1
    );

    package main;

    my $data = do {
      my ($a, $b);

      $a = { time => time };
      $b = { time => $a };

      $a->{time} = $b;
      $a
    };

    my $example = Example::HasWkr->new(data => $data);

This package supports the `wkr` and `weak_ref` directives is used to denote if
the attribute's value should be weakened. See the [Moo](https://metacpan.org/pod/Moo) documentation for more
details.

## has-wrt

    package Example::HasWrt;

    use Moo;

    use Data::Object::Attributes;

    has data => (
      is => 'ro',
      wrt => 'set_data'
    );

    package main;

    my $example = Example::HasWrt->new;

This package supports the `wrt` and `writer` directives denotes the name of
the method to be used to "write" and return the attribute's value. See the
[Moo](https://metacpan.org/pod/Moo) documentation for more details.

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-attributes/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-attributes/wiki)

[Project](https://github.com/iamalnewkirk/data-object-attributes)

[Initiatives](https://github.com/iamalnewkirk/data-object-attributes/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-attributes/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-attributes/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-attributes/issues)
