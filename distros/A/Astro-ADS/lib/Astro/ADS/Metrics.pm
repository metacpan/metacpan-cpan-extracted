package Astro::ADS::Metrics;
$Astro::ADS::Metrics::VERSION = '1.91';
use Moo;
extends 'Astro::ADS';
#with 'Astro::ADS::Role::ResultMapper';

use Astro::ADS::Result;

use Carp;
use Data::Dumper::Concise;
use Mojo::Base -strict; # do we want -signatures
use Mojo::DOM;
use Mojo::File qw( path );
use Mojo::JSON qw( decode_json encode_json );
use Mojo::URL;
use Mojo::Util qw( quote url_escape );
use PerlX::Maybe;
use Types::Standard qw( Int Str Enum ArrayRef HashRef );

has bibcode => (
    is  => 'rw',
    isa => Str,
);
has bibcodes => (
    is      => 'rw',
    isa     => ArrayRef[Str],
    default => sub { return [] },
);
has types => (
    is  => 'rw',
    isa => Enum[qw( basic citations indicators histograms timeseries )],
);
has histograms => (
    is  => 'rw',
    isa => Enum[qw( publications reads downloads citations )],
);

sub details {
    my ($self, @bibcodes) = @_;
    my $url = $self->base_url->clone->path('metrics/detail');

    my $response = $self->post_response( $url, {bibcodes => \@bibcodes} );
    if ( $response->is_error ) {
        carp $response->message;
        my $error_obj = {
            message  => $response->message,
            bibcodes => \@bibcodes,
            url      => $url->to_string,
        };
        return Astro::ADS::Result->new( {error => $error_obj} );
    }

    return $response->json;
}

sub fetch {
    my ($self, $bibcode) = @_;

    $bibcode ||= $self->bibcode()
        or die 'No bibcode given to fetch';
    my $path = join '/', 'metrics', url_escape($bibcode);
    my $url = $self->base_url->clone->path($path);
    my $response = $self->get_response( $url );
    return $response->json;
}

sub batch {
    my ($self, $bibcodes, $options) = @_;
    my $url = $self->base_url->clone->path('metrics');

    my $terms = {
              bibcodes   => $bibcodes,
        maybe types      => $options->{types},
        maybe histograms => $options->{histograms},
    };

    my $response = $self->post_response( $url, $terms );
    if ( $response->is_error ) {
        carp $response->message;
        my $error_obj = {
            message  => $response->message,
            bibcodes => $bibcodes,
            url      => $url->to_string,
            key      => $self->token,
        };
        return Astro::ADS::Result->new( {error => $error_obj} );
    }

    return $response->json;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Astro::ADS::Metrics - Queries the ADS Metrics endpoint and collects the results

=head1 VERSION

version 1.91

=head1 SYNOPSIS

    my $metrics = Astro::ADS::Metrics->new({
        bibcodes  => ['...'],  # list of bibcodes
        { types => ['basic'] } # types of metrics to return
    });

    my $json_result = $metrics->batch();

    my $single_bibcode = $metrics->fetch('2019MNRAS.487.3523C');

    my $detailed_stats = $metrics->details( @bibcodes );


=head1 DESCRIPTION

Fetch Metrics for papers in the Harvard ADS

Currently only C<fetch> checks the Metrics object for
how to make the calls.

The json structure is documented on the ADS API website.
I haven't used the ResultMapper to make it easier to access.
You'll have to work that out yourself. Let me know if there's a better way.

=head1 Methods

=head2 fetch

Fetch a single bibcode. No options taken.
Returns the json response as a hash reference.

=head2 batch

Takes an array ref of bibcodes to find metrics for.
An optional hash ref can limit the types of metrics
returned and if the type is histogram, which histograms
to return. As in

    { types    => ['histograms'], histograms => ['citations'] }

Returns the json response as a hash reference.

=head2 details

Queries the metrics/details endpoint with a list of bibcodes.
Takes no options.
Returns the json response as a hash reference.

=head2 Notes

This module's client methods are liable to change,
but deprecation warnings will be issued if they do.
See the docs.

=head1 TODO

The Metrics object should store the arguments from the latest
request, so that repeated calls can be brief.

Consider using the ResultMapper to contain results (if that makes sense)
or maybe to warn if there are any C<skipped bibcodes> in the response.

=head1 See Also

=over 4

=item * L<Astro::ADS>

=item * L<ADS API|https://ui.adsabs.harvard.edu/help/api/>

=item * L<Metrics API|https://ui.adsabs.harvard.edu/help/api/api-docs.html#tag--metrics>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Boyd Duffee.

This is free software, licensed under:

  The MIT (X11) License

=cut
