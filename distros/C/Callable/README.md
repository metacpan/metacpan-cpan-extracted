# DISCLAIMER

Sorry for my English ...

# NAME

Callable - make different things callable

# SYNOPSIS

    my $db = DBI->connect( ... );
    my $router = My::Router->new(
        # use subroutine as handler
        '/' => Callable->(
            sub { my ($db, $request) = @_; ... },

            # inject default arguments to handler
            $db
        ),

        # use subroutine by name as handler
        '/profile' => Callable->new(
            # call handler as package method
            'Controller::Profile->home',

            # inject default arguments to handler
            db => $db,
            authenticated_only => 1
        ),

        # create class instance and use it as handler
        '/admin' => Callable->new(
            [
                # class_name => method
                'Controller::Admin' => 'home',

                # inject arguments to constructor
                db => $db
            ],

            # inject default arguments to handler
            restrictions => {role => 'admin'}
        ),
    );

    my $handler = $router->match($ENV{REQUEST_URI});

    # send additional arguments when calling handler
    my $response = $handler->(Request->new(%ENV));
    print $response->dump();

# DESCRIPTION

Callable is a simple wrapper for make subroutines from different sources.
Can be used in applications with configurable callback maps (e.g. website router config).
Inspired by PHP's [callable](https://www.php.net/manual/ru/language.types.callable.php)

# METHODS

## new($source\[, @default\_args\])

Create instance. Arguments:

- $source

    See ["SOURCES"](#sources)

- @default\_args

    Default arguments that will be sent to handler

        my $hello = Callable->new(sub { join ', ', @_; }, 'Hello');
        print $hello->('World'); # Hello, World
        print $hello->('Bro'); # Hello, Bro
        print "$hello, World"; # Hello, World

## overload '&{}'

Callable instance can be called like a subroutine reference:

    my $foo = Callable->new( ... );
    my $result = $foo->();

## overload '""'

Callable instance can be interpolated:

    my $foo = Callable->new( ... );
    my $result = "Foo: $foo."; # same as 'Foo: ' . $foo->() . '.'

# SOURCES

## subroutine reference

    my $foo = Callable->new(sub { ... });

## subroutine name

    my $foo = Callable->new('foo::bar');

Finds subroutine reference by it's name (`\&{$name}`). Name can be:
Fully-qualified (`Module::Name::sub_name`) names used as is,
not qualified names (`sub_name`) will be prefixed with package, where
callable was called from (see [caller](https://metacpan.org/pod/caller)):

    {
        package Foo;
        sub foo { 'Foo' }
        sub bar { Callable->new('Foo::foo') }
        sub baz { Callable->new('foo') }
    }

    package main;

    # ok, fully-qualified name 'Foo::foo', subroutine found
    print Foo::bar->();

    # not ok, 'foo' has no package name, so it will be interpreted as 'main::foo'
    print Foo::baz->();

## package method

Same as ["subroutine name"](#subroutine-name), but with `->` before subroutine name:

    # Fully-qualified
    my $foo = Callable->new('Module::Name->sub_name');

    # Not qualified
    my $foo = Callable->new('->sub_name');

## object method

    my $obj = My::Class->new( ... );
    my $foo = Callable->new([$obj => 'method_name']);

## class and method

    my $foo = Callable->new(['My::Class' => 'method_name']);

`$foo->()` creates `My::Class` instance and calls `->metod_name`.

Constructor name can be specified:

    my $foo = Callable->new(['My::Class->constructor_name' => 'method_name']);

`$Callable::DEFAULT_CLASS_CONSTRUCTOR` is used when no constructor name
given (`new` by default)

## callable

Callable instance can be cloned from another callable instance:

    my $source = Callable->new(sub { ... });
    my $foo = Callable->new($source);

Usable for re-create class instance (["class and method"](#class-and-method)) and/or for resetting
default ["Arguments"](#arguments)

# ARGUMENTS

Send arguments when calling:

    my $foo = Callable->new(sub { join ',', @_ });
    print $foo->(qw(Hello , World)); # prints Hello,World

Send default arguments when create instance:

    my $foo = Callable->new(sub { join ',', @_ }, 'Hello');
    print $foo->(qw(, World)); # prints Hello,World
    print $foo->(qw(, Bro)); # prints Hello,Bro

Send arguments to class constructor:

    {
        package My::Class;
        sub new {
            my $class = shift;
            return bless \@_, $class;
        }

        sub foo {
            my $self = shift;
            return join ' ', @{$self}, @_;
        }
    }

    my $foo = Callable->new(['My::Class', 'foo', 'Hello'], ',');
    print $foo->('World'); # prints Hello , World
    print $foo->('Bro'); # prints Hello , Bro

# LICENSE

Copyright (C) Al Tom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Al Tom <al-tom.ru@yandex.ru>
