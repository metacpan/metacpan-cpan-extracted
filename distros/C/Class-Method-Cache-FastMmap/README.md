# NAME

Class::Method::Cache::FastMmap - Cache method results using Cache::FastMmap

# VERSION

version v0.3.2

# SYNOPSIS

```perl
package MyClass;

use Class::Method::Cache::FastMmap;

sub my_method {
  ...
}

cache 'my_method' => (
   serializer  => 'storable',
   expire_time => '1h',
);
```

# DESCRIPTION

This package allows you to easily cache the results of a method call
using [Cache::FastMmap](https://metacpan.org/pod/Cache::FastMmap).

# EXPORTS

## `cache`

```perl
cache $method => %options;
```

This wraps the `$method` with a function that caches the return value.

It assumes that the method returns a defined scalar value and that the
method arguments are serialisable.

The `%options` are as follows:

- `cache`

    is used to specify a different (shared) cache. You may use another
    caching class, so long as it provides `get` and `set` methods.

    Added v0.2.0.

- `key_cb`

    is used to provide a custom key-generation function.  If
    none is specified, then [Object::Signature](https://metacpan.org/pod/Object::Signature) is used.

    The function should expect a single argument with an array reference
    corresponding to the original method call parameters:

    ```perl
    $key_cb->( [ $self, @_ ] );
    ```

- `prefix`

    This is the prefix too prepend to the key. It defaults to the class
    and method name when the ["cache"](#cache) is specified, or an empty string
    otherwise.

    Added v0.2.0.

Remaining `%options` are passed to the constructor for
[Cache::FastMmap](https://metacpan.org/pod/Cache::FastMmap).

As of v0.3.0, you can import the `cache` method with a different
namme:

```perl
use Class::Method::Cache::FastMmap
   "cache" => { -as => "memoize" };

sub my_method {
  ...
}

memoize 'my_method' => (
   serializer  => 'storable',
   expire_time => '1h',
);
```

Undefined results are not cached. So if your method returns `undef`
on failure, then it never cache that result.

# SEE ALSO

[Cache::FastMmap](https://metacpan.org/pod/Cache::FastMmap)

[Object::Signature](https://metacpan.org/pod/Object::Signature)

# SOURCE

The development version is on github at [https://github.com/robrwo/Class-Method-Cache-FastMmap](https://github.com/robrwo/Class-Method-Cache-FastMmap)
and may be cloned from [git://github.com/robrwo/Class-Method-Cache-FastMmap.git](git://github.com/robrwo/Class-Method-Cache-FastMmap.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Class-Method-Cache-FastMmap/issues](https://github.com/robrwo/Class-Method-Cache-FastMmap/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some development of this module was sponsored by Science Photo Library
[https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
