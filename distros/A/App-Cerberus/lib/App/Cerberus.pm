package App::Cerberus;
$App::Cerberus::VERSION = '0.11';
use strict;
use warnings;
use JSON();
use Carp;
use Plack::Request;

our $json = JSON->new->utf8;

#===================================
sub new {
#===================================
    my $class = shift;
    my $conf = shift || {};
    my %order;
    my $plugin_conf = $conf->{plugins}
        or croak "No plugins configured";

    my @plugins;
    for (@$plugin_conf) {
        my ( $name, $args ) = ref eq 'HASH' ? %$_ : $_;
        my $module = __PACKAGE__ . "::Plugin::$name";
        eval "require $module"
            or die "Can't load plugin ($module): $@";

        my $plugin = eval { $module->new($args) }
            or croak "Error loading plugin ($name): $@";

        push @plugins, $plugin;
    }
    bless { plugins => \@plugins }, $class;
}

#===================================
sub request {
#===================================
    my $self = shift;
    my $req  = Plack::Request->new( shift() );

    my $response = {};
    for my $plugin ( @{ $self->{plugins} } ) {
        eval {
            $plugin->request( $req, $response );
            1;
        }
            or warn "Error running plugin ("
            . ref($plugin) . "): "
            . ( $@ || 'Unknown error' );
    }
    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [ $json->encode($response) ]
    ];

}

1;

# ABSTRACT: A pluggable Perl web service to preprocess web requests. Plugins can add geo, timezone and browser metadata, and throttle request rate.

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cerberus - A pluggable Perl web service to preprocess web requests. Plugins can add geo, timezone and browser metadata, and throttle request rate.

=head1 VERSION

version 0.11

=head1 DESCRIPTION

There is a bunch of things we want to know about our web users, such as:

=over

=item *

Geo-location

=item *

Time zone

=item *

User-agent info

=item *

Are they a spider?

=item *

Are they making too many requests? Should we throttle them?

=back

To get all the above information reliably can easily consume 20MB+ of memory
in every web server process.

App::Cerberus packages up all this functionality into  a simple web service
(using L<Plack>), freeing up your web processes to deal with just your own
code.

A query to L<App::Cerberus> is a simple HTTP GET, and the response is JSON.

=head1 PLUGINS

=head2 L<App::Cerberus::Plugin::GeoIP>

Uses L<Geo::IP> with the L<GeoLite City database|http://www.maxmind.com/app/geolite>
to provide geo-location at the city level.

For instance:

    "geo": {
        "area_code": 201,
        "longitude": "-74.0781",
        "country_name": "United States",
        "region_name": "New Jersey",
        "country_code": "US",
        "region": "NJ",
        "city": "Jersey City",
        "postal_code": "07304",
        "latitude": "40.7167"
    }

=head2 L<App::Cerberus::Plugin::TimeZone>

Uses L<Time::OlsonTZ::Data> to provide the current timezone for the user, and
it's offset from GMT.

For instance:

    "tz": {
        "short_name": "EDT",
        "name": "America/New_York",
        "dst": "1",
        "gmt_offset": "-14400"
    }

The L<GeoIP|App::Cerberus::Plugin::GeoIP> plugin must be run before the
L<TimeZone|App::Cerberus::Plugin::TimeZone> plugin.

=head2 L<App::Cerberus::Plugin::BrowserDetect>

Uses L<HTTP::BrowserDetect> to provide data about the user agent and
recognises the most well known robots.

For instance:

    "ua": {
        "is_robot": 0,
        "is_mobile": 0,
        "is_tablet": 1,
        "version": {
            "minor": ".1",
            "full": 5.1,
            "major": "5"
        },
        "browser": "safari",
        "device": "ipad",
        "browser_properties": [
            "ios",
            "iphone",
            "ipod",
            "mobile",
            "safari",
            "device"
        ],
        "os": "iOS"
    }

=head2 L<App::Cerberus::Plugin::Throttle>

Set per-second, per-minute, per-hour, per-day and per-month request limits.
Different limits can be applied to different IP ranges.

For instance:

    "throttle": {
        "range":         "google",
        "reason":        "second",
        "sleep":         10,
        "request_count": 12
    }

=head1 INSTALLING CERBERUS

L<App::Cerberus> can be installed with your favourite cpan installer, eg:

    cpanm App::Cerberus

The only exception to this is that the L<Geo::IP> module should be properly
installed first, as it requires some manual work to make it use the C API.

See L<App::Cerberus::Plugin::GeoIP/INSTALLING GEO::IP> for instructions.

=head1 CONFIGURING CERBERUS

L<cerberus.pl> requires a YAML config file, eg:

    cerberus --conf /path/to/cerberus.yml

You can find an example C<cerberus.yml> here:
L<http://github.com/downloads/clintongormley/App-Cerberus/cerberus.yml>

The config file has two sections:

=head2 C<plack>

This lists any command line options that should be passed to L<plackup>, eg:

    plack:
        - port:                 5001
        - server:               Starman
        - workers:              2
        - daemonize

=head2 C<plugins>

This lists the plugins that should be loaded, and passes any specified
parameters to C<init()>. Plugins are run in the order specified:

    plugins:
      - GeoIP:                  /opt/geoip/GeoLiteCity.dat
      - TimeZone
      - BrowserDetect
      - Throttle:
            store:
                Memcached:
                    namespace:  cerberus
                    servers:
                        -       localhost:11211

            second_penalty:     5
            ranges:
                default:
                    ips:        0.0.0.0/0
                    limit:
                                - 20 per second
                                - 100 per minute

See each L<plugin|PLUGINS> for details of the accepted parameters.

=head1 RUNNING CERBERUS

    cerberus --conf /path/to/cerberus.yml

See L<cerberus.pl> for more options.

=head1 SEE ALSO

=over

=item L<App::Cerberus::Client>

=item L<Dancer::Plugin::Cerberus>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Cerberus

You can also look for information at:

=over

=item * GitHub

L<http://github.com/clintongormley/App-Cerberus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Cerberus>

=item * Search MetaCPAN

L<https://metacpan.org/module/App::Cerberus>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
