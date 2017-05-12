package DBIx::Class::ElasticSync::Role::ElasticSchema;

use strict;
use warnings;

use Moose::Role;

has es_store => (
    is  => 'rw',
    isa => 'Maybe[Object]'
);

has connect_elasticsearch => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    default  => sub { },
);

=head2 es

Builds a Search::Elasticsearch Object based on the given Config. It holds the Object in Memory while Runtime

	$schema->connect_elasticsearch( host => "localhost", port => 9200, cxn => undef, debug => 0 );
	my $es = $schema->es;

=cut

sub es {

    my ($self) = @_;

    if ( !$self->es_store ) {

        my $settings = $self->connect_elasticsearch;

        if ( $settings->{debug} ) {

            delete $settings->{debug};
            $settings->{trace_to} = 'Stderr';
            eval "use Log::Any::Adapter qw(Stderr);";
        }

        $self->es_store( Search::Elasticsearch->new( %$settings ) );

    }

    return $self->es_store;
}

=head2 es_dispatch

Collects dispatching Informations from called ElasticResultSet

=cut

sub es_dispatch {

    my $self  = shift;
    my $class = shift;

    return unless $class;

    return $self->dispatcher->{$class};
}

=head2 es_is_registered_rs

checks if ElasticResultSet is active for the Application

=cut

sub es_is_registered_rs {

    my ( $self, $rs ) = @_;

    return 1 if grep { $_ eq $rs } @{ $self->connect_elasticsearch->{registered_elastic_rs} };
}

sub es_index_name {

    my $self = shift;
    return $self->connect_elasticsearch->{index} || ref $self;
}

=head2 es_index_all

Batch indexes all data in RDMS Storage for the registered ElasticResultSets

=cut

sub es_index_all {

    my $self = shift;

    my $registered_elastic_rs = $self->connect_elasticsearch->{registered_elastic_rs};

    foreach my $rs (@$registered_elastic_rs) {

        eval "use $rs";

        warn $@ if $@;

        $rs->es_batch_index;
    }

}

=head2 es_index_obj

push a Document from BlackholeResults to the Index

=cut

sub es_index_obj {

    my $self = shift;
    my $obj  = shift;

    my $additional = {};

    if ( $obj->{_parent} ) {

        $additional->{parent} = delete $obj->{_parent};
    }

    $self->es->index(
        {
            index => $obj->{type},
            id    => $obj->{body}->{es_id},
            type  => $obj->{type},
            body  => $obj->{body},
            %$additional,
        }
    );
}

sub es_create_index {

    my $self = shift;

    $self->es->indices->create( index => $self->es_index_name, );
}

=head2 es_collect_mappings

Collects mapping templates from the registered Resultsets and push them to the Elasticsearch Storage

=cut

sub es_collect_mappings {

    my ($self) = @_;

    my $registered_elastic_rs = $self->connect_elasticsearch->{registered_elastic_rs};

    foreach my $rs (@$registered_elastic_rs) {

        eval "use $rs";

        warn $@ if $@;

        my $mapping = $rs->mapping;

        $self->es->indices->put_template(
            name => $rs->type,
            body => $rs->mapping,

        );
    }

}

=head2 drop_indexes

drops all Elastic Indexes

=cut

sub drop_indexes {

    my ($self) = shift;

    my $registered_elastic_rs = $self->connect_elasticsearch->{registered_elastic_rs};

    my $deleted_index = {};

    foreach my $rs (@$registered_elastic_rs) {

        eval "use $rs";

        warn $@ if $@;

        if ( !$deleted_index->{ $rs->index_name } ) {

            $deleted_index->{ $rs->index_name } = 1;
            $self->es->indices->delete(
                index  => $rs->index_name,
                ignore => 404,
            );
        }
    }

}

sub es_drop_mapping {

    my $self = shift;

    my $types   = [];
    my @sources = $self->sources;

    for my $source (@sources) {

        my $rs          = $self->resultset($source);
        my $source_info = $rs->result_source->source_info;

        next unless $source_info && $source_info->{es_index_type} eq 'primary';

        next unless $rs->can('es_has_searchable') && $rs->es_has_searchable;

        warn "delete mapping $source";

        $self->es->indices->delete_mapping(
            index  => $self->es_index_name,
            type   => $source,
            ignore => 404,
        );
    }

}

=head2 es_create_repository

Creates repository for Elastic Snapshot API

=cut

sub es_create_repository {

    my ( $self, $repository, $body ) = @_;

    return unless $repository;

    $body = {} unless ref $body;

    $self->es->snapshot->create_repository(
        repository => $repository,
        body       => $body,
    );
}

=head2 es_create_snapshot

creates a snapshot

=cut

sub es_create_snapshot {

    my ( $self, $repository, $snapshot, $body ) = @_;

    return unless $repository && $snapshot;

    $body = {} unless ref $body;

    $self->es->snapshot->create(
        repository => $repository,
        snapshot   => $snapshot,
        body       => $body,
    );
}

=head2 es_restore_snapshot

restores a snapshot

=cut

sub es_restore_snapshot {

    my ( $self, $repository, $snapshot, $body ) = @_;

    return unless $repository && $snapshot;

    $body = {} unless ref $body;

    $self->es->snapshot->restore(
        repository => $repository,
        snapshot   => $snapshot,
        body       => $body,
    );
}

1;
