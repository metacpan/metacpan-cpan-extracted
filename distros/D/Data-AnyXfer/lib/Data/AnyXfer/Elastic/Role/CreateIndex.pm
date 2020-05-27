package Data::AnyXfer::Elastic::Role::CreateIndex;


#############################################################
use Carp;
croak 'This module has now been deprecated. '
. 'Please use Data::AnyXfer::Elastic::Indices directly.';
#############################################################


use v5.16.3;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;

use Data::AnyXfer::Elastic::Indices;

=head1 NAME

Data::AnyXfer::Elastic::Role::CreateIndex - A Role for Elasticsearch Index construction

=head1 SYNOPSIS

    package Parent;

    use Moo;
use MooX::Types::MooseLike::Base qw(:all);


    with 'Data::AnyXfer::Elastic::Role::CreateIndex';

    1;

=head1 DESCRIPTION

This role provides a method for creating Elasticsearch Index.

=cut

my $indices = Data::AnyXfer::Elastic::Indices->new;

=head1 METHODS

=head2 C<create_index()>

    $bool = Parent->create_index(
        {
            name            => 'interiors_2013',    # required
            mappings        => \%mappings,          # optional
            settings        => \%settings,          # optional
            warmers         => \%warmers,           # optional
            aliases         => \%aliases,           # optional
            delete_previous => 1,                   # optional
        }
    );

This method wraps the L<Search::Elasticsearch::Client::Direct::Indices> C<create>
method. However it also provides an additional arguement I<delete_previous>; which
deletes the index, should it exist, prior to a new index creation. Essentially the
index with alway be overridden.

Please note that the I<delete_previous> arguement should be used with care. Supposing
that an index contains multiple types - if the delete_previous flag is marked true
then all types will destroyed when the index is deleted.

=head1 SEE ALSO

L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-create-index.html>

=cut

sub create_index {
    my ( $self, %args ) = @_;

    croak "Arguement `name` required" unless $args{name};

    if ( $indices->exists( index => $args{name} ) ) {

        if ( $args{delete_previous} ) {

            $indices->delete( index => $args{name} );

        } else {

            croak 'Error: Index already exists with name: ' . $args{name};
        }
    }

    $indices->create(
        index => $args{name},
        body  => {
            mappings => $args{mappings} || {},
            settings => $args{settings} || {},
            warmers  => $args{warmers}  || {},
            aliases  => $args{aliases}  || {},
        },
    ) or croak( 'Error: Unable to create index: ' . $args{name} );

    return 1;
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

