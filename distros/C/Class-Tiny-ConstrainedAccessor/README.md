# Class::Tiny::ConstrainedAccessor - Generate Class::Tiny accessors that apply type constraints

[![Appveyor Badge](https://ci.appveyor.com/api/projects/status/github/cxw42/class-tiny-constrainedaccessor?svg=true)](https://ci.appveyor.com/project/cxw42/class-tiny-constrainedaccessor)



[Class::Tiny](https://metacpan.org/pod/Class::Tiny) uses custom accessors if they are defined before the
`use Class::Tiny` statement in a package.  This module creates custom
accessors that behave as standard `Class::Tiny` accessors except that
they apply type constraints (`isa` relationships).  Type constraints
can come from [Type::Tiny](https://metacpan.org/pod/Type::Tiny), [MooseX::Types](https://metacpan.org/pod/MooseX::Types), [MooX::Types::MooseLike](https://metacpan.org/pod/MooX::Types::MooseLike),
[MouseX::Types](https://metacpan.org/pod/MouseX::Types), or [Specio](https://metacpan.org/pod/Specio).

Example of a class using this package:

    package SampleClass;
    use Scalar::Util qw(looks_like_number);

    use Type::Tiny;

    my $MediumInteger;
    BEGIN {
        # Create the type constraint
        $MediumInteger = Type::Tiny->new(
            name => 'MediumInteger',
            constraint => sub { looks_like_number($_) and $_ >= 10 and $_ < 20 }
        );
    }

    use Class::Tiny::ConstrainedAccessor {
        medint => $MediumInteger,           # create accessor sub medint()
        med_with_default => $MediumInteger,
    };

    # After using ConstrainedAccessor, actually define the class attributes.
    use Class::Tiny qw(medint regular), {
        med_with_default => 12,
    };

# SUBROUTINES

## import

Creates the accessors you have requested.  Basic usage:

    use Class::Tiny::ConstrainedAccessor
        name => constraint
        [, name => constraint ...]; # ... any number of name=>constraint pairs

This also creates a [BUILD()](https://metacpan.org/pod/Class::Tiny#BUILD) subroutine to check the
constructor parameters, if a `BUILD()` doesn't already exist.

If a `BUILD()` does exist (e.g., you said `use subs 'BUILD';`), this package
will create the same function, taking the same parameters as `BUILD()` would,
but call it `_check_all_constraints()`.   You can call this checker from your
own `BUILD()` if you want to.

# OPTIONS

To specify options, pass an **arrayref** as the first argument on the \`use\`
line.  This is to leave room for someday carrying attributes and constraints in
a hashref.  For example:

    use Class::Tiny::ConstrainedAccessor [ OPTION=>value ],
        name => constraint ...;

Valid options are:

- NOBUILD

    If `NOBUILD => 1` is given, the constructor-parameter-checker
    is created as `_check_all_constraints` regardless of whether `BUILD()`
    exists or not.  Example:

        package MyClass;
        use Class::Tiny::ConstrainedAccessor
            [NOBUILD => 1],
            foo => SomeConstraint;
        # Now $object->_check_all_constraints($args) exists, but not BUILD().

# AUTHORS

Created by Christopher White, `<cxwembedded at gmail.com>`.  Thanks to
Toby Inkster for code contributions.

# BUGS

Please report any bugs or feature requests through the GitHub Issues interface
at [https://github.com/cxw42/Class-Tiny-ConstrainedAccessor/issues](https://github.com/cxw42/Class-Tiny-ConstrainedAccessor/issues).  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Tiny::ConstrainedAccessor

You can also look for information at:

- GitHub (report bugs here)

    [https://github.com/cxw42/Class-Tiny-ConstrainedAccessor](https://github.com/cxw42/Class-Tiny-ConstrainedAccessor)

- Search CPAN

    [https://metacpan.org/release/Class-Tiny-ConstrainedAccessor](https://metacpan.org/release/Class-Tiny-ConstrainedAccessor)

# LICENSE

Copyright 2019 Christopher White.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Apache License (2.0). You may obtain a
copy of the full license at:

[https://www.apache.org/licenses/LICENSE-2.0](https://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
