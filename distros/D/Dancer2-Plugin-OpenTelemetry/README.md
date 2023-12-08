# OpenTelemetry for Dancer2

[![Coverage Status]][coveralls]

This is part of an ongoing attempt at implementing the OpenTelemetry
standard in Perl. The distribution in this repository implements a
plugin for the [Dancer2] web-framework, to generate and capture
telemetry data using the OpenTelemetry [API].

## What is OpenTelemetry?

OpenTelemetry is an open source observability framework, providing a
general-purpose API, SDK, and related tools required for the instrumentation
of cloud-native software, frameworks, and libraries.

OpenTelemetry provides a single set of APIs, libraries, agents, and collector
services to capture distributed traces and metrics from your application. You
can analyze them using Prometheus, Jaeger, and other observability tools.

## How does this distribution fit in?

This distribution allows authors of [Dancer2] applications to generate
telemetry data from their applications with minimal changes. In keeping with
the API / SDK separation described above, this plugin does not itself collect
or export this telemetry data. For that you will need to wire in the [SDK], for
which the best place to start is [that distribution's documentation][sdk].

## How do I get started?

Install this distribution from CPAN:
```
cpanm Dancer2::Plugin::OpenTelemetry
```
or directly from the repository if you want to install a development
version (although note that only the CPAN version is recommended for
production environments):
```
# On a local fork
cd path/to/this/repo
cpanm install .

# Over the net
cpanm https://github.com/jjatria/dancer2-plugin-opentelemetry.git
```

Then, enable the plugin in your [Dancer2] application. Remember to use the
SDK to be able to use this telemetry data.

``` perl
use Dancer2;
use OpenTelemetry::Plugin::OpenTelemetry;

# Requests to this will automatically generate telemetry data
get '/' => sub { 'OK' };
```

## How can I get involved?

We are in the process of setting up an OpenTelemetry-Perl special interest
group (SIG). Until that is set up, you are free to [express your
interest][sig] or join us in IRC on the #io-async channel in irc.perl.org.

## License

This distribution is licensed under the same terms as Perl itself. See
[LICENSE] for more information.

[dancer2]: https://metacpan.org/pod/Dancer2
[sdk]: https://github.com/jjatria/perl-opentelemetry-sdk
[api]: https://github.com/jjatria/perl-opentelemetry
[coveralls]: https://coveralls.io/github/jjatria/dancer2-plugin-opentelemetry?branch=main
[license]: https://github.com/jjatria/dancer2-plugin-opentelemetry/blob/main/LICENSE
[sig]: https://github.com/open-telemetry/community/issues/828
