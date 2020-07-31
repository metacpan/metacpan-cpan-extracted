# NAME

Catalyst::Plugin::DetachIfNotModified - Short-circuit requests with If-Modified-Since headers

# VERSION

version v0.1.0

# SYNOPSIS

In your Catalyst class:

```perl
use Catalyst qw/
    DetachIfNotModified
  /;
```

In a controller method:

```perl
my $item = ...

$c->detach_if_not_modified_since( $item->timestamp );

# Do some CPU-intensive stuff or generate response body here.
```

# DESCRIPTION

This plugin will allow your [Catalyst](https://metacpan.org/pod/Catalyst) app to handle requests with
`If-Modified-Since` headers.

If the content of a web page has not been modified since a given date,
you can quickly bail out and avoid generating a web page that you do
not need to.

This can improve the performance of your website.

This should be used with [Plack::Middleware::ConditionalGET](https://metacpan.org/pod/Plack::Middleware::ConditionalGET).

# METHODS

## detach\_if\_not\_modified\_since

```
$c->detach_if_not_modified_since( $timestamp );
```

This sets the `Last-Modified` header in the response to the
`$timestamp`, and checks if the request contains a
`If-Modified-Since` header that not less than the timestamp.  If it
does, then it will set the response status code to `304` (Not
Modified) and detach.

The `$timestamp` may be a unix epoch, or an object with an `epoch`
method, such as a [DateTime](https://metacpan.org/pod/DateTime) object.

# CAVEATS

Be careful when aggregating a collection of objects into a single
timestamp, e.g. the maximum timestamp from a list.  If a member is
removed from that collection, then the maximum timestamp won't be
affected, and the result is that an outdated web page may be cached by
user agents.

# SEE ALSO

[Catalyst](https://metacpan.org/pod/Catalyst)

[Catalyst::Plugin::Cache::HTTP::Preempt](https://metacpan.org/pod/Catalyst::Plugin::Cache::HTTP::Preempt)

[Plack::Middleware::ConditionalGET](https://metacpan.org/pod/Plack::Middleware::ConditionalGET)

# SOURCE

The development version is on github at [https://github.com/robrwo/Catalyst-Plugin-DetachIfNotModified](https://github.com/robrwo/Catalyst-Plugin-DetachIfNotModified)
and may be cloned from [git://github.com/robrwo/Catalyst-Plugin-DetachIfNotModified.git](git://github.com/robrwo/Catalyst-Plugin-DetachIfNotModified.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Catalyst-Plugin-DetachIfNotModified/issues](https://github.com/robrwo/Catalyst-Plugin-DetachIfNotModified/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

This module is based on code created for Science Photo Library
[https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
