package Data::AnyXfer::Elastic::Role::Project;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::autoclean;

use Carp;

use Data::AnyXfer::Elastic::Index;
use Data::AnyXfer::Elastic::ScrollHelper;
use Data::AnyXfer::JSON qw/encode_json_pretty/;

=head1 NAME

Data::AnyXfer::Elastic::Role::Project

=head1 SYNOPSIS

    with 'Data::AnyXfer::Elastic::Role::Project';

    # The consuming module must implement a attribute called 'index_info'
    # which returns an IndexInfo instance describing the Elasticsearch index.

    $results = $self->_es_simple_search(
        body => {
            query => {
                term => {
                    "first_name" => { value => "jessica" },
                }
            },
            size => 10,
        }
    );

=head1 DESCRIPTION

B<Data::AnyXfer::Elastic::Role::Project> implements common Elasticsearch
helper methods into your project.

=head1 ATTRIBUTES

=over

=item C<es>

Stores a C<Data::AnyXfer::Elastic::Index> object that is connected to
the Elasticsearch index and type specified in C<index_info>.

=back

=cut

has es => (
    is       => 'ro',
    isa      => InstanceOf['Data::AnyXfer::Elastic::Index'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_es',
);

sub _build_es {

    my $index_info = $_[0]->index_info;

    return Data::AnyXfer::Elastic::Index->new(
        index_name   => $index_info->alias,
        index_type   => $index_info->type,
        silo         => $index_info->silo,
        connect_hint => $index_info->connect_hint,
    );

}

=head1 METHODS

=head2 C<index_info>

B<index_info> must be implemented by your project too define the projects
Elasticsearch index. See C<Data::AnyXfer::Elastic::IndexInfo>.

=cut

sub index_info {
    croak 'index_info must be implemented by your project.';
}


=head2 C<_es_simple_search( $args )>

    $searcher->_es_simple_search(
        body => {
            query => {
                term => {
                    "first_name" => { value => "jessica" },
                }
            }
        }
    );

    Output:

    [
        {
            email       => "jedwards3@taobao.com",
            first_name  => "Jessica",
            id          => 4,
            last_name   => "Edwards"
        },
        {
            email       => "jhart4@dot.gov",
            first_name  => "Gerald",
            id          => 5,
            last_name   => "Hart"
        }
    ]

B<_es_simple_search> provides a general search mechanism to quickly search a
index. The relevant index name and index_type are automatically injected into
the request - and only search body arguments need to be included. These can be
found in C<Search::Elasticsearch::Client::Direct> and official Elasticsearch
documentation. The method returns the extracted results body.

See L<./Scrolling Searches>.

=cut

sub _es_simple_search {
    my ( $self, %args ) = @_;

    # extract results, defaults to "true"
    my $extract = delete $args{extract_results};
    $extract = !defined($extract) || $extract;

    my $scroll_size = delete $args{scroll_size};
    my $scroll      = delete $args{scroll};

    if ( defined $scroll_size || $scroll ) {

        croak 'scroll_size is required for scrolled searches'
            unless defined $scroll_size;

        my $scroll_helper = $self->es->scroll_helper(
            %args,
            scroll => $scroll || '5m',
            size => $scroll_size,
        );

        return Data::AnyXfer::Elastic::ScrollHelper->new(
            extract_results => $extract,
            scroll_helper   => $scroll_helper,
        );

    } else {

        my $return = $self->es->search(%args);

        return $extract
            ? $self->_es_extract_results($return)
            : $return;
    }
}



=head2 C<_es_extract_results>

    $results = $self->_es_extract_results( $es_search_response );

Elasticsearch by default returns search results with meta data regarding shard
statuses and search duration. Most of the time this is useless. This method
strips this meta data and returns an array reference of search results
directly.

=cut

sub _es_extract_results {
    return [ map { $_->{_source} } @{ $_[1]->{hits}->{hits} } ];
}


=head2 C<_es_simple_radial_search>

    # default radial search, defaults to 0 - 100km

    $results = $self->_es_simple_radial_search( from_point => [0.12, 51.5] );

    # radial search within 10 kilometres

    $results = $self->_es_simple_radial_search(
        from_point => { lon => 0.12, lat => 51.5 },
        max_distance => '10km' );

    # nearest cities within 100 kilometres ordered by distance

    $results = $self->_es_simple_radial_search(
        from_point => [0.12, 51.5],
        body => { query => { term => { category => 'city' } } } );

    # top 5 nearest cinemas within 6 kilometres, using a boost value of .5 for distance
    # (it's more important that it's a cinema first, then distance second)

    $results = $self->_es_simple_radial_search(
        from_point => { lon => 0.12, lat => 51.5 },
        max_distance => '6km',
        distance_boost => .5,
        body => { query => term => { description => 'cinema' } } },
        size => 5);

