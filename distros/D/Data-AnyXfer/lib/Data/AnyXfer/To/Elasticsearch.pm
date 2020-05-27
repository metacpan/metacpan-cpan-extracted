package Data::AnyXfer::To::Elasticsearch;

use v5.16.3;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

use Clone qw/ clone /;

use Data::AnyXfer::Elastic::Index;
use Data::AnyXfer::Elastic::Indices;

requires 'log';

with 'Data::AnyXfer::Role::Elasticsearch';


=head1 NAME

Data::AnyXfer::To::Elasticsearch - transfer to Elasticsearch

=head1 SYNOPSYS

TODO

=head1 DESCRIPTION

TODO

=cut

has 'sig_column' => (
    is      => 'ro',
    isa     => Str,
);

has 'id_column' => (
    is      => 'ro',
    isa     => Str,
    default => 'id',
);

has 'allow_preexisting_index' => (
    is  => 'ro',
    isa => Bool,
);

around 'initialize' => sub {
    my ( $orig, $self, @args ) = @_;

    $self->$orig(@args) or return;

    my $log     = $self->log;
    my $index   = $self->index_info->index;
    my $aliases = $self->index_info->aliases;

    # Setup index
    my $indices = $self->index_info->get_indices;

    # clear index if it already exists
    if ( !$self->allow_preexisting_index
      && $indices->exists( index => $index ) ) {
        $indices->delete( index => $index )
            or $log->logdie("Unable to delete index ${index}");
    }

    # detect mappings to use
    my $api_version = $indices->elasticsearch->api_version;
    my $mappings;

    if ( $api_version =~ /^2/ ) {
        # XXX : Support ES 2.3.5 (TO BE REMOVED)
        $mappings = $self->index_info->es235_mappings;
    } else {
        # XXX : Support ES 6.x
        $mappings = $self->index_info->mappings;
    }

    # create the index without any aliases
    # (this will be done in finalize)
    $indices->create(
        index => $index,
        body  => {
            mappings => $mappings,
            settings => $self->index_info->settings,
            warmers  => $self->index_info->warmers,
        }
    ) or $log->logdie("Unable to create index ${index}");

    return 1;
};

around 'store' => sub {
    my ( $orig, $self, $rec ) = @_;

    $self->$orig($rec) or return;

    my $h = $self->_bulk;

    my $data = clone($rec);

    my $id = delete $data->{ $self->id_column };

    my $created = $h->index(
        {   index  => $self->index_info->index,
            type   => $self->index_info->type,
            id     => $id,
            source => $data,
        }
    );
    $self->log->logdie("store failed for id ${id}")
        unless $created;

    return 1;
};

around 'finalize' => sub {
    my ( $orig, $self ) = @_;

    $self->$orig or return;

    my $h             = $self->_bulk;
    my $index         = $self->index_info->index;
    my $primary_alias = $self->index_info->alias;
    my $aliases       = $self->index_info->aliases;

    $h->flush or $self->log->logdie("flush failed");

    # Define final aliases
    # and quietly clean up anything else on our primary alias

    my $indices = $self->index_info->get_indices;

    # build actions
    my ( @removes, @adds );

    # add
    push @adds, { add => { index => $index, alias => $_ } }
        foreach ( keys %{$aliases} );

    # remove (we only clean-up the primary alias)
    # we won't mess with any other aliases defined
    # - these would need custom cleanup
    push @removes, { remove => { index => '*', alias => $primary_alias } };

    # create the final aliases
    $indices->update_aliases( body => { actions => [ @removes, @adds ] } );

    return 1;
};



use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

