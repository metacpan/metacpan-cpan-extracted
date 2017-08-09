# ABSTRACT: provides perl API to DarkSky
package DarkSky::API;
use strict;
use warnings;
use JSON::XS;
use HTTP::Tiny;
use Moo;

our $VERSION = '1.1.4';

my $json = JSON::XS->new->pretty->canonical;

my $api   = "https://api.darksky.net/forecast";
my $docs  = "https://darksky.net/dev/";
my %units = (
    si   => 1,
    us   => 1,
    auto => 1,
    ca   => 1,
    uk   => 1,
);

has key => ( is => 'ro' );
has units => (
    is    => 'ro',
    'isa' => sub {
        die "Invalid units specified: see $docs\n"
            unless exists( $units{ $_[0] } );
    },
    'default' => 'auto',
);

has latitude  => ( is => 'ro' );
has longitude => ( is => 'ro' );
has 'time'    => ( is => 'ro', default => '' );
has timezone  => ( is => 'ro' );
has offset    => ( is => 'ro' );                  # Deprecated
has currently => ( is => 'ro' );
has minutely  => ( is => 'ro' );
has hourly    => ( is => 'ro' );
has daily     => ( is => 'ro' );
has alerts    => ( is => 'ro' );
has flags     => ( is => 'ro' );
has lang      => ( is => 'ro' );

sub BUILDARGS {
    my ( $class, %args ) = @_;

    my $url = "";
    my @params;
    if ( exists( $args{time} ) && $args{time} ne '' ) {
        @params = ( $args{latitude}, $args{longitude}, $args{time} );
    }
    else {
        @params = ( $args{latitude}, $args{longitude} );
    }

    my $params = join( ',', @params );

    if ( exists( $args{units} ) ) {
        $url
            = $api . '/'
            . $args{key} . '/'
            . $params
            . "?units="
            . $args{units};
    }
    else {
        $url = $api . '/' . $args{key} . '/' . $params . "?units=auto";
    }

    if ( exists( $args{lang} ) ) {
        $url = $url . "&lang=" . $args{lang};
    }

    my $response = HTTP::Tiny->new->get($url);

    die "Request to '$url' failed: $response->{status} $response->{reason}\n"
        unless $response->{success};

    return decode_json( $response->{content} );
}

sub TO_JSON { return { %{ shift() } }; }

1;

=pod

=encoding utf-8

=head1 NAME

DarkSky::API - Provides Perl API to DarkSky

=head1 SYNOPSIS

    use DarkSky::API;
    use JSON::XS;
    use feature 'say';
    
    my $lat  = 43.6667;
    my $long = -79.4167;
    my $time = "1475363709"; # example epoch time (optional)
    my $key = "c9ce1c59d139c3dc62961cbd63097d13"; # example DarkSky API key
    
    my $forecast = DarkSky::API->new(
        key       => $key,
        longitude => $long,
        latitude  => $lat,
        time      => $time
    );
    
    say "current temperature: " . $forecast->{currently}->{temperature};

    my $json = JSON::XS->new->canonical->pretty;

    # Allow blessed objects to be serialized
    # See http://search.cpan.org/~mlehmann/JSON-XS-3.02/XS.pm#OBJECT_SERIALISATION
    $json->convert_blessed([1]);

    say $json->encode($forecast);

=head1 DESCRIPTION

This module is a wrapper around the DarkSky API.

=head1 REFERENCES

Git repository: L<https://github.com/mlbright/DarkSky-API>

DarkSky API docs: L<https://darksky.net/dev/>

Another Perl API to DarkSky: L<http://search.cpan.org/~mallen/WebService-ForecastIO-0.01>

=head1 COPYRIGHT

Copyright (c) 2017 L<Martin-Louis Bright>

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
