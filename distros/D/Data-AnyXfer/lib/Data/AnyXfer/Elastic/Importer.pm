package Data::AnyXfer::Elastic::Importer;

use Moo;
use MooX::HandlesVia;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;
use Try::Tiny;

use Data::AnyXfer ();
use Data::AnyXfer::Elastic ();
use Data::AnyXfer::Elastic::Logger;

require Data::AnyXfer::Elastic::Import::SpawnTask;
require Data::AnyXfer::Elastic::Import::SpawnTask::Remote;
require Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host;

=head1 NAME

Data::AnyXfer::Elastic::Importer

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Importer;

    my $importer = Data::AnyXfer::Elastic::Importer->new(
        logger => Data::AnyXfer::Elastic::Logger->new,
    );

    my $datafile = DataFile->new( file => 'my/project.datafile' );

    # Put this live on the relevant clusters
    my $response = $importer->deploy( datafile => $datafile );

    # alternativly, you can deploy in steps..
    See source of C<deploy>


=head1 DESCRIPTION

The Elasticsearch B<Importer> is designed to take a datafile and stream the
index into Elasticsearch cluster(s). This process is known as playing the
datafile. The process creates a index with the mappings/settings defined in the
datafile. It will create indexes on multiple clusters depending on the silo
given. Once the index has been created it can then be finalise which makes the
index B<live> by switching over the alias.

=cut

# Lower the bulk helper max count for memory efficiency at a small
# speed cost (as our boxes tend to have less memory than standard)
use constant DEFAULT_BULK_MAX_COUNT => 500;

# How long to wait in seconds after populating the index for the document
# count to reach the epxected number, before marking the import as a failure
use constant DEFAULT_WAIT_COUNT_TIMEOUT => Data::AnyXfer->test ? 60 : 10;

=head1 ATTRIBUTES

=item logger

Logs events and errors to file. A instance of a
C<Data::AnyXfer::Elastic::Logger>.

=item bulk_max_count

Perl number. Defaults to 500.
The maximum number of items which will be sent by the bulk helper before a
flush is performed.

=item wait_count_timeout

Perl number. Defaults to 10.
The maximum number of seconds to wait after indexing for the number of visible
documents in the index to reach the expected count before treating the import
as a failure.

=item delete_before_create

Boolean. Defaults to 0.
When true, the importer instance will attempt to delete the index
before creating them during L<./execute>.

=item document_id_field

String. Optional.

Allows you to specify a field on each document which will also be supplied
to elasticsearch as the document's C<_id>.

=back

=cut

has logger => (
    is      => 'ro',
    isa     => InstanceOf['Data::AnyXfer::Elastic::Logger'],
    default => sub {
        return Data::AnyXfer::Elastic::Logger->new(
            screen => 0,
            file   => 1,
        );
    },
);

has es => (
  is  => 'ro',
  isa => InstanceOf['Data::AnyXfer::Elastic'],
  default => sub {
    return Data::AnyXfer::Elastic->default;
  },
);

has delete_before_create => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has bulk_max_count => (
    is      => 'rw',
    default => DEFAULT_BULK_MAX_COUNT,
);

has wait_count_timeout => (
    is      => 'rw',
    default => DEFAULT_WAIT_COUNT_TIMEOUT,
);

has document_id_field => (
    is  => 'rw',
    isa => Str,
);

has current_child_pid => (
    is  => 'rw',
    isa => Maybe[Int],
);

has remote_host => (
    is  => 'ro',
    isa => Str,
);

has remote_port => (
    is  => 'ro',
    isa => Int,
);

has remote_user => (
    is  => 'ro',
    isa => Str,
);

has identity_file => (
    is  => 'ro',
    isa => InstanceOf['Path::Class::File'],
);

has _remote_host_instance => (
    is      => 'ro',
    isa     => Maybe[InstanceOf['Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host']],
    lazy    => 1,
    builder => '_build_remote_host_instance',
);

