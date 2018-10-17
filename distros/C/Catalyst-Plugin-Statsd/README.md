# NAME

Catalyst::Plugin::Statsd - log Catalyst stats to statsd

# VERSION

version v0.1.1

# SYNOPSIS

```perl
use Catalyst qw/
   Statsd
   -Stats=1
 /;

__PACKAGE__->config(
  'psgi_middleware', [
      Statsd => {
          client => Net::Statsd::Tiny->new,
      },
  ],
);

# (or you can specify the Statsd middleware in your
# application's PSGI file.)
```

# DESCRIPTION

This plugin will log [Catalyst](https://metacpan.org/pod/Catalyst) timing statistics to statsd.

# KNOWN ISSUES

Enabling stats will also log a table of statistics to the Catalyst
log.  If you do not want this, then you will need to subclass
[Catalyst::Stats](https://metacpan.org/pod/Catalyst::Stats) or modify your logger accordingly.

# SEE ALSO

- [Catalyst::Stats](https://metacpan.org/pod/Catalyst::Stats)
- [Plack::Middleware::Statsd](https://metacpan.org/pod/Plack::Middleware::Statsd)

# SOURCE

The development version is on github at [https://github.com/robrwo/CatalystX-Statsd](https://github.com/robrwo/CatalystX-Statsd)
and may be cloned from [git://github.com/robrwo/CatalystX-Statsd.git](git://github.com/robrwo/CatalystX-Statsd.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/CatalystX-Statsd/issues](https://github.com/robrwo/CatalystX-Statsd/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
