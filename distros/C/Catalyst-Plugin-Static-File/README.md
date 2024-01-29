# NAME

Catalyst::Plugin::Static::File - Serve a specific static file

# VERSION

version v0.2.2

# SYNOPSIS

In your Catalyst class:

```perl
use Catalyst qw/
    Static::File
  /;
```

In a controller method:

```
$c->serve_static_file( $absolute_path, $type );
```

# DESCRIPTION

This plugin provides a simple method for your [Catalyst](https://metacpan.org/pod/Catalyst) app to send a specific static file.

Unlike [Catalyst::Plugin::Static::Simple](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3AStatic%3A%3ASimple),

- It only supports serving a single file, not a directory of static files. Use [Plack::Middleware::Static](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3AStatic) if you want to
serve multiple files.
- It assumes that you know what you're doing. If the file does not exist, it will throw an fatal error.
- It uses [Plack::MIME](https://metacpan.org/pod/Plack%3A%3AMIME) to identify the content type, but you can override that.
- It adds a file path to the file handle, plays nicely with [Plack::Middleware::XSendfile](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3AXSendfile) and [Plack::Middleware::ETag](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3AETag).
- It does not log anything.

# METHODS

## serve\_static\_file

```
$c->serve_static_file( $absolute_path, $type );
```

This serves the file in `$absolute_path`, with the `$type` content type.

If the `$type` is omitted, it will guess the type using the filename.

It will also set the `Last-Modified` and `Content-Length` headers.

It returns a true value on success.

If you want to use conditional requests, use [Plack::Middleware::ConditionalGET](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3AConditionalGET).

# SECURITY

The [serve\_static\_file](https://metacpan.org/pod/serve_static_file) method does not validate the file that is passed to it.

You should ensure that arbitrary filenames are not passed to it. You should strictly validate any external data that is
used for generating the filename.

# SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten years.

# SEE ALSO

[Catalyst](https://metacpan.org/pod/Catalyst)

[Catalyst::Plugin::Static::Simple](https://metacpan.org/pod/Catalyst%3A%3APlugin%3A%3AStatic%3A%3ASimple)

# SOURCE

The development version is on github at [https://github.com/robrwo/Catalyst-Plugin-Static-File](https://github.com/robrwo/Catalyst-Plugin-Static-File)
and may be cloned from [git://github.com/robrwo/Catalyst-Plugin-Static-File.git](git://github.com/robrwo/Catalyst-Plugin-Static-File.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Catalyst-Plugin-Static-File/issues](https://github.com/robrwo/Catalyst-Plugin-Static-File/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
