[![Build Status](https://travis-ci.org/pokutuna/p5-Class-Enumemon.svg?branch=master)](https://travis-ci.org/pokutuna/p5-Class-Enumemon)
# NAME

Class::Enumemon - enum-like class generator

# SYNOPSIS

    package IdolType;
    use Class::Enumemon (
        values => 1,
        getter => 1,
        indexer => {
            by_id     => 'id',
            from_type => 'type',
        },
        {
            id   => 1,
            type => 'cute',
        },
        {
            id   => 2,
            type => 'cool',
        },
        {
            id   => 3,
            type => 'passion',
        },
    );

    1;

    package My::Pkg;
    use IdolType;

    # `values`: defines a method for getting all values
    IdolType->values; #=> [ bless({ id => 1, type => 'cute' }, 'IdolType'), ... ]

    # `indexer`: defines indexer methods to package
    my $cu = IdolType->by_id(1); #=> bless({ id => 1, type => 'cute' }, 'IdolType')
    IdonType->from_type('cool'); #=> bless({ id => 2, type => 'cool' }, 'IdolType')
    IdonType->values->[2];       #=> bless({ id => 3, type => 'passion' }, 'IdolType')

    # `getter`: defines getter methods to instance
    $cu->id;   #=> 1
    $cu->type; #=> 'cute'

    # `local`: makes a guard object for overriding its data lexically
    {
        my $guard = IdolType->local(
            {
                id   => 1,
                type => 'vocal',
            },
            {
                id   => 2,
                type => 'dance',
            },
            {
                id   => 3,
                type => 'visual',
            },
        );

        IdolType->by_id(1)           #=> bless({ id => 1, type => 'vocal' }, 'IdolType')
        IdolType->from_type('dance') #=> bless({ id => 1, type => 'dance' }, 'IdolType')
        IdolType->from_type('cute')  #=> undef
    }

    IdolType->from_type('cute') #=> bless({ id => 1, type => 'cute' }, 'IdolType')

# DESCRIPTION

Class::Enumemon generate enum-like classes with typical methods that are getter for all, indexer, accessor and guard generator.
An instance fetched from package is always same reference with another.

# LICENSE

Copyright (C) pokutuna.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHORS

pokutuna (POKUDA Tunahiko) &lt;popopopopokutuna@gmail.com>

nanto\_vi (TOYAMA Nao) &lt;nanto@moon.email.ne.jp>

mechairoi (TSUJIKAWA Takaya) &lt;ttsujikawa@gmail.com>

# SEE ALSO

[https://github.com/mechairoi/Class-Enum](https://github.com/mechairoi/Class-Enum)
