[![Build Status](https://travis-ci.com/papix/Class-Accessor-Typed.svg?branch=master)](https://travis-ci.com/papix/Class-Accessor-Typed)
# NAME

Class::Accessor::Typed - Class::Accessor::Lite with Type

# SYNOPSIS

    package Synopsis;

    use Class::Accessor::Typed (
        rw => {
            baz => { isa => 'Str', default => 'string' },
        },
        ro => {
            foo => 'Str',
            bar => 'Int',
        },
        wo => {
            hoge => 'Int',
        },
        rw_lazy => {
            foo_lazy => 'Str',
        }
        ro_lazy => {
            bar_lazy => { isa => 'Int', builder => 'bar_lazy_builder' },
        }
    );

    sub _build_foo_lazy  { 'string' }
    sub bar_lazy_builder { 'string' }

# DESCRIPTION

Class::Accessor::Typed is variant of `Class::Accessor::Lite`. It supports argument validation like `Smart::Args`.

# THE USE STATEMENT

The use statement of the module takes a single hash.
An arguments specifies the read/write type (rw, ro, wo) and setting of properties.
Setting of property is defined by hash reference that specifies property name as key and property rule as value.

    use Class::Accessor::Typed (
        rw => { # read/write type
            baz => 'Int', # property name => property rule
        },
    );

- new => $true\_of\_false

    If value evaluates to false, the default constructor is not created.
    The other cases, Class::Accessor::Typed provides the default constructor automatically.

- rw => \\%name\_and\_option\_of\_the\_properties

    create a read / write accessor.

- ro => \\%name\_and\_option\_of\_the\_properties

    create a read-only accessor.

- wo => \\%name\_and\_option\_of\_the\_properties

    create a write-only accessor.

- rw\_lazy => \\%name\_and\_option\_of\_the\_properties

    create a read / write lazy accessor.

- ro\_lazy => \\%name\_and\_option\_of\_the\_properties

    create a read-only lazy accessor.

## PROPERTY RULE

Property rule can receive string of type name (e.g. `Int`) or hash reference (with `isa`/`does`, `default`, `optional` and `builder`).
`default` can only use on `rw`, `ro` and `wo`, and `builder` can only use on `rw_lazy` and `ro_lazy`.

# SEE ALSO

[Class::Accessor::Lite](https://metacpan.org/pod/Class%3A%3AAccessor%3A%3ALite)

[Smart::Args](https://metacpan.org/pod/Smart%3A%3AArgs)

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

papix <mail@papix.net>
