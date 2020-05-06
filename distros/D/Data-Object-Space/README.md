# NAME

Data::Object::Space

# ABSTRACT

Namespace Class for Perl 5

# SYNOPSIS

    package main;

    use Data::Object::Space;

    my $space = Data::Object::Space->new('foo/bar');

# DESCRIPTION

This package provides methods for parsing and manipulating package namespaces.

# INHERITS

This package inherits behaviors from:

[Data::Object::Name](https://metacpan.org/pod/Data%3A%3AObject%3A%3AName)

# LIBRARIES

This package uses type constraints from:

[Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard)

# METHODS

This package implements the following methods:

## append

    append(Str @args) : Object

The append method modifies the object by appending to the package namespace
parts.

- append example #1

        # given: synopsis

        $space->append('baz');

        # 'Foo/Bar/Baz'

- append example #2

        # given: synopsis

        $space->append('baz', 'bax');

        # $space->package;

        # 'Foo/Bar/Baz/Bax'

## array

    array(Str $arg1) : ArrayRef

The array method returns the value for the given package array variable name.

- array example #1

        # given: synopsis

        package Foo::Bar;

        our @handler = 'start';

        package main;

        $space->array('handler')

        # ['start']

## arrays

    arrays() : ArrayRef

The arrays method searches the package namespace for arrays and returns their
names.

- arrays example #1

        # given: synopsis

        package Foo::Bar;

        our @handler = 'start';
        our @initial = ('next', 'prev');

        package main;

        $space->arrays

        # ['handler', 'initial']

## base

    base() : Str

The base method returns the last segment of the package namespace parts.

- base example #1

        # given: synopsis

        $space->base

        # Bar

## bless

    bless(Any $arg1 = {}) : Object

The bless method blesses the given value into the package namespace and returns
an object. If no value is given, an empty hashref is used.

- bless example #1

        # given: synopsis

        package Foo::Bar;

        sub import;

        package main;

        $space->bless

        # bless({}, 'Foo::Bar')

- bless example #2

        # given: synopsis

        package Foo::Bar;

        sub import;

        package main;

        $space->bless({okay => 1})

        # bless({okay => 1}, 'Foo::Bar')

## build

    build(Any @args) : Object

The build method attempts to call `new` on the package namespace and if successful returns the resulting object.

- build example #1

        package Foo::Bar::Baz;

        sub new {
          bless {}, $_[0]
        }

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/bar/baz');

        $space->build

        # bless({}, 'Foo::Bar::Baz')

- build example #2

        package Foo::Bar::Bax;

        sub new {
          bless $_[1], $_[0]
        }

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/bar/bax');

        $space->build({okay => 1})

        # bless({okay => 1}, 'Foo::Bar::Bax')

## call

    call(Any @args) : Any

The call method attempts to call the given subroutine on the package namespace
and if successful returns the resulting value.

- call example #1

        # given: synopsis

        package Foo;

        sub import;

        sub start {
          'started'
        }

        package main;

        use Data::Object::Space;

        $space = Data::Object::Space->new('foo');

        $space->call('start')

        # started

## child

    child(Str $arg1) : Object

The child method returns a new [Data::Object::Space](https://metacpan.org/pod/Data%3A%3AObject%3A%3ASpace) object for the child
package namespace.

- child example #1

        # given: synopsis

        $space->child('baz');

        # $space->package;

        # Foo::Bar::Baz

## children

    children() : ArrayRef[Object]

The children method searches `%INC` and `@INC` and retuns a list of
[Data::Object::Space](https://metacpan.org/pod/Data%3A%3AObject%3A%3ASpace) objects for each child namespace found (one level deep).

- children example #1

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('c_p_a_n');

        $space->children

        # [
        #   'CPAN/Author',
        #   'CPAN/Bundle',
        #   'CPAN/CacheMgr',
        #   ...
        # ]

## cop

    cop(Any @args) : CodeRef

The cop method attempts to curry the given subroutine on the package namespace
and if successful returns a closure.

- cop example #1

        # given: synopsis

        package Foo::Bar;

        sub import;

        sub handler {
          [@_]
        }

        package main;

        use Data::Object::Space;

        $space = Data::Object::Space->new('foo/bar');

        $space->cop('handler', $space->bless)

        # sub { Foo::Bar::handler(..., @_) }

## destroy

    destroy() : Object

The destroy method attempts to wipe out a namespace and also remove it and its
children from `%INC`. **NOTE:** This can cause catastrophic failures if used
incorrectly.

- destroy example #1

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('data/dumper');

        $space->load; # Data/Dumper

        $space->destroy;

## eval

    eval(Str @args) : Any

The eval method takes a list of strings and evaluates them under the namespace
represented by the instance.

- eval example #1

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo');

        $space->eval('our $VERSION = 0.01');

## functions

    functions() : ArrayRef

The functions method searches the package namespace for functions and returns
their names.

- functions example #1

        package Foo::Functions;

        use routines;

        fun start() {
          1
        }

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/functions');

        $space->functions

        # ['start']

## hash

    hash(Str $arg1) : HashRef

The hash method returns the value for the given package hash variable name.

- hash example #1

        # given: synopsis

        package Foo::Bar;

        our %settings = (
          active => 1
        );

        package main;

        $space->hash('settings')

        # {active => 1}

## hashes

    hashes() : ArrayRef

The hashes method searches the package namespace for hashes and returns their
names.

- hashes example #1

        # given: synopsis

        package Foo::Bar;

        our %defaults = (
          active => 0
        );

        our %settings = (
          active => 1
        );

        package main;

        $space->hashes

        # ['defaults', 'settings']

## id

    id() : Str

The id method returns the fully-qualified package name as a label.

- id example #1

        # given: synopsis

        $space->id

        # Foo_Bar

## included

    included() : Str

The included method returns the path of the namespace if it exists in `%INC`.

- included example #1

        package main;

        my $space = Data::Object::Space->new('Data/Object/Space');

        $space->included;

        # lib/Data/Object/Space.pm

## inherits

    inherits() : ArrayRef

The inherits method returns the list of superclasses the target package is
derived from.

- inherits example #1

        package Bar;

        package main;

        my $space = Data::Object::Space->new('bar');

        $space->inherits

        # []

- inherits example #2

        package Foo;

        package Bar;

        use base 'Foo';

        package main;

        my $space = Data::Object::Space->new('bar');

        $space->inherits

        # ['Foo']

## load

    load() : Str

The load method checks whether the package namespace is already loaded and if
not attempts to load the package. If the package is not loaded and is not
loadable, this method will throw an exception using confess. If the package is
loadable, this method returns truthy with the package name. As a workaround for
packages that only exist in-memory, if the package contains a `new`, `with`,
`meta`, or `import` routine it will be recognized as having been loaded.

- load example #1

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('c_p_a_n');

        $space->load

        # CPAN

## loaded

    loaded() : Int

The loaded method checks whether the package namespace is already loaded
returns truthy or falsy.

- loaded example #1

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('data/dumper');

        $space->loaded;

        # 0

- loaded example #2

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('data/dumper');

        $space->load;

        $space->loaded;

        # 1

## locate

    locate() : Str

The locate method checks whether the package namespace is available in
`@INC`, i.e. on disk. This method returns the file if found or an empty
string.

- locate example #1

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo');

        $space->locate;

        # ''

- locate example #2

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('data/dumper');

        $space->locate;

        # /path/to/Data/Dumper.pm

## methods

    methods() : ArrayRef

The methods method searches the package namespace for methods and returns their
names.

- methods example #1

        package Foo::Methods;

        use routines;

        method start() {
          1
        }

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/methods');

        $space->methods

        # ['start']

## name

    name() : Str

The name method returns the fully-qualified package name.

- name example #1

        # given: synopsis

        $space->name

        # Foo::Bar

## parent

    parent() : Object

The parent method returns a new [Data::Object::Space](https://metacpan.org/pod/Data%3A%3AObject%3A%3ASpace) object for the parent
package namespace.

- parent example #1

        # given: synopsis

        $space->parent;

        # $space->package;

        # Foo

## parse

    parse() : ArrayRef

The parse method parses the string argument and returns an arrayref of package
namespace segments (parts).

- parse example #1

        my $space = Data::Object::Space->new('Foo::Bar');

        $space->parse;

        # ['Foo', 'Bar']

- parse example #2

        my $space = Data::Object::Space->new('Foo/Bar');

        $space->parse;

        # ['Foo', 'Bar']

- parse example #3

        my $space = Data::Object::Space->new('Foo\Bar');

        $space->parse;

        # ['Foo', 'Bar']

- parse example #4

        my $space = Data::Object::Space->new('foo-bar');

        $space->parse;

        # ['FooBar']

- parse example #5

        my $space = Data::Object::Space->new('foo_bar');

        $space->parse;

        # ['FooBar']

## parts

    parts() : ArrayRef

The parts method returns an arrayref of package namespace segments (parts).

- parts example #1

        my $space = Data::Object::Space->new('foo');

        $space->parts;

        # ['Foo']

- parts example #2

        my $space = Data::Object::Space->new('foo/bar');

        $space->parts;

        # ['Foo', 'Bar']

- parts example #3

        my $space = Data::Object::Space->new('foo_bar');

        $space->parts;

        # ['FooBar']

## prepend

    prepend(Str @args) : Object

The prepend method modifies the object by prepending to the package namespace
parts.

- prepend example #1

        # given: synopsis

        $space->prepend('etc');

        # 'Etc/Foo/Bar'

- prepend example #2

        # given: synopsis

        $space->prepend('etc', 'tmp');

        # 'Etc/Tmp/Foo/Bar'

## rebase

    rebase(Str @args) : Object

The rebase method returns an object by prepending the package namespace
specified to the base of the current object's namespace.

- rebase example #1

        # given: synopsis

        $space->rebase('zoo');

        # Zoo/Bar

## root

    root() : Str

The root method returns the root package namespace segments (parts). Sometimes
separating the `root` from the `parts` helps identify how subsequent child
objects were derived.

- root example #1

        # given: synopsis

        $space->root

        # Foo

## routine

    routine(Str $arg1) : CodeRef

The routine method returns the subroutine reference for the given subroutine
name.

- routine example #1

        package Foo;

        sub cont {
          [@_]
        }

        sub abort {
          [@_]
        }

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo');

        $space->routine('cont')

        # sub { ... }

## routines

    routines() : ArrayRef

The routines method searches the package namespace for routines and returns
their names.

- routines example #1

        package Foo::Routines;

        sub start {
          1
        }

        sub abort {
          1
        }

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/routines');

        $space->routines

        # ['start', 'abort']

## scalar

    scalar(Str $arg1) : Any

The scalar method returns the value for the given package scalar variable name.

- scalar example #1

        # given: synopsis

        package Foo::Bar;

        our $root = '/path/to/file';

        package main;

        $space->scalar('root')

        # /path/to/file

## scalars

    scalars() : ArrayRef

The scalars method searches the package namespace for scalars and returns their
names.

- scalars example #1

        # given: synopsis

        package Foo::Bar;

        our $root = 'root';
        our $base = 'path/to';
        our $file = 'file';

        package main;

        $space->scalars

        # ['root', 'base', 'file']

## sibling

    sibling(Str $arg1) : Object

The sibling method returns a new [Data::Object::Space](https://metacpan.org/pod/Data%3A%3AObject%3A%3ASpace) object for the sibling
package namespace.

- sibling example #1

        # given: synopsis

        $space->sibling('baz')

        # Foo::Baz

## siblings

    siblings() : ArrayRef[Object]

The siblings method searches `%INC` and `@INC` and retuns a list of
[Data::Object::Space](https://metacpan.org/pod/Data%3A%3AObject%3A%3ASpace) objects for each sibling namespace found (one level
deep).

- siblings example #1

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('encode/m_i_m_e');

        $space->siblings

        # [
        #   'Encode/Alias',
        #   'Encode/Config'
        #   ...
        # ]

## used

    used() : Str

The used method searches `%INC` for the package namespace and if found returns
the filepath and complete filepath for the loaded package, otherwise returns
falsy with an empty string.

- used example #1

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/xyz');

        $space->used

        # ''

- used example #2

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('c_p_a_n');

        $space->load;
        $space->used

        # 'CPAN'

- used example #3

        package Foo::Bar;

        sub import;

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/bar');

        $space->used

        # 'Foo/Bar'

## variables

    variables() : ArrayRef[Tuple[Str, ArrayRef]]

The variables method searches the package namespace for variables and returns
their names.

- variables example #1

        package Etc;

        our $init = 0;
        our $func = 1;

        our @does = (1..4);
        our %sets = (1..4);

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('etc');

        $space->variables

        # [
        #   ['arrays', ['does']],
        #   ['hashes', ['sets']],
        #   ['scalars', ['func', 'init']],
        # ]

## version

    version() : Maybe[Str]

The version method returns the `VERSION` declared on the target package, if
any.

- version example #1

        package Foo::Boo;

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/boo');

        $space->version

        # undef

- version example #2

        package Foo::Boo;

        our $VERSION = 0.01;

        package main;

        use Data::Object::Space;

        my $space = Data::Object::Space->new('foo/boo');

        $space->version

        # '0.01'

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-space/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-space/wiki)

[Project](https://github.com/iamalnewkirk/data-object-space)

[Initiatives](https://github.com/iamalnewkirk/data-object-space/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-space/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-space/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-space/issues)
