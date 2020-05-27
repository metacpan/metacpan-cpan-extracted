package Data::AnyXfer::Elastic::Utils::Validator::IndexInfo;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use namespace::autoclean;

# PARENTS
extends 'Data::AnyXfer::Elastic::IndexInfo';


# INTERFACES
with 'Data::AnyXfer::Elastic::Role::IndexInfo';


=head1 NAME

Data::AnyXfer::Elastic::Utils::Validator::IndexInfo

=head1 DESCRIPTION

Index Info definition for Validation index.

=cut



# INDEX INFO INTERFACE

sub define_index_info {
    return (
        silo             => 'public_data',
        # must be on static cluster so test indexes are cleaned
        # up and created on all nodes
        type             => 'validation_index',
        alias            => 'validation_index',
        timestamp_format => '%Y',
        mappings         => $_[0]->_get_mappings,
    );

}

sub _get_mappings {
    return {
        validation_index => {
            properties => {
                fieldtype_geo_shape => { type => 'geo_shape' },
                # TODO: add more useful fields
            },
        },
    };
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