has _finalise_called => (
    is       => 'rw',
    init_arg => undef,
    default  => sub { return 0 },
);

has _cache => (
    is       => 'rw',
    isa      => ArrayRef[ArrayRef],
    init_arg => undef,
    lazy     => 1,
    default  => sub { return [] },
    handles_via => 'Array',
    handles     => {
        _count_cache => 'count',
        _reset_cache => 'clear',
        _list_cache  => 'elements',
    }
);

has _errors => (
    is       => 'rw',
    isa      => ArrayRef[InstanceOf['Search::Elasticsearch::Error::Request']],
    init_arg => undef,
    lazy     => 1,
    default  => sub { return [] },
    handles_via => 'Array',
    handles     => {
        _count_errors => 'count',
        _reset_errors => 'clear',
        errors        => 'elements',
    }
);


# ROLE IMPLEMENTATION
with 'Data::AnyXfer::Elastic::Role::Importer_ES2';


=head1 METHODS

=head2 deploy

This method "plays" the datafile. It streams the data from the datafile into
Elasticsearch. It creates a unique index based on the datafiles' time-stamp and
will assign the mapping, settings etc. Datafile documents are then streamed
into the index via the bulk helper. Finally it swaps the aliases making the
index 'live'.

    my $response = $importer->deploy(
        datafile         => $datafile,        # required
        silo             => 'public_data',    # optional
        no_finalise      => 1,                # optional, does not call finalise
    );

=over

=item datafile

A required C<Data::AnyXfer::Elastic::Import::DataFile> object that
defines the content and configuration of an Elasticsearch index.

=item silo

A optional string that overrides the silo defined in C<$datafile> index info.

=item no_finalise

An optional bool indicating whether to run finalise at the end of the
successful deployment of the datafile to all intended nodes and clusters
(defaults to C<1>).

Useful for situation where you need to delay or co-ordinate switching
the data over with some other action.

=back

=cut

sub deploy {
    my ( $self, %args ) = @_;

    eval {

        # fetch Elasticsearch clients tagged with silo
        my $silo = defined $args{silo} ? $args{silo} : $args{datafile}->silo;

        # Let's find out clients for the import
        my ( @clients, @proxy_host_values );
        if ( $args{clients} ) {

            # allow clients to be supplied directly to deploy
            # (We do not support proxy host values when this is done. You must
            # use the remote_* attrs when creating this Importer instance if
            # you wish to use one)
            @clients = @{ $args{clients} };
        } else {
            # otherwise as normal, use the silo to fetch the clients
            @clients = $self->es->all_clients_for($silo);

            # also fetch any proxy host definitions for use as the remote host
            # for playing data (lists are ordered so positionally matches the
            # clients)
            @proxy_host_values
                = Data::AnyXfer::Elastic::ServerList
                ->get_proxy_host_for_nodes($silo);
        }

        croak "Could not attain clients from ${silo}" unless @clients;

        my $datafile = $args{datafile};
        my ( @process_list, @skips );
        for (@clients) {

            # see if we have a proxy host we must use for connecting to the
            # target nodes
            my $proxy_host
                = @proxy_host_values ? shift @proxy_host_values : undef;

            # do a basic index existence check here so that we don't
            # cleanup indexes we did not create
            if ( $self->delete_before_create
                || !$_->indices->exists( index => $datafile->index ) )
            {
                push @skips, 0;

                my $process = $self->_spawn_task(
                    proxy_host           => $proxy_host,
                    datafile             => $datafile,
                    client               => $_,
                    verbose              => $self->logger->screen ? 1 : 0,
                    delete_before_create => $self->delete_before_create,
                    bulk_max_count       => $self->bulk_max_count,
                );
                push @process_list, $process;

                sleep 3;    # we pause to allow memory usage to settle

            } else {
                push @skips, 1;

                $self->logger->error(
                    index_info => $datafile,
                    text       => 'Encountered a problem running datafile',
                    content    => 'Index already exists',
                    client     => $_,
                );
            }
        }

        # sychronise with children before continuing
        # (if we hit a timeout, this will be handled and cleaned up )
        foreach (@process_list) { $_->wait }

        # we managed to create the index, so we will need to clean it up
        # add the client/datafile combination to the cache
        for ( reverse @clients ) {
            push @{ $self->_cache }, ( [ $_, $datafile ] ) unless pop @skips;
        }

        # wait for the document count to synchronise across all elasticsearch
        # clusters (or die, as data must be the same everywhere)
        $self->_wait_for_doc_count(
            target_doc_count => $datafile->get_document_count,
            index_name       => $datafile->index,
            clients          => \@clients,
            timeout          => $self->wait_count_timeout,
        );
    };

    # Adding index didn't work
    if ( $@ || $self->errors ) {
        my @errors = $self->errors;
        push @errors, $@ if $@;

        # cleanup any indices we created and croak
        $self->cleanup;
        croak join( "\n", @errors, 'Failed to import datafile. Aborting...' );
    }

    # Finalise unless disabled
    unless ( $args{no_finalise} ) {

        # try to finalise, otherwise die with errors
        unless ( $self->finalise ) {
            my $datafile = $args{datafile};
            croak sprintf
                'finalise() failed! cleanup manually! see logs for details '
                . '(index: %s, alias: %s)',
                $datafile->index,
                $datafile->alias;
        }
    }
    return 1;
}


