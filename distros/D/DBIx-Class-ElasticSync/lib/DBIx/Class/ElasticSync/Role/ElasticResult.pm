package DBIx::Class::ElasticSync::Role::ElasticResult;

use strict;
use warnings;

use Moose::Role;

=head2

dispatches the Result, builds the needed DBIC ResultSet and gives it to the Indexing function

=cut

sub es_index {

    my $self = shift;

    my $schema = $self->result_source->schema;
    my $class  = $self->result_source->source_name;

    my $elastic_rs = $schema->dispatcher->{$class};

    for my $rs (@$elastic_rs) {

        next unless $self->schema->es_is_registered_rs($rs);

        eval "use $rs";

        die $@ if $@;

        my $obj     = $self->es_obj_builder($rs);
        my $dbic_rs = $self->es_dbic_builder( $rs, $obj );

        $rs->es_index($dbic_rs);
    }
}

=head2 es_obj_builder

Reloads the Object from the Database to get a clean Row Object

=cut

sub es_obj_builder {

    my $self = shift;
    my $rs   = shift;

    my $class = $self->result_source->source_name;

    my $obj = $self;

    # Reload from db
    $obj->discard_changes;

    return $obj;

}

=head2 es_dbic_builder

Builds the Resultset for Indexing

=cut

sub es_dbic_builder {

    my $self = shift;
    my $rs   = shift;
    my $obj  = shift;

    my $dbic_rs     = $rs->index_rs;
    my $me          = $dbic_rs->current_source_alias;
    my $dbic_params = { map { $me . "." . $_ => $obj->$_ } $obj->result_source->primary_columns };

    $dbic_rs = $dbic_rs->search_rs($dbic_params);

    return $dbic_rs;
}

=head2 es_delete

Dispatches and give the DBIC Resultset to the delete function

=cut

sub es_delete {

    my ( $self, $orig ) = @_;

    my $schema = $self->result_source->schema;
    my $class  = $self->result_source->source_name;

    my $elastic_rs = $schema->dispatcher->{$class};

    my $is_primary = 0;

    for my $rs (@$elastic_rs) {

        eval "use $rs";

        die $@ if $@;

        my $obj = $self->es_obj_builder($rs);
        my $dbic_rs = $self->es_dbic_builder( $rs, $obj );

        if ( $rs->es_is_primary($class) ) {

            $rs->es_delete($dbic_rs);
            $is_primary = 1;

        } elsif ( $rs->es_is_nested($class) ) {

            $self->$orig if $self->in_storage;
            $rs->es_index($dbic_rs);
        }
    }

    $self->$orig if $is_primary;
}

after 'insert' => sub {
    my $self = shift;

    warn "Inserting ...\n";
    $self->es_index;
};

after 'update' => sub {
    my $self = shift;

    warn "Updating ...\n";
    $self->es_index;
};

around 'delete' => sub {
    my $orig = shift;
    my $self = shift;

    warn "Deleting...\n";
    $self->es_delete($orig);
};

sub es_index_transfer {

    my ( $self, $body ) = @_;

    my $type = $self->result_source->name;

    my $parent = {};
    if ( $self->es_is_child ) {

        $parent = { parent => $self->es_parent };
    }

}

sub schema {

    return shift->result_source->schema;
}

sub es {

    return shift->schema->es;
}

1;
