[![Actions Status](https://github.com/kfly8/p5-Boundary/workflows/test/badge.svg)](https://github.com/kfly8/p5-Boundary/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Boundary/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Boundary?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Boundary.svg)](https://metacpan.org/release/Boundary)
# NAME

Boundary - declare interface package

# SYNOPSIS

Declare interface package `IFoo`:

```perl
package IFoo {
    use Boundary;

    requires qw(hello world);
}
```

Implements the interface package `IFoo`:

```perl
package Foo {
    use Boundary::Impl qw(IFoo);

    sub hello { ... }
    sub world { ... }
}
```

Use the type `ImplOf`:

```perl
use Boundary::Types -types;
use Foo;

my $type = ImplOf['IFoo'];
my $foo = Foo->new; # implements of IFoo
$type->check($foo); # pass!
```

# DESCRIPTION

This module provides a interface.
`Boundary` declares abstract functions without implementation and defines an interface package.
`Bounary::Impl` checks if the abstract functions are implemented at **compile time**.

The difference with Role is that the implementation cannot be reused.
[namespace::allclean](https://metacpan.org/pod/namespace%3A%3Aallclean) prevents the reuse of the implementation.

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly8@cpan.org>
