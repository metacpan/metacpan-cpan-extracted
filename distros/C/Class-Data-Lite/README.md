# NAME

Class::Data::Lite - a minimalistic class accessors

# SYNOPSIS

    package MyPackage;
    use Class::Data::Lite (
        rw => {
            readwrite => 'rw',
        },
        ro => {
            readonly => 'ro',
        },
    );
    package main;
    print(MyPackage->readwrite); #=> rw

# DESCRIPTION

Class::Data::Lite is a minimalistic implement for class accessors.
There is no inheritance and fast.

# THE USE STATEMENT

The use statement (i.e. the `import` function) of the module takes a single
hash as an argument that specifies the types and the names of the properties.
Recognises the following keys.

- `rw` => (\\@name\_of\_the\_properties|\\%name\_of\_the\_properties\_and\_values)

    creates a read / write class accessor for the name of the properties passed
    through as an arrayref or hashref.

- `ro` => (\\@name\_of\_the\_properties|\\%name\_of\_the\_properties\_and\_values)

    creates a read-only class accessor for the name of the properties passed
    through as an arrayref or hashref.

# BENCHMARK

It is faster than Class::Data::Inheritance. See `eg/bench.pl`.

                                  Rate Class::Data::Inheritable    Class::Data::Lite
    Class::Data::Inheritable 2619253/s                       --                 -38%
    Class::Data::Lite        4191169/s                      60%                   --

# SEE ALSO

[Class::Accessor::Lite](https://metacpan.org/pod/Class::Accessor::Lite), [Class::Data::Inheritance](https://metacpan.org/pod/Class::Data::Inheritance)

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
