package Data::AnyXfer::Elastic::Role::IndexInfo_ES2;

use Carp;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);


use Clone    ();
use JSON::XS ();


=head1 NAME

Data::AnyXfer::Elastic::Role::IndexInfo_ES2 - Role representing
Elasticsearch information (ES 2.3.5 Support)

=head1 SYNOPSIS

    if ( $object->does(
        'Data::AnyXfer::Elastic::Role::IndexInfo') ) {

        my $index = $object->get_index;

        my $results =
            $index->search( query => { match_all => {} } );
    }

=head1 DESCRIPTION

This role is used by
L<Data::AnyXfer::Elastic::IndexInfo> to retrieve or supply Elasticsearch
indexing / storage information.

This basically acts as connection information. Any object satisfying
the interface criteria may consume and implement this role.

=head1 SEE ALSO

L<Data::AnyXfer::Elastic>

L<Data::AnyXfer::Elastic::IndexInfo>

=cut


has es235_mappings => (
    is      => 'ro',
    isa     => HashRef,
    builder => '_build_es235_mappings',
    lazy    => 1,
);


sub _build_es235_mappings {

    my $self = shift;

    # check to see if we have an explicit mapping supplied
    if ( my $mappings = $self->mappings ) {

        # XXX : transform mappings structure to equivalent for ES 2.3.5
        return _transform_mapping_for_es2($mappings);
    }

    # this index is schemaless
    return {};
}


# Recursive backwatds conversion of mappings structure to
# be ES 2.3.5 compatible (conversion is for common cases only)

my @string_not_analyzed = qw(string not_analyzed);
my @string_analyzed     = qw(string analyzed);

sub _transform_mapping_for_es2 {

    my $mappings = $_[0];
    my $type     = ref $mappings;

    # recursively handle hashes in the mappings
    # structure
    if ( $type eq 'HASH' ) {

        # shallow clone mappings hash so there are no
        # side-effects to callers
        my $value = { %{$mappings} };

        # transform datatypes
        if ( my $type = $value->{type} ) {

            # XXX : backwards support to handle deprecated
            # string datatype
            if ( $type eq 'keyword' ) {
                @{$value}{qw(type index)} = @string_not_analyzed;

            } elsif ( $type eq 'text' ) {

                @{$value}{qw(type index)} = @string_analyzed;

            } elsif ( $type eq 'scaled_float' ) {

                # XXX : backwards support for scaled_float dataFile
                # which was best as a double in older versions of ES
                $value->{type} = 'double';
                $value->{precision_step}
                    = log( delete $value->{scaling_factor} );

            } elsif ( $type eq 'completion' ) {
                # turn payloads on by default
                $value->{payloads} = JSON::XS::true();

                # XXX : backwards support to handle deprecated
                # completion contexts structure
                if ( my $contexts = delete $value->{contexts} ) {

                    $contexts
                        = ref $contexts eq 'ARRAY'
                        ? Clone::clone($contexts)
                        : [ Clone::clone($contexts) ];

                    $value->{context}
                        = { map { ( delete $_->{name} ) => $_ }
                            @{$contexts} };
                }
            }

            # convert any new indexing values to the old format
            if ( my $index = $value->{index} ) {

                if ( $index eq 'true' ) {
                    $value->{index} = 'analyzed';

                } elsif ( $index eq 'false' ) {
                    $value->{index} = 'not_analyzed';
                }
            }

            # convert fielddata values to old format
            my $fielddata = $value->{fielddata};
            if (defined $fielddata) {
                $value->{fielddata} = {
                    format => $fielddata ? 'paged_bytes' : 'disabled'
                };
            }
        }

        # return a clone of the hash once transformed
        return {
            map { $_ => _transform_mapping_for_es2( $value->{$_} ) }
                keys %{$value}
        };
    }

    # recursively  arrays in the mappings structure
    if ( $type eq 'ARRAY' ) {
        return [ map { _transform_mapping_for_es2($_) } @{$mappings} ];
    }

    # must be a scalar or other type which cannot have a datatype
    return $mappings;
}




1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

