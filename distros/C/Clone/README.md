Clone - recursively copy Perl datatypes
=======================================

[![Build Status](https://travis-ci.org/garu/Clone.png?branch=master)](https://travis-ci.org/garu/Clone)
[![Coverage Status](https://coveralls.io/repos/garu/Clone/badge.png?branch=master)](https://coveralls.io/r/garu/Clone?branch=master)
[![CPAN version](https://badge.fury.io/pl/Clone.svg)](https://metacpan.org/pod/Clone)

This module provides a `clone()` method which makes recursive
copies of nested hash, array, scalar and reference types,
including tied variables and objects.

```perl
    use Clone 'clone';

    my $data = {
       set => [ 1 .. 50 ],
       foo => {
           answer => 42,
           object => SomeObject->new,
       },
    };

    my $cloned_data = clone($data);

    $cloned_data->{foo}{answer} = 1;
    print $cloned_data->{foo}{answer};  # '1'
    print $data->{foo}{answer};         # '42'
```

You can also add it to your class:

```perl
    package Foo;
    use parent 'Clone';
    sub new { bless {}, shift }

    package main;

    my $obj = Foo->new;
    my $copy = $obj->clone;
```

`clone()` takes a scalar argument and duplicates it. To duplicate lists,
arrays or hashes, pass them in by reference, e.g.

```perl
    my $copy = clone (\@array);

    # or

    my %copy = %{ clone (\%hash) };
```

See Also
--------

[Storable](https://metacpan.org/pod/Storable)'s `dclone()` is a flexible solution for cloning variables,
albeit slower for average-sized data structures. Simple
and naive benchmarks show that Clone is faster for data structures
with 3 or fewer levels, while `dclone()` can be faster for structures
4 or more levels deep.

COPYRIGHT
---------

Copyright 2001-2019 Ray Finch. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

AUTHOR
------

Ray Finch `<rdf@cpan.org>`

Breno G. de Oliveira `<garu@cpan.org>` and
Florian Ragwitz `<rafl@debian.org>` perform routine maintenance
releases since 2012.