# LOCAL AND REMOTE TASK SPAWNING

sub _spawn_task {
    my ( $self, %args ) = @_;

    my $process;

    # check if we have been supplied remote host information
    # if we have, spawn a remote import task
    my $remote_host = $self->_remote_host_instance;
    my $proxy_host  = delete $args{proxy_host};

    # we can also be supplied a 'proxy host' value from the es server
    # definition, so use this as a fallback
    if ( !$remote_host && $proxy_host ) {
        $remote_host
            = Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host
            ->new( %{$proxy_host} );
    }

    # now we need to spawn the right kind of process
    if ($remote_host) {
        # if we have a remote host, we need to create a remote task
        return Data::AnyXfer::Elastic::Import::SpawnTask::Remote->run(
            remote_host_instance => $remote_host,
            %args,
        );
    }
    # otherwise, spawn a normal local task
    return Data::AnyXfer::Elastic::Import::SpawnTask->run(%args);
}


sub _build_remote_host_instance {
    my $self = $_[0];

    return unless $self->remote_host;

    # build host instance to represent the target host
    my %host_args = (
        host          => $self->remote_host,
        port          => $self->remote_port,
        user          => $self->remote_user,
        identity_file => $self->identity_file
    );

    # remove undef values
    foreach ( keys %host_args ) {
        delete $host_args{$_} unless defined $host_args{$_};
    }

    # return remote host instance
    return
        Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host->new(
        %host_args);
}



=head2 execute

Use c<deploy> where you can, if you have to do it as several
steps (import index, do something else, switch aliases), then
see the source of the c<deploy> method.

    my $elastic = Data::AnyXfer::Elastic->new;
    my @clients = $elastic->all_clients_for($silo);

    foreach my $client ( @clients ) {

        $importer->execute(
            datafile         => $datafile,     # required
            elasticsearch    => $client,       # required
        );

    }


This method takes a datafile and plays it into Elasticsearch. It differs from
C<deploy> because it does not automatically finalise it. It returns the number
of documents played on successful execution, or C<undef> on error. The argument
I<elasticsearch> must be a Search::Elasticsearch object generated from
C<Data::AnyXfer::Elastic>. If not provided then a client will be
generated from the datafile silo configuration.

=cut

