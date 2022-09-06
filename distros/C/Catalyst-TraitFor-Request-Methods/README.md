# NAME

Catalyst::TraitFor::Request::Methods - Add enumerated methods for HTTP requests

# VERSION

version v0.4.0

# SYNOPSIS

In the [Catalyst](https://metacpan.org/pod/Catalyst) class

```perl
__PACKAGE__->config(
  request_class_traits => [
      'Methods'
  ]
);
```

In any code that uses a [Catalyst::Request](https://metacpan.org/pod/Catalyst%3A%3ARequest), e.g.

```
if ($c->request->is_post) {
    ...
}
```

# DESCRIPTION

This trait adds enumerated methods from RFC 7231 and RFC 5789 for
checking the HTTP request method.

Using these methods is a less error-prone alternative to checking a
case-sensitive string with the method name.

In other words, you can use

```
$c->request->is_get
```

instead of

```
$c->request->method eq "GET"
```

The methods are implemented as lazy read-only attributes.

# METHODS

## is\_get

The request method is `GET`.

## is\_head

The request method is `HEAD`.

## is\_post

The request method is `POST`.

## is\_put

The request method is `PUT`.

## is\_delete

The request method is `DELETE`.

## is\_connect

The request method is `CONNECT`.

## is\_options

The request method is `OPTIONS`.

## is\_trace

The request method is `TRACE`.

## is\_patch

The request method is `PATCH`.

## is\_unrecognized\_method

The request method is not recognized.

# SEE ALSO

[Catalyst::Request](https://metacpan.org/pod/Catalyst%3A%3ARequest)

# SOURCE

The development version is on github at [https://github.com/robrwo/Catalyst-TraitFor-Request-Methods-](https://github.com/robrwo/Catalyst-TraitFor-Request-Methods-)
and may be cloned from [git://github.com/robrwo/Catalyst-TraitFor-Request-Methods-.git](git://github.com/robrwo/Catalyst-TraitFor-Request-Methods-.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Catalyst-TraitFor-Request-Methods-/issues](https://github.com/robrwo/Catalyst-TraitFor-Request-Methods-/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2022 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
