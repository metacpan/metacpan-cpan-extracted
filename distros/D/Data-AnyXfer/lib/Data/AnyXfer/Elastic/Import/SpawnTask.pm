package Data::AnyXfer::Elastic::Import::SpawnTask;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);




use Data::UUID ();
use IPC::Run3  ();
use Search::Elasticsearch;
use List::MoreUtils qw( uniq );

use Data::AnyXfer ();
use Data::AnyXfer::JSON qw( encode_json );
use Data::AnyXfer::Elastic::IndexInfo ();
use Data::AnyXfer::Elastic::Logger    ();
use Data::AnyXfer::Elastic::Importer  ();
use Data::AnyXfer::Elastic::Role::IndexInfo;
use Data::AnyXfer::Elastic::Import::DataFile;

use Data::AnyXfer::Elastic::Import::SpawnTask::Process ();

use constant PROCESS_CLASS =>
    qw(Data::AnyXfer::Elastic::Import::SpawnTask::Process);


=head1 NAME

Data::AnyXfer::Elastic::Import::SpawnTask - Play an import
in a separate background process

=head1 SYNOPSIS

    use Path::Class                               ();
    use Data::AnyXfer::Elastic                    ();
    use Data::AnyXfer::Elastic::Import::DataFile  ();
    use Data::AnyXfer::Elastic::Import::SpawnTask ();

    my $datafile = Data::AnyXfer::Elastic::Import::DataFile->new(
        file => Path::Class::file( 'my_data.datafile' )
    );

    # generate a task per client
    my @process_list;
    my $elastic = Data::AnyXfer::Elastic->new;
    foreach ($elastic->all_clients_for('public_data')) {
        my @args = (
            datafile             => $datafile,
            client               => $_,
            verbose              => 1,
            delete_before_create => 1,
        );
        push @process_list,
            Data::AnyXfer::Elastic::Import::SpawnTask->run(@args);
    }

    # wait for the tasks to complete
    foreach (@process_list) { $_->wait() }

=head1 DESCRIPTION

This module allows us to play a datafile using
L<Data::AnyXfer::Elastic::Importer>, asynchronously, using a background
process.

The background process will be spun up as a new process. You will be returned a
process object which you can inspect to track progress.

=head1 ATTRIBUTES

For internal use only.

=cut

has argsfile => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has datafile => (
    is       => 'ro',
    isa      => InstanceOf['Data::AnyXfer::Elastic::Import::DataFile'],
    required => 1,
);

has index_info => (
    is       => 'ro',
    does     => ConsumerOf['Data::AnyXfer::Elastic::Role::IndexInfo'],
    required => 1,
);

has client => (
    is       => 'ro',
    does     => InstanceOf['Search::Elasticsearch::Role::Client::Direct'],
    required => 1,
);

has verbose => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has delete_before_create => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has bulk_max_count => (
    is      => 'ro',
    isa     => Int,
    default => Data::AnyXfer::Elastic::Importer::DEFAULT_BULK_MAX_COUNT,
);


=head1 METHODS

=cut

# INSTANCE CREATION (FROM WITHIN TASK)

sub BUILDARGS {
    my ( $class, %args ) = @_;

    my $file = Path::Class::file( $args{argsfile} );
    croak "Argument 'file' does not exist at: $file" unless -f $file;

    my $data = Data::AnyXfer::JSON::decode_json(
        $file->slurp( iomode => '<:encoding(UTF-8)' ) );

    # re-enable test flags if we are in testmode
    Data::AnyXfer->test(1) if $data->{testmode};

    return {
        argsfile => "$file",
        datafile => $class->inflate_datafile_dir(
            $data->{datafile_dir}, $data->{datafile_label}
        ),
        index_info => $class->inflate_index_info( $data->{index_info} ),
        client     => $class->inflate_client_info( $data->{client_info} ),
        delete_before_create => $data->{delete_before_create},
        bulk_max_count       => $data->{bulk_max_count},
        verbose              => $data->{verbose},
    };
}

sub BUILD {
    my $self = $_[0];

    # RUN THE IMPORT ON CREATION
    $self->do_import;
}


# TASK SPAWNING

=head2 run

    my $process = Data::AnyXfer::Elastic::Import::SpawnTask->run(
        datafile             => $datafile,
        client               => $_,
        verbose              => 1,
        delete_before_create => 1,
        debug                => 1,
    );
    do_something(); # do something in the meantime
    $process->wait(); # wait for the import to complete

This is the primary method in this module (It should be called as a class
method).

