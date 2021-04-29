# NAME

Data::Enum - fast, immutable enumeration classes

# VERSION

version v0.2.0

# SYNOPSIS

```perl
use Data::Enum;

my $color = Data::Enum->new( qw[ red yellow blue green ] );

my $red = $color->new("red");

$red->is_red;    # "1"
$red->is_yellow; # "" (false)
$red->is_blue;   # "" (false)
$red->is_green;  # "" (false)

say $red;        # outputs "red"

$red eq $color->new("red"); # true

$red eq "red"; # true
```

# DESCRIPTION

This module will create enumerated constant classes with the following
properties:

- Any two classes with the same elements are equivalent.

    The following two classes are the _same_:

    ```perl
    my $one = Data::Enum->new( qw[ foo bar baz ] );
    my $two = Data::Enum->new( qw[ foo bar baz ] );
    ```

- All class instances are singletons.

    ```perl
    my $one = Data::Enum->new( qw[ foo bar baz ] );

    my $a = $one->new("foo")
    my $b = $one->new("foo");

    refaddr($a) == $refaddr($b); # they are the same thing
    ```

- Methods for checking values are fast.

    ```
    $a->is_foo; # constant time

    $a eq $b;   # compares refaddr
    ```

- Values are immutable (read-only).

This is done by creating a unique internal class name based on the
possible values.  Each value is actually a subclass of that class,
with the appropriate `is_` method returning a constant.

# METHODS

## new

```perl
my $class = Data::Enum->new( @values );
```

This creates a new anonymous class. Values can be instantiated with a
constructor:

```perl
my $instance = $class->new( $value );
```

Calling the constructor with an invalid value will throw an exception.

Each instance will have an `is_` method for each value.

Each instance stringifies to its value.

## values

```perl
my @values = $class->values;
```

Returns a list of valid values, stringified and sorted with duplicates
removed.

This was added in v0.2.0.

# SEE ALSO

[Class::Enum](https://metacpan.org/pod/Class::Enum)

[Object::Enum](https://metacpan.org/pod/Object::Enum)

[MooX::Enumeration](https://metacpan.org/pod/MooX::Enumeration)

[MooseX::Enumeration](https://metacpan.org/pod/MooseX::Enumeration)

[Type::Tiny::Enum](https://metacpan.org/pod/Type::Tiny::Enum)

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Data-Enum](https://github.com/robrwo/perl-Data-Enum)
and may be cloned from [git://github.com/robrwo/perl-Data-Enum.git](git://github.com/robrwo/perl-Data-Enum.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Data-Enum/issues](https://github.com/robrwo/perl-Data-Enum/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