=cut

sub _es_simple_radial_search {

    my ( $self, %search_args ) = @_;

    my $location     = delete $search_args{from_point};
    my $max_distance = delete $search_args{max_distance};
    my $boost        = delete $search_args{distance_boost};

    # check required arguments
    croak q!'location' is required for radial searches!
        unless $location;

    # apply argument defaults for optional args
    ( $search_args{body} ||= {} )->{query} ||= { match_all => {} };
    $search_args{size} //= 300;
    $boost ||= 3;

    # if max distance supplied, set score cutoff for results
    # for a gaus curve, this should be around one third of the value
    my $min_score = $max_distance ? $boost / 3 : undef;

    # if a max distance was not supplied, set it to something large
    $max_distance ||= '100km';

    # build radial search query
    ( $search_args{body} ||= {} )->{query} = {
        function_score => {
            query     => $search_args{body}->{query},
            functions => [
                {   exp => {
                        location => {
                            offset => '0km',
                            scale  => $max_distance,
                            origin => $location,
                        }
                    },
                    weight => $boost,
                },
            ],
            score_mode => 'first',
            # optionally supply a min score
            ( $min_score ? ( min_score => $min_score ) : () ),
        },
    };

    # run search and return
    return $self->_es_simple_search(%search_args);
}

=head2 C<_es_simple_bounding_box_search>

=cut

sub _es_simple_bounding_box_search {

    my ( $self, %search_args ) = @_;

    foreach (qw( latitude_max latitude_min longitude_max longitude_min )) {
        croak qq!'$_' is required for bounding box searches!
            unless $search_args{$_};
    }

    # setup default search query
    ( $search_args{body} ||= {} )->{query} ||= { match_all => {} };
    $search_args{size} //= 10000;

    # build filters
    my @filters = $search_args{body}->{filter} || ();

    # are we searching on geo points or polygons?
    unless ( delete $search_args{polygon_intersects} ) {

        # we're searching on geo points
        # compose bounding box filters
        push @filters,
            {
            geo_bounding_box => {
                location => {
                    top_left => {
                        lon => delete $search_args{longitude_min},
                        lat => delete $search_args{latitude_max},
                    },
                    bottom_right => {
                        lon => delete $search_args{longitude_max},
                        lat => delete $search_args{latitude_min},
                    },
                }
            }
            };

    } else {
        # otherwise this must be a geo shape
        my ( $xmax, $xmin, $ymax, $ymin )
            = delete @search_args{
            qw/latitude_max latitude_min longitude_max longitude_min/};

        push @filters,
            {
            geo_shape => {
                polygon => {
                    relation => 'intersects',
                    shape    => {
                        type        => 'polygon',
                        coordinates => [
                            [   [ 0 + $ymin, 0 + $xmin ],
                                [ 0 + $ymin, 0 + $xmax ],
                                [ 0 + $ymax, 0 + $xmax ],
                                [ 0 + $ymax, 0 + $xmin ],
                                [ 0 + $ymin, 0 + $xmin ],
                            ]
                        ]
                    }
                }
            }
            };
    }

    # add any filters generated to the query
    if (@filters) {

        if ( $self->es->elasticsearch->api_version =~ /^2/ ) {
            # XXX : Support ES 2.3.5
            $search_args{body}->{query} = {
                filtered => {
                    query  => $search_args{body}->{query},
                    filter => { bool => { must => \@filters, }, }
                }
            };
        } else {
            # XXX : Support ES 6.x
            $search_args{body}->{query} = {
                bool => {
                    must   => $search_args{body}->{query},
                    filter => { bool => { must => \@filters, }, }
                }
            };
        }
        delete $search_args{body}->{filter};
    }

    # run search and return
    return $self->_es_simple_search(%search_args);
}


=head2 C<_es_simple_polygon_search>

    # default polygon search (max 2000 results)
    $polygon1 = [ [$lon1, $lat1], [$lon2, $lat2], [$lon3, $lat3]];
    $results = $self->_es_simple_polygon_search(polygons => [$polygon1, $polygon2]);

    # default polygon search, results sorted by price (max 2000 results)
    $results = $self->_es_simple_polygon_search(
        body => { sort => [ { price => "asc" } ] },
        polygons => [$polygon1, $polygon2],
    );

