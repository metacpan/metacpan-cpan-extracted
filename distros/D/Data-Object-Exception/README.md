# NAME

Data::Object::Exception

# ABSTRACT

Exception Class for Perl 5

# SYNOPSIS

    use Data::Object::Exception;

    my $exception = Data::Object::Exception->new;

    # $exception->throw

# DESCRIPTION

This package provides functionality for creating, throwing, and introspecting
exception objects.

# SCENARIOS

This package supports the following scenarios:

## args-1

    use Data::Object::Exception;

    my $exception = Data::Object::Exception->new('Oops!');

    # $exception->throw

The package allows objects to be instantiated with a single argument.

## args-kv

    use Data::Object::Exception;

    my $exception = Data::Object::Exception->new(message => 'Oops!');

    # $exception->throw

The package allows objects to be instantiated with key-value arguments.

# ATTRIBUTES

This package has the following attributes:

## context

    context(Any)

This attribute is read-only, accepts `(Any)` values, and is optional.

## id

    id(Str)

This attribute is read-only, accepts `(Str)` values, and is optional.

## message

    message(Str)

This attribute is read-only, accepts `(Str)` values, and is optional.

# METHODS

This package implements the following methods:

## explain

    explain() : Str

The explain method returns an error message with stack trace.

- explain example #1

        use Data::Object::Exception;

        my $exception = Data::Object::Exception->new('Oops!');

        $exception->explain

## throw

    throw(Tuple[Str, Str] | Str $message, Any $context, Maybe[Number] $offset) : Any

The throw method throws an error with message (and optionally, an ID).

- throw example #1

        use Data::Object::Exception;

        my $exception = Data::Object::Exception->new;

        $exception->throw('Oops!')

- throw example #2

        use Data::Object::Exception;

        my $exception = Data::Object::Exception->new('Oops!');

        $exception->throw

- throw example #3

        use Data::Object::Exception;

        my $exception = Data::Object::Exception->new;

        $exception->throw(['E001', 'Oops!'])

## trace

    trace(Int $offset, $Int $limit) : Object

The trace method compiles a stack trace and returns the object. By default it
skips the first frame.

- trace example #1

        use Data::Object::Exception;

        my $exception = Data::Object::Exception->new('Oops!');

        $exception->trace(0)

- trace example #2

        use Data::Object::Exception;

        my $exception = Data::Object::Exception->new('Oops!');

        $exception->trace(1)

- trace example #3

        use Data::Object::Exception;

        my $exception = Data::Object::Exception->new('Oops!');

        $exception->trace(0,1)

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-exception/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-exception/wiki)

[Project](https://github.com/iamalnewkirk/data-object-exception)

[Initiatives](https://github.com/iamalnewkirk/data-object-exception/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-exception/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-exception/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-exception/issues)