sub execute {
    my ( $self, %args ) = @_;

    croak "Can not call execute() as finalise() has been called"
        if $self->_finalise_called();

    my $count         = 0;
    my $elasticsearch = $args{elasticsearch};
    my $datafile      = $args{datafile};

    eval {
        $self->logger->info(
            index_info => $datafile,
            text       => 'Executing datafile '
                . $datafile->storage->get_destination_info,
            content => undef,
            client  => $elasticsearch,
        );

        # create and prepare the index for bulk indexing
        $self->_create_index( $elasticsearch, $datafile );
        $self->logger->info(
            index_info => $datafile,
            text => sprintf( 'Index created (name: %s)', $datafile->index ),
            content => undef,
            client  => $elasticsearch,
        );

        # to simulate a error in testing only
        if ( $args{_sim_error} && Data::AnyXfer->test ) {
            croak 'simulated error';
        }

        # stream all data into the index
        $count = $self->_populate_index( $elasticsearch, $datafile );
        $self->logger->info(
            index_info => $datafile,
            text => "Finished populating documents in index (count: $count)",
            content => undef,
            client  => $elasticsearch,
        );

        # prepare settings to make the index operational
        # so it is safe to "finalise"
        $self->_prepare_index( $elasticsearch, $datafile );
        $self->logger->info(
            index_info => $datafile,
            text       => 'Index settings updated',
            content    => undef,
            client     => $elasticsearch,
        );

    };

    if ( my $error = $@ ) {

        $self->logger->error(
            index_info => $datafile,
            text       => 'Encountered a problem running datafile',
            content    => $error,
            client     => $elasticsearch,
        );

        push @{ $self->_errors }, $error;
        return undef;

    }

    return $count;
}

# _create_index - initialises an index for datafile execution
sub _create_index {

    my ( $self, $elasticsearch, $datafile, $index ) = @_;

    # if no index was supplied, trust the datafile
    $index ||= $datafile->index;

    # if configured, attempt to remove the index first
    if ( $self->delete_before_create ) {
        my $index = $datafile->index;
        eval {
            $elasticsearch->indices->delete( index => $index );
            $self->logger->info(
                index_info => $datafile,
                text =>
                    "Deleted existing index, as 'delete_before_create' was enabled (name: $index)",
                content => undef,
                client  => $elasticsearch,
            );
        };
    }

    # create the index - aliases is not passed because this will
    # make the index immediately live.
    my $body = {
        settings => $datafile->settings,
        warmers  => $datafile->warmers
    };

    if ( $elasticsearch->api_version =~ /^2/ ) {
        # XXX : Support ES 2.3.5 (TO BE REMOVED)
        $body->{mappings} = $datafile->es235_mappings;
    } else {
        # XXX : Support ES 6.x
        $body->{mappings} = $datafile->mappings;
    }

    # disable the refresh interval
    # (as this module will always want to throw all the data at elasticsearch
    # at once)
    my $settings = ( $body->{settings} ||= {} );
    $settings->{'index.refresh_interval'} = -1;

    # create the index
    $elasticsearch->indices->create(
        index => $index,
        body  => $body,
    );

    # we managed to create the index, so we will need to clean it up
    # add the client/datafile combination to the cache

    # XXX : We must check if we're not the main process
    # as it has to be done in the parent when running with multiple processes
    unless ( $self->current_child_pid ) {
        push @{ $self->_cache }, ( [ $elasticsearch, $datafile ] );
    }

    return 1;
}