=cut

sub _es_simple_polygon_search {

    my ( $self, %search_args ) = @_;

    # setup default query if not supplied
    # (user just wants everything returned from the filters)
    ( $search_args{body} ||= {} )->{query} ||= { match_all => {} };
    $search_args{size} //= 10000;

    # build polygon filters
    if ( my $polygons = delete $search_args{polygons} ) {

        # TODO : Refactor this away to somewhere
        # which can handle it better
        # (makes sure we have a 3 level nested array of points)
        $polygons = [$polygons]
            unless ref $polygons eq 'ARRAY';

        $polygons = [$polygons]
            unless ref $polygons eq 'ARRAY'
            && ( !@{$polygons} || ref $polygons->[0] eq 'ARRAY' );

        $polygons = [$polygons]
            unless ref $polygons eq 'ARRAY'
            && ( !@{$polygons}
            || ref $polygons->[0] eq 'ARRAY'
            && ( !@{ $polygons->[0] } || ref $polygons->[0]->[0] eq 'ARRAY' )
            );

        # for safety, make sure coordinates are perl numbers
        for (@{$polygons}) {
            $_ = [0 + $_->[0], 0 + $_->[1]] for @{$_};
        }

        # Build the filters
        my @filters
            = map { { geo_polygon => { location => { points => $_ } } } }
            @{$polygons};
        push @filters, $search_args{body}->{filter} || ();

        # Modify / add filters into query
        if (@filters) {

            if ( $self->es->elasticsearch->api_version =~ /^2/ ) {
                # XXX : Support ES 2.3.5 (TO BE REMOVED)
                $search_args{body}->{query} = {
                    filtered => {
                        query  => $search_args{body}->{query},
                        filter => { bool => { must => \@filters, }, }
                    }
                };
            } else {
                # XXX : Support ES 6.x
                $search_args{body}->{query} = {
                    bool => {
                        must   => $search_args{body}->{query},
                        filter => { bool => { must => \@filters, }, }
                    }
                };
            }
        }
    }

    # run search and return
    return $self->_es_simple_search(%search_args);

}

=head2 C<_es_simple_point_search>

    # default point search

    my $point1 = [$lon1, $lat1];

    my $results = $self->_es_simple_point_search( points => $point1 );

    this search finds the intersection of the provided point with
    any document with a geo_shape polygon which containes that point

=cut

sub _es_simple_point_search {

    my ( $self, %search_args ) = @_;

    # setup default query if not supplied
    ( $search_args{body} ||= {} )->{query} ||= { match_all => {} };
    $search_args{size} //= 1000;

    if ( my $point = delete $search_args{point} ) {

        my $points_geo_shape = [
            {   geo_shape => {
                    polygon => {
                        shape => {
                            type        => 'point',
                            coordinates => $point
                        },
                        relation => 'intersects'
                    }
                }
            }
        ];

        $search_args{body}{query}{bool}{must} = $points_geo_shape;

        # Build the filters
        my @filters;
        push @filters, $search_args{body}->{filter} || ();

        if (@filters) {
            $search_args{body}{query}{bool}{filter} = \@filters;
        }
    }

    # run search and return
    return $self->_es_simple_search(%search_args);

}


=head1 Scrolling Searches

Passing B<_es_simple_search> - or any function that extends its functionality
- a C<scroll_size> returns a L<Data::AnyXfer::Elastic::ScrollHelper>
instead of a result. This can then be used for reading batched results from
ES.

=over

=item C<scroll_size>

The number of results to return for each batch from each node in the ES
cluster. The total size of the batch returned is C<scroll_size * es_nodes>.

If this is set then scrolling will be used, an instance of
L<Data::AnyXfer::Elastic::ScrollHelper> will be returned instead of
the normal results.

=item C<search_type>

Efficient scrolling can be set by setting the C<search_type> to C<scan>,
saving on the innefficient sorting phase.

=item C<scroll>

Set the duration to keep the results alive, for processing before the next set
of results is fetched. Default is C<5m>.

=back

=head1 ENVIRONMENT

=head2 ES_DEBUG

    $ENV{ES_DEBUG} = 1;

Set debugging printing of ES calls.

=cut


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

