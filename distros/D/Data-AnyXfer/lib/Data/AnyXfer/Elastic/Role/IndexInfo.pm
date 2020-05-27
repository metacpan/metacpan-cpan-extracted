package Data::AnyXfer::Elastic::Role::IndexInfo;

use Moo::Role;
use Moose::Meta::Class;
use MooX::Types::MooseLike::Base qw(:all);

use Data::AnyXfer::Elastic::Index   ();
use Data::AnyXfer::Elastic::Indices ();

=head1 NAME

Data::AnyXfer::Elastic::Role::IndexInfo - Role representing
Elasticsearch information

=head1 SYNOPSIS

    if ( $object->does(
        'Data::AnyXfer::Elastic::Role::IndexInfo') ) {

        my $index = $object->get_index;

        my $results =
            $index->search( query => { match_all => {} } );
    }

=head1 DESCRIPTION

This role is used by
L<Data::AnyXfer::Elastic> to retrieve or supply Elasticsearch
indexing / storage information.

This basically acts as connection information. Any object satisfying
the interface criteria may consume and implement this role.

=head1 SEE ALSO

L<Data::AnyXfer::Elastic>

=head1 REQUIRED METHODS

=cut


=head2 index

The name of the Elasticsearch index for the package / namespace.

If you don't know what a type is, see
L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/_basic_concepts.html#_index>
 for more information.

=cut

requires 'index';

=head2 type

The primary document type for the package / namespace.

If you don't know what an index is, see
L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/_basic_concepts.html#_type>
 for more information.

=cut

requires 'type';


=head2 mappings

The mappings C<HASH> ref for all types containing in the index.
See
L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-create-index.html#mappings>

=cut

requires 'mappings';


=head2 settings

The settings C<HASH> ref for any Elasticsearch index settings.
See
L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-create-index.html#create-index-settings>

=cut

requires 'settings';


=head2 warmers

The warmers map (C<HASH> ref), for the index.
See
L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-create-index.html#warmers>

=cut

requires 'warmers';


=head2 alias

The primary alias used for the project. This will always
 at least point to the L</index>.

See L</aliases>.

=cut

requires 'alias';


=head2 silo

The L<Data::AnyXfer::Elastic> silo the data should be
 held in and retrieved from.

=cut

requires 'silo';


=head2 aliases

The full aliases map (C<HASH> ref) for the Elasticsearch
 C<create_index> call.

See
L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-create-index.html#create-index-aliases>

B<You do not need to define the mapping for L</alias>
unless you have special requirements. By default, this
 will be alised to the L<index> if this object is used
to index any new data>.

=cut

requires 'aliases';


=head1  PROVIDED ATTRIBUTES

=head2 api_version

    if ($object->api_version =~ /^6/) {
        # do something for elasticsearch 6
    }

Returns the Search::Elasticsearch client API version. This is useful
for changing behaviour for different versions of Elasticsearch or API changes.

=cut

has api_version => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_detect_index_info_es_version',
);

sub _detect_index_info_es_version {

    my ($info) = @_;
    my $client = Data::AnyXfer::Elastic->client_for( $info->silo );
    return $client->api_version;
}


=head1 PROVIDED METHODS

=head2 get_index

    my $index = $object->get_index;

    # use it...

Returns a basic instance of L<Data::AnyXfer::Elastic::Index>
using the objects own information, B<to use for reads only!>
(the index handle is created on the primary alias, found out through
the interface).

Optionally takes a named argument C<direct>, which when set causes
the index object to look directly at the generated index name, instead of the alias.
(This will not do what you want if you use aliasing of any kind!)

=cut

sub get_index {

    my ( $info, %opts ) = @_;

    my $index_name = $opts{direct} ? $info->index : $info->alias;
    my $connect_hint = $opts{connect_hint};

    # if there was no direct connection hint,
    # look for one in the index info
    if ( !$connect_hint && $info->can('connect_hint') ) {
        $connect_hint = $info->connect_hint;
    }

    return Data::AnyXfer::Elastic::Index->new(
        silo         => $info->silo,
        index_name   => $index_name,
        index_type   => $info->type,
        connect_hint => $connect_hint,
    );
}

=head2 get_indices

    my $indices = $object->get_indices;

    # use it...

Returns a basic instance of L<Data::AnyXfer::Elastic::Indices>
using the objects own information.

=cut

sub get_indices {

    my ( $info, %opts ) = @_;
    my $connect_hint = $opts{connect_hint};

    # if there was no direct connection hint,
    # look for one in the index info
    if ( !$connect_hint && $info->can('connect_hint') ) {
        $connect_hint = $info->connect_hint;
    }

    return Data::AnyXfer::Elastic::Indices->new(
        silo         => $info->silo,
        connect_hint => $connect_hint,
    );
}

=head2 new_anon_project

    my $project = $object->new_anon_project;

Returns an anonymous project consumer which uses this instance to
satisfy its C<index_info> requirement.

See L<Data::AnyXfer::Elastic:Role::Project>.

=cut

sub new_anon_project {

    my $info = $_[0];

    my $meta = Moose::Meta::Class->create_anon_class(
        methods => {
            index_info => sub {$info}
        },
        roles => ['Data::AnyXfer::Elastic::Role::Project'],
        # XXX : Because we use a closure to inject the index_info method
        # Moo is not able to differentiate different project classes,
        # so we EXPLICITLY disable caching here
        cache => 0,
    );

    return $meta->new_object;
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