It takes a named argument list, and returns a L<Proc::Background> instance
representing the import process. The process will die once the import is
complete, so if you need to you can call C<wait> to synchronise.

=cut

sub run {
    my ( $class, %args ) = @_;

    # ensure we have a datafile
    my $datafile = $args{datafile};
    croak 'datafile argument is required to spawn an import task'
        unless $datafile;

    # ensure we have a target client
    my $client = $args{client};
    croak 'client argument is required to spawn an import task'
        unless $client;

    # we need to pass on any connection information
    my @connections
        = map { $_->uri->as_string } @{ $client->transport->cxn_pool->cxns };

    # serialise information required for task into argsfile
    # to be picked up by the new process
    my $argsfile = $class->generate_argsfile(
        {   client_info  => \@connections,
            datafile_dir => $args{datafile_dir}
                || $datafile->storage->working_dir . '',
            datafile_label => $datafile->storage->get_destination_info . '',
            index_info     => $datafile->export_index_info->as_hash,
            delete_before_create => $args{delete_before_create},
            bulk_max_count       => $args{bulk_max_count},
            verbose              => $args{verbose},
            testmode             => Data::AnyXfer->test,
        }
    );

    # spawn process passing in the information we serialised
    my $process = $class->_run_self_with_argsfile( $argsfile, \%args );
    return $process;
}


# ARGUMENT SERIALISATION

sub _run_self_with_argsfile {
    my ( $class, $argsfile, $args ) = @_;

    my $verbose = $args->{debug};

    # build the command list
    # starts the perl interpretter and creates an instance of ourselves
    # passing in the argsfile as a string

    # make sure we use the same version of perl intepretter we're
    # currently running under

    my $command = sprintf                                          #
        q/ %1$s -M%2$s -E '%2$s->new( argsfile => q!%3$s! )' /,    #
        $^X, __PACKAGE__, $argsfile;                               #

    print "Executing in background: ${command}\n" if $verbose;

    # spawn a background process running the command
    # and return a process instance
    return $class->_exec_command($command, $args);
}


sub _exec_command {
    my ($class, $command, $args) = @_;

    # add syntax to capture pid to the end of the command
    $command .= ' > /dev/null & echo $!';

    # run the command in a new process and capture the pid
    my $pid;
    IPC::Run3::run3( [ qw/bash -c/, $command ], undef, \$pid );
    $pid = ( $pid =~ /^(\d+)/ )[0];

    # return a process instance representing the command
    # running in the background
    return PROCESS_CLASS()->new( pid => $pid );
}


sub generate_argsfile {
    my ( $class, $args ) = @_;

    # find a unique file name (accounts for clashes after shortening the UID)
    my ( $tmpdir, $file, $uuid ) = Data::AnyXfer->tmp_dir();
    do {
        $uuid = substr( Data::UUID->new()->create_str, 0, 10 );
        $file = $tmpdir->file($uuid);

    } while ( -f $tmpdir->file($uuid) );

    # serialise the arguments
    my $argsjson = encode_json($args);
    $file->spew( iomode => '>:raw', $argsjson );

    # return the file location / object
    return $file;
}


# ARGUMENT INFLATION

sub inflate_datafile_dir {
    my ( $class, $dir, $datafile_label ) = @_;

    # create datafile storage using the parent process working directory
    # XXX : use read-only mode so that the storage instance knows it is
    # safe to skip cloning the working directory
    my $storage
        = Data::AnyXfer::Elastic::Import::Storage::Directory->new(
        dir              => Path::Class::dir($dir),
        destination_info => $datafile_label,
        read_only        => 1,
        );

    return Data::AnyXfer::Elastic::Import::DataFile->new(
        storage => $storage );
}

sub inflate_index_info {
    my ( $class, $info ) = @_;
    return Data::AnyXfer::Elastic::IndexInfo->new( %{$info} );
}

sub inflate_client_info {
    my ( $class, $info ) = @_;
    return Data::AnyXfer::Elastic->default->build_client( nodes => $info );
}


# ES IMPORT

sub do_import {
    my $self = $_[0];

    my $importer = Data::AnyXfer::Elastic::Importer->new(
        # other args
        delete_before_create => $self->delete_before_create,
        bulk_max_count       => $self->bulk_max_count,
        # define custom logger to allow verbose option
        logger => Data::AnyXfer::Elastic::Logger->new(
            screen => $self->verbose,
            file   => 1,
        ),
    );

    $importer->execute(
        datafile      => $self->datafile,
        elasticsearch => $self->client
    );
}


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
