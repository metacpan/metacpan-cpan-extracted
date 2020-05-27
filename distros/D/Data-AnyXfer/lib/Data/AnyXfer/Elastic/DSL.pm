package Data::AnyXfer::Elastic::DSL;

use strict;
use warnings;

use DateTime::Format::Strptime;
use DateTime ();

use constant dt_pattern => '%F %T';    # yyyy-mm-dd hh:mm:ss

BEGIN {

    my @METHODS = qw(
        range
        match
        regexp
        geo_bounding_box
    );

    foreach my $method (@METHODS) {

        no strict 'refs';

        *{$method} = sub { shift->_common( $method, @_ ) };
    }
}

=head1 NAME

Data::AnyXfer::Elastic::DSL

=head1 DESCRIPTION

Data::AnyXfer::Elastic::DSL contains helpful methods to help reduce the
verbosity of Elasticsearch queries through its Domain Specific Language (DSL).
These methods can be used in both filters and query clauses; adjusting
additional Elasticsearch arguments accordingly.

Query DSL: L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html>

=head1 SYNOPSIS

    use constant DSL => 'Data::AnyXfer::Elastic::DSL';

    my $exists       = DSL->exists('location');
    my $match        = DSL->match( 'name', 'George' );
    my $match_phrase = DSL->match_phrase( 'Vonnegut', 'So it goes.' );
    my $missing      = DSL->missing('property_reference');
    my $range        = DSL->range( 'age', gte => 16, lte => 25 );
    my $regexp       = DSL->regexp( 'postcode_short', value => 'E.*' );
    my $term         = DSL->term( 'name', value => 'foxtons', boost => 1 );
    my $terms        = DSL->terms( 'office', values => [ 1, 2, 3 ] );

    my $geo_bounding_box = DSL->geo_bounding_box(
        'pin.location',
        top_left     => { lat => 50, lon => 0 },
        bottom_right => { lat => 49, lon => -0.1 }
    );

    my $geo_distance = DSL->geo_distance(
        'pin.location',
        distance => '100km',
        lat      => 40,
        lon      => -70
    );

    my $geo_polygon = DSL->geo_polygon(
        'pin.location',
        points => [ [ -70, 40 ], [ -80, 30 ], [ -90, 20 ] ],
        _cache => 1,
    );

    my $geo_shape = DSL->geo_shape(
        'pin.location',
        "coordinates" : [
            [ [[102.0, 2.0], [103.0, 2.0], [103.0, 3.0], [102.0, 3.0], [102.0, 2.0]] ],

            [ [[100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0]],
              [[100.2, 0.2], [100.8, 0.2], [100.8, 0.8], [100.2, 0.8], [100.2, 0.2]] ]
        ],
        type   => 'multipolygon'
    );

=head1 METHODS

=head2 Common Methods

    range
    match
    regexp
    geo_bounding_box

The are common methods that have the same interface( $field, %arguements ):

=over

=item field

Defines the field name to search by.

=item arguements

This hash takes all optional Elasticsearch options such as boost and
_cache; in addition to specific arguements for the filter/query clause.

=back

=head2 exists

    DSL->exists( $field );

Returns a exists clause.

=cut

sub exists {
    my ( $class, $field ) = @_;
    return { exists => { field => $field } };
}

=head2 geo_distance

    DSL->geo_distance( $field, lat => 40, lon => 20, %es_args );

Returns a geo distance clause.

=cut

sub geo_distance {
    my ( $class, $field, %args ) = @_;
    return {
        geo_distance => {
            $field => {
                lat => delete $args{lat},
                lon => delete $args{lon},
            },
            %args
        }
    };
}

=head2 geo_polygon

    DSL->term( $field, points => [...] %es_args );

Returns a geo polygon filter clause.

=cut

sub geo_polygon {
    my ( $class, $field, %args ) = @_;
    return { geo_polygon =>
            { $field => { points => delete $args{points} }, %args }, };
}

=head2 geo_shape

    DSL->term( $field, coordinates => [...] %es_args );

Returns a geo shape filter clause.

=cut

sub geo_shape {
    my ( $class, $field, %args ) = @_;
    return {
        geo_shape => {
            $field => {
                (   $args{relation}    #
                    ? ( relation => delete $args{relation}, )
                    : ()
                ),
                shape => {
                    type        => delete $args{type},
                    coordinates => delete $args{coordinates},
                    %args
                },
            },
        }
    };
}

=head2 match_phrase

    DSL->match_phrase( $field, $phrase );

Returns a match_phrase clause.

=cut

sub match_phrase {
    my ( $class, $field, $phrase ) = @_;
    return { match_phrase => { $field => $phrase } };
}

=head2 missing

    DSL->missing( $field );

Returns a field missing clause

=cut

sub missing {
    return { bool => { must_not => { exists => { field => $_[1] } } } };
}

=head2 term

    DSL->term( $field, value => 'criteria', %es_args );

Returns a term clause.

=cut

sub term {
    my ( $class, $field, %args ) = @_;
    return { term => { $field => delete $args{value}, %args } };
}

=head2 terms

    DSL->terms( $field, values => \@criteria, %es_args );

Returns a terms clause.

=cut

sub terms {
    my ( $class, $field, %args ) = @_;
    return { terms => { $field => delete $args{values}, %args } };
}

=head2 format_datetime

    DSL->format_datetime('2001-10-02'); # returns 2001-10-02 23:59:59
    DSL->format_datetime( Datetime->new );
    DSL->format_datetime( london_now );

This method returns a datetime string in the format of yyyy-mm-dd hh:mm:ss for
use in Elasticsearch queries. It accepts any DateTime object or a string in the
format yyyy-mm-dd. Defaults to now().

=cut

sub format_datetime {
    my ( $class, $dt ) = @_;

    if ( UNIVERSAL::isa( $dt, 'DateTime' ) ) {

        return DateTime::Format::Strptime->new( pattern => dt_pattern )
            ->format_datetime($dt);
    }

    if ( $dt && $dt =~ m{^\d{4}-\d{2}-\d{2}$} ) {

        # Elasticsearch  needs the full format yyyy-MM-dd HH:mm:ss

        return $dt . ' 23:59:59';

    }

    return $class->format_datetime(DateTime->now);
}

sub _common {
    my ( $class, $method, $field, %args ) = @_;
    return { $method => { $field => \%args } };
}

1;


=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
