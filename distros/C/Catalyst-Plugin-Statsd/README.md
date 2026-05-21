# NAME

Catalyst::Plugin::Statsd - Log Catalyst stats to statsd

# SYNOPSIS

```perl
use Catalyst qw/
   Statsd
   -Stats=1
 /;

use Net::Statsd::Tiny;

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

## CONFIGURATION

```perl
__PACKAGE__->config(

  'Plugin::Statsd' => {
      disable_stats_report => 0,
  },

);
```

## `disable_stats_report`

Enabling stats will also log a table of statistics to the Catalyst
log.  If you do not want this, then set `disable_stats_report`
to true.

Note that if you are modifying the `log_stats` method or using
another plugin that does this, then this may interfere with that if
you disable the stats report.

This defaults to

```
!$c->debug
```

# RECENT CHANGES

Changes for version v0.10.1 (2026-05-10)

- Security
    - Plack::Middleware::Statsd v0.9.0 or later is now a requirement.
- Tests
    - Added more test diagnostics.
    - Fixed error in regular expression in tests that sometimes failed. GH#5

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Catalyst](https://metacpan.org/pod/Catalyst) version 5.90123 or later
- [Moose::Role](https://metacpan.org/pod/Moose%3A%3ARole)
- [POSIX](https://metacpan.org/pod/POSIX)
- [Plack::Middleware::Statsd](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3AStatsd) version v0.9.0 or later
- [Ref::Util](https://metacpan.org/pod/Ref%3A%3AUtil)
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Catalyst::Plugin::Statsd
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SECURITY CONSIDERATIONS

If the ["statsd\_client"](#statsd_client) does not have a secure communications channel to the
statsd server, then there is the risk that information such as IP
addresses or session ids will be leaked.

Anything that needs to log information in a set that contains
personally identifiable information, authentication tokens or other
sensitive data should use the `psgix.monitor.statsd_secure_set_add`
function instead of the client's `set_add` method, for example:

```perl
if (my $secure_set_add = $c->req->env->{'psgix.monitor.statsd_secure_set_add'}) {
    $secure_set_add->( $c->body_param->{name_of_sheep} );
}
```

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.
Future releases may only support Perl versions released in the last ten (10) years.

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/CatalystX-Statsd/issues](https://github.com/robrwo/CatalystX-Statsd/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/CatalystX-Statsd](https://github.com/robrwo/CatalystX-Statsd)
and may be cloned from [https://github.com/robrwo/CatalystX-Statsd.git](https://github.com/robrwo/CatalystX-Statsd.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Slaven Rezić <slaven@rezic.de>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

- [Catalyst::Stats](https://metacpan.org/pod/Catalyst%3A%3AStats)
- [Plack::Middleware::Statsd](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3AStatsd)
- [Net::Statsd::Tiny](https://metacpan.org/pod/Net%3A%3AStatsd%3A%3ATiny)
