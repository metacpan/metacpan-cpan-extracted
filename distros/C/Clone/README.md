Clone - recursively copy Perl datatypes
=======================================

[![Build Status](https://github.com/garu/Clone/actions/workflows/test.yml/badge.svg)](https://github.com/garu/Clone/actions/workflows/test.yml)
[![CPAN version](https://badge.fury.io/pl/Clone.svg)](https://metacpan.org/pod/Clone)

## Synopsis

## Synopsis

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

## Description

This module provides a `clone()` method which makes recursive
copies of nested hash, array, scalar and reference types,
including tied variables and objects.

`clone()` takes a scalar argument and duplicates it. To duplicate lists,
arrays or hashes, pass them in by reference, e.g.

```perl
my $copy = clone (\@array);

# or

my %copy = %{ clone (\%hash) };
```

## Installation

From CPAN:

```bash
    cpanm Clone
```

From source:

```bash
    perl Makefile.PL
    make
    make test
    make install
```

## Examples

### Cloning Blessed Objects

```perl
    package Person;
    sub new {
        my ($class, $name) = @_;
        bless { name => $name, friends => [] }, $class;
    }

    package main;
    use Clone 'clone';

    my $person = Person->new('Alice');
    my $clone = clone($person);

    # $clone is a separate object with the same data
    push @{$person->{friends}}, 'Bob';
    print scalar @{$clone->{friends}};  # 0
```

### Handling Circular References

Clone properly handles circular references, preventing infinite loops:

```perl
    my $a = { name => 'A' };
    my $b = { name => 'B', ref => $a };
    $a->{ref} = $b;  # circular reference

    my $clone = clone($a);
    # Circular structure is preserved in the clone
```

### Cloning Weakened References

```perl
    use Scalar::Util 'weaken';

    my $obj = { data => 'important' };
    my $container = { strong => $obj, weak => $obj };
    weaken($container->{weak});

    my $clone = clone($container);
    # Both strong and weak references are preserved correctly
```

### Cloning Tied Variables

```perl
    use Tie::Hash;
    tie my %hash, 'Tie::StdHash';
    %hash = (a => 1, b => 2);

    my $clone = clone(\%hash);
    # The tied behavior is preserved in the clone
```

## Limitations

* **Maximum Recursion Depth**: Clone supports structures up to 32,000 levels deep. Deeper structures will cause the clone operation to fail with an error. This limit prevents stack overflow and ensures safe operation.

* **Filehandles and IO Objects**: Filehandles and IO objects are cloned, but the underlying file descriptor is shared. Both the original and cloned filehandle will refer to the same file position. For DBI database handles and similar objects, Clone attempts to handle them safely, but behavior may vary depending on the object type.

* **Code References**: Code references (subroutines) are cloned by reference, not by value. The cloned coderef points to the same subroutine as the original.

* **Thread Safety**: Clone is not explicitly thread-safe. Use appropriate synchronization when cloning data structures across threads.

## Performance

Clone is implemented in C using Perl's XS interface, making it very fast for most use cases.

**When to use Clone:**

Clone is optimized for speed and works best with:
* Shallow to medium-depth structures (3 levels or fewer)
* Data structures that need fast cloning in hot code paths
* Structures containing blessed objects and tied variables

**When to use Storable::dclone:**

[Storable](https://metacpan.org/pod/Storable)'s `dclone()` may be faster for:
* Very deep structures (4+ levels)
* When you need serialization features

Benchmarking your specific use case is recommended for performance-critical applications.

## Caveats

* **Cloned objects are deep copies**: Changes to the clone do not affect the original, and vice versa. This includes nested references and objects.

* **Object internals**: While Clone handles most blessed objects correctly, objects with XS components or complex internal state may not clone as expected. Test thoroughly with your specific object types.

* **Memory usage**: Cloning large data structures creates a complete copy in memory. Ensure you have sufficient memory available.

## Testing

Run the test suite:

```bash
    make test
```

Or with verbose output:

```bash
    prove -lv t/
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository on [GitHub](https://github.com/garu/Clone)
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

## See Also

[Storable](https://metacpan.org/pod/Storable)'s `dclone()` is a flexible solution for cloning variables,
albeit slower for average-sized data structures. Simple
and naive benchmarks show that Clone is faster for data structures
with 3 or fewer levels, while `dclone()` can be faster for structures
4 or more levels deep.

Other modules that may be of interest:

* [Clone::PP](https://metacpan.org/pod/Clone::PP) - Pure Perl implementation of Clone
* [Scalar::Util](https://metacpan.org/pod/Scalar::Util) - For `weaken()` and other scalar utilities
* [Data::Dumper](https://metacpan.org/pod/Data::Dumper) - For debugging and inspecting data structures

## Support

* **Bug Reports and Feature Requests**: Please report bugs on [GitHub Issues](https://github.com/garu/Clone/issues)
* **Source Code**: Available on [GitHub](https://github.com/garu/Clone)

COPYRIGHT
---------

Copyright 2001-2026 Ray Finch. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

## Author

Ray Finch `<rdf@cpan.org>`

Breno G. de Oliveira `<garu@cpan.org>`,
Nicolas Rochelemagne `<atoomic@cpan.org>` and
Florian Ragwitz `<rafl@debian.org>` perform routine maintenance
releases since 2012.
