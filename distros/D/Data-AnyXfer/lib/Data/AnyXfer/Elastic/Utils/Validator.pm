package Data::AnyXfer::Elastic::Utils::Validator;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use namespace::autoclean;


# IMPORTS
use Data::AnyXfer::Elastic                              ();
use Data::AnyXfer::Elastic::Error                       ();
use Data::AnyXfer::Elastic::Utils::Validator::IndexInfo ();


# GLOBALS
# using global variables to share elasticsearch connection across
# object instances
my $alias;
my $indices;


=head1 NAME

Data::AnyXfer::Elastic::Utils::Validator

=head1 DESCRIPTION

This module is a helper utility to validate queries against Elasticsearch.

See: https://www.elastic.co/guide/en/elasticsearch/reference/2.4/search-validate.html

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Utils::Validator ();

    my $validator = Data::AnyXfer::Elastic::Utils::Validator->new;

=head1 RESPONSE

 {
    "explanations": [
        {
            "error": "Invalid Exception",
            "valid": 1
        }
    ],
    "valid": 1
 }

=head1 METHODS

    my $validation_response = $validator->validate_geo_shape( Geo::JSON );

Validates the provided GeoJSON shape against Elasticsearch validator. Checks
for self-intersections, duplicate points etc.

=cut

sub validate_geo_shape {
    my ( $self, $geojson ) = @_;

    return $self->_validate(
        query => {
            geo_shape => {
                fieldtype_geo_shape => {
                    shape => {
                        coordinates => $geojson->coordinates,
                        type        => $geojson->type,
                    }
                }
            }
        }
    );
}


# PRIVATE METHODS


sub _get_cached_indices_object {

    return $indices if $indices && $alias;

    # create index info - does not create an initial index
    my $index_info
        = Data::AnyXfer::Elastic::Utils::Validator::IndexInfo->new;

    my @clients = Data::AnyXfer::Elastic->default->all_clients_for(
        $index_info->silo );

    for (@clients) {
        $_->indices->create(
            index => $index_info->index,
            body  => {
                map { $_ => $index_info->$_ } qw( mappings settings aliases )
            },
            ignore => 400,   # ignore index_already_exists_exception exception
        );
    }

    $alias   = $index_info->alias;
    return $indices = $index_info->get_indices;
}


sub _validate {
    my ( $self, %body ) = @_;

    my $response = eval {
        $self->_get_cached_indices_object->validate_query(
            index   => $alias,
            body    => \%body,
            explain => 1,
        );
    };

    # croak elasticsearch errors nicely
    if ( my $error = $@ ) {

        # unset so a connection will be produced on the next run
        $alias   = undef;
        $indices = undef;

        Data::AnyXfer::Elastic::Error->croak($error);
    }

    return $response;
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