# _populate_index - populates an elasticsearch index with datafile data
sub _populate_index {

    my ( $self, $elasticsearch, $datafile, $index ) = @_;

    # if no index was supplied, trust the datafile
    $index ||= $datafile->index;

    # prepare for bulk operation
    my $bulk = $elasticsearch->bulk_helper(
        max_count => $self->bulk_max_count,
        index     => $index,
        type      => $datafile->type,
    );

    # XXX : Support ES 2.3.5
    my $es_235_support = $elasticsearch->api_version =~ /^2/;

    # callback function to extract data and stream them to Elasticsearch.
    # Note that the id for the document is auto-generated by
    # Elasticsearch.
    my $count = 0;
    my $doc_handler;

    if ( my $id_field = $self->document_id_field ) {

        # index documents with an id field
        $doc_handler = sub {
            for (@_) {
                # XXX : Support ES 2.3.5
                $self->convert_document_for_es2($_) if $es_235_support;
                $bulk->index( { id => $_->{$id_field}, source => $_ } );
            }
            $count += scalar @_;
        };
    } else {

        # index documents without (will be auto generated from the doc uid)
        $doc_handler = sub {
            for (@_) {
                # XXX : Support ES 2.3.5
                $self->convert_document_for_es2($_) if $es_235_support;
                $bulk->index( { source => $_ } );
            }
            $count += scalar @_;
        };
    }

    $datafile->fetch_data($doc_handler);

    $bulk->flush;
    return $count;
}

# _create_index - configure an index to make it ready to query against
#  undo any optimisations made for initial population
sub _prepare_index {

    my ( $self, $elasticsearch, $datafile, $index ) = @_;

    # if no index was supplied, trust the datafile
    $index ||= $datafile->index;

    # update index settings for operation
    my $settings = $datafile->settings;

    # set the configured refresh interval, or default
    # (this would have been disabled by us in _create_index)
    my $refresh_interval = $settings->{'index.refresh_interval'} || '1s';

    # update the index
    $elasticsearch->indices->put_settings(
        index => $index,
        body  => { 'index.refresh_interval' => $refresh_interval },
    );

    return 1;
}

=head2 finalise

    $importer->finalise;

This method finalises deployment by switching aliases for each datafile
executed. It will concurrently add the alias to the new index while removing
any previous associations, see c<deploy> source before using this directly.

=cut

sub finalise {
    my ( $self, %args ) = @_;

    croak "Can not call finalise() twice" if $self->_finalise_called();

    # Flag this so we do not call again!
    $self->_finalise_called(1);

    my $datafile_scoped;
    eval {
        for ( $self->_list_cache ) {

            my $elasticsearch = $_->[0];
            my $datafile = $datafile_scoped = $_->[1];

            my $index   = $datafile->index;
            my $alias   = $datafile->alias;
            my @aliases = keys @{$datafile->aliases};

            # fetch old indices that are attached to that alias
            my @past = eval {
                keys @{$elasticsearch->indices->get_alias( name => $alias )};   #
            };
            undef $@;

            # build alias actions
            my @add =                                                        #
                map { { add => { alias => $_, index => $index } } } @aliases;
            my @remove =                                                     #
                map { { remove => { alias => $alias, index => $_ } } } @past;

            # build update body and perform switch
            my %body = ( body => { actions => [ @add, @remove ] } );
            $elasticsearch->indices->update_aliases(%body);
            $self->logger->info(
                index_info => $datafile,
                text       => 'Finalised',
                content    => \%body,
                client     => $elasticsearch,
            );

        }

        $self->_reset_cache;

    };

    if ( my $error = $@ ) {

        $self->logger->error(
            index_info => $datafile_scoped,
            text       => 'Encountered a problem finalising index',
            content    => $error,
        );

        push @{ $self->_errors }, $error;
        return 0;

    }

    return 1;
}

=head2 errors

    my $errors = $importer->errors;

List the errors that have occurred.

=head2 cleanup

    $importer->cleanup;

This method removes all indexes the importer has created and will empty the
cache. This can not be called if finalise() has been called already.

=cut

sub cleanup {
    my $self = shift;

    croak "Can not call automatic cleanup as finalise() has been called"
        if $self->_finalise_called();

    for ( $self->_list_cache ) {

        eval { $_->[0]->indices->delete( index => $_->[1]->index ) };

    }

    $self->_reset_cache;
    $self->_reset_errors;

    return 1;
}

# alias for Utils->wait_for_doc_count
sub _wait_for_doc_count {
    &Data::AnyXfer::Elastic::Utils::wait_for_doc_count;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

