package DBIx::NoSQL::Model::Index;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::Model::Index::VERSION = '0.0021';
use strict;
use warnings;

use Moose;
use Clone qw/ clone /;
use Digest::SHA qw/ sha1_hex /;
use DBIx::NoSQL::Search;

has model => qw/ is ro required 1 weak_ref 1 /, handles => [qw/ store storage /];

has prepared => qw/ is rw isa Bool default 0 /;

has key_column => qw/ is rw isa Str lazy_build 1 /;
sub _build_key_column { 'key' }

has [qw/ create_statement drop_statement schema_digest /] => qw/ is rw isa Maybe[Str] /;

has result_class_scaffold => qw/ is ro lazy_build 1 /;
sub _build_result_class_scaffold { return DBIx::NoSQL::ClassScaffold->new->become_ResultClass }
has result_class => qw/ is ro lazy_build 1 /;
sub _build_result_class { return shift->result_class_scaffold->package }

sub search {
    my $self = shift;

    $self->prepare;

    my $search = DBIx::NoSQL::Search->new( model => $self->model );

    if ( @_ ) {
        $search->_where( $_[0] );
    }

    return $search;
}

sub update {
    my $self = shift;
    my $key = shift;
    my $target = shift;

    $self->prepare;

    my $model = $self->model;

    my $data = $target;
    if ( $data && ! ref $data ) {
        $data = $model->deserialize( $target );
    }

    my %set;
    $set{ $self->key_column } = $key;
    while( my ( $field, $column ) = each %{ $model->_field2column_map } ) {
        $set{ $column } = $data->{ $field };
    }

    $self->store->schema->resultset( $self->model->name )->update_or_create(
        \%set, { key => 'primary' },
    );
}

sub delete {
    my $self = shift;
    my $key = shift;

    $self->prepare;

    my $result = $self->store->schema->resultset( $self->model->name )->find(
        { $self->key_column => $key },
        { key => 'primary' }
    );
    if ( $result ) {
        $result->delete;
    }
}

sub prepare {
    my $self = shift;

    return if $self->prepared;

    $self->register_result_class;

    if ( ! $self->exists ) {
        $self->deploy;
    }
    elsif ( ! $self->same ) {
        if ( 1 ) {
            $self->redeploy;
        }
        else {
            my $model = $self->model->name;
            die "Unable to prepare index for model ($model) because index already exists (and is different)";
        }
    }

    $self->prepared( 1 );
}

sub register_result_class {
    my $self = shift;

    my $model = $self->model;
    my $store = $self->store;
    my $schema = $store->schema;
    my $name = $self->model->name;
    my $result_class = $self->result_class;

    $schema->unregister_source( $name ) if $schema->source_registrations->{ $name };

    {
        unless ( $result_class->can( 'result_source_instance' ) ) {
            $result_class->table( $name );
        }

        my $key_column = $self->key_column;
        unless( $result_class->has_column( $key_column ) ) {
            $result_class->add_column( $key_column => {
                data_type => 'text'
            } );
        }
        unless( $result_class->primary_columns ) {
            $result_class->set_primary_key( $key_column );
        }

        for my $field ( values %{ $model->field_map } ) {
            next unless $field->index;
            unless( $result_class->has_column( $field->name ) ) {
                $field->install_index( $model, $result_class );
            }
        }
    }

    $schema->register_class( $name => $result_class );

    my $table = $result_class->table;
    my $deployment_statements = $schema->build_deployment_statements;
    my @deployment_statements = split m/;\n/, $deployment_statements;
		my ( $create ) = grep { m/(?:(?i)CREATE\s+TABLE\s+.*)$table/ } @deployment_statements;
    my ( $drop ) = grep { m/(?:(?i)DROP\s+TABLE\s+.*)$table/ } @deployment_statements;

    s/^\s*//, s/\s*$// for $create, $drop;

    $self->create_statement( $create );
    $self->drop_statement( $drop );
    $self->schema_digest( sha1_hex $create );
}

sub stash_schema_digest {
    my $self = shift;
    my $model = $self->model->name;
    return $self->store->stash->value( "model.$model.index.schema_digest", @_ );
}

sub exists {
    my $self = shift;

    return $self->storage->table_exists( $self->model->name );
}

sub same {
    my $self = shift;

    return unless my $stash_schema_digest = $self->stash_schema_digest;
    return unless my $schema_digest = $self->schema_digest;
    return $schema_digest eq $stash_schema_digest;
}

sub deploy {
    my $self = shift;

    if ( $self->exists ) {
        if ( $self->same ) {
            return;
        }
        else {
            my $model = $self->model->name;
            warn "Index schema mismatch for model ($model)";
            return;
        }
    }

    $self->_deploy;
}

sub _deploy {
    my $self = shift;
    $self->store->storage->do( $self->create_statement );
    $self->stash_schema_digest( $self->schema_digest );
}

sub undeploy {
    my $self = shift;
    $self->store->storage->do( $self->drop_statement );
}

sub redeploy {
    my $self = shift;
    my %options = @_;

    exists $options{ $_ } or $options{ $_ } = 1 for qw/ register /;

    $self->register_result_class if $options{ register };
    $self->undeploy;
    $self->_deploy;
    $self->reload;
    $self->prepared( 1 );
}

sub reload {
    my $self = shift;

    my @result = $self->model->_store_set->search( { __model__ => $self->model->name } )->all;
    for my $result ( @result ) {
        $self->update( $result->get_column( '__key__' ), $result->get_column( '__value__' ) );
    }
}

sub reset {
    my $self = shift;
    $self->register_result_class;
}

sub reindex { return shift->redeploy( @_ ) }
sub migrate { return shift->redeploy( @_ ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::Model::Index

=head1 VERSION

version 0.0021

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
