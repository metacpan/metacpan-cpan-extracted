# NAME

Catalyst::Plugin::Statsd - log Catalyst stats to statsd

# VERSION

version v0.4.2

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

# METHODS

## `statsd_client`

```
$c->statsd_client;
```

Returns the statsd client.

## `statsd_metric_name_filter`

```
$c->statsd_metric_name_filter( $stat_or_name );
```

This method returns the name to be used for logging stats, or `undef`
if the metric should be ignored.

If it is passed a non-arrayref, then it will stringify the argument
and return that.

If it is passed an array reference, then it assumes the argument comes
from [Catalyst::Stats](https://metacpan.org/pod/Catalyst::Stats) report and is converted into a suitable metric
name.

You can override or modify this method to filter out which metrics you
want logged, or to change the names of the metrics.

# METRICS

## `catalyst.response.time`

This logs the Catalyst reponse time that is normally reported by
Catalyst.  However, it is probably unnecessary since
[Plack::Middleware::Statsd](https://metacpan.org/pod/Plack::Middleware::Statsd) also logs response times.

## `catalyst.stats.*.time`

These are metrics generated from [Catalyst::Stats](https://metacpan.org/pod/Catalyst::Stats).

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

# CONTRIBUTOR

Slaven Rezić <slaven@rezic.de>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
