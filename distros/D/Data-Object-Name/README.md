# NAME

Data::Object::Name

# ABSTRACT

Name Class for Perl 5

# SYNOPSIS

    use Data::Object::Name;

    my $name = Data::Object::Name->new('FooBar/Baz');

# DESCRIPTION

This package provides methods for converting "name" strings.

# METHODS

This package implements the following methods:

## file

    file() : Str

The file method returns a file representation of the name.

- file example #1

        # given: synopsis

        my $file = $name->file; # foo_bar__baz

## format

    format(Str $method, Str $format) : Str

The format method calls the specified method passing the result to the core
["sprintf"](#sprintf) function with itself as an argument.

- format example #1

        # given: synopsis

        my $file = $name->format('file', '%s.t'); # foo_bar__baz.t

## label

    label() : Str

The label method returns a label (or constant) representation of the name.

- label example #1

        # given: synopsis

        my $label = $name->label; # FooBar_Baz

## lookslike\_a\_file

    lookslike_a_file() : Bool

The lookslike\_a\_file method returns truthy if its state resembles a filename.

- lookslike\_a\_file example #1

        # given: synopsis

        my $is_file = $name->lookslike_a_file; # falsey

## lookslike\_a\_label

    lookslike_a_label() : Bool

The lookslike\_a\_label method returns truthy if its state resembles a label (or
constant).

- lookslike\_a\_label example #1

        # given: synopsis

        my $is_label = $name->lookslike_a_label; # falsey

## lookslike\_a\_package

    lookslike_a_package() : Bool

The lookslike\_a\_package method returns truthy if its state resembles a package
name.

- lookslike\_a\_package example #1

        # given: synopsis

        my $is_package = $name->lookslike_a_package; # falsey

## lookslike\_a\_path

    lookslike_a_path() : Bool

The lookslike\_a\_path method returns truthy if its state resembles a file path.

- lookslike\_a\_path example #1

        # given: synopsis

        my $is_path = $name->lookslike_a_path; # truthy

## new

    new(Str $arg) : Object

The new method instantiates the class and returns an object.

- new example #1

        use Data::Object::Name;

        my $name = Data::Object::Name->new;

- new example #2

        use Data::Object::Name;

        my $name = Data::Object::Name->new('FooBar');

## package

    package() : Str

The package method returns a package name representation of the name given.

- package example #1

        # given: synopsis

        my $package = $name->package; # FooBar::Baz

## path

    path() : Str

The path method returns a path representation of the name.

- path example #1

        # given: synopsis

        my $path = $name->path; # FooBar/Baz

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-name/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-name/wiki)

[Project](https://github.com/iamalnewkirk/data-object-name)

[Initiatives](https://github.com/iamalnewkirk/data-object-name/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-name/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-name/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-name/issues)
