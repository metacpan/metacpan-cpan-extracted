package Data::AnyXfer::Elastic::Import::SpawnTask::Remote;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);


extends 'Data::AnyXfer::Elastic::Import::SpawnTask';

use File::Spec        ();
use Path::Class       ();
use Path::Class::File ();
use Digest::MD5       ();
use IPC::Run3         ();

use Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Process;
use Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host;

use constant PROCESS_CLASS =>
    qw(Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Process);

=head1 NAME

Data::AnyXfer::Elastic::Import::SpawnTask::Remote - Play an import
in parallel on a target remote host

=head1 DESCRIPTION

This module subclasses
L<Data::AnyXfer::Elastic::Import::SpawnTask>, and overrides its methods
to execute the import on a different host to where it was started.

You will be returned a process object which you can inspect to track progress.

=head1 ATTRIBUTES

For internal use only. The interface is the same as the parent class,
except for an additional C<remote_host_instance> attribute, which represents all
of the extra information needed by this module.

=cut


has remote_host_instance => (
    is  => 'rw',
    isa => InstanceOf['Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host'],
    required => 1,
);


# REMOTE FILE TRANSFER ROUTINES

sub remote_process_temp_directory {
    return Path::Class::dir( sprintf '%s/es_spawntask_remote_p%s',
        File::Spec->tmpdir, $$ );
}


sub _remote_transfer_object {
    my ( $class, $file_or_dir, $args ) = @_;

    # it's important that the temp directory includes our PID
    my $remote_dir = $class->remote_process_temp_directory;

    # synchronise the remote directory with our local datafile
    # working dir

    # XXX : working dir because:
    # decompressing a 10GB LZMA dataset and the IO to write it back to disk
    # + transferring 200MB takes longer than tranfering 10GB of already
    # decompressed data
    $class->_sync_source_to_target(
        %{$args},
        remote_target => $remote_dir,
        local_source  => $file_or_dir,
    );

    # return the final remote location
    return $file_or_dir->is_dir
        ? $remote_dir->subdir( $file_or_dir->basename )
        : $remote_dir->file( $file_or_dir->basename );
}


sub _sync_source_to_target {
    my ( $class, %args ) = @_;

    # get the remote host info
    my $remote_host = $args{remote_host_instance};

    # prepare rsync arguments
    my @rsync_cmd = (
        Core::Path::Utils->rsync,    #
        '-a',                                   # archive mode,
        '-v',                                   # verbose
        '-q',                 # keep partial files, show progress
        '--no-p',             # don't preserve permissions
        '--no-g',             # don't preserve groups
        '--chmod=ugo=rwX',    #
    );

    my $remote_target = sprintf '%s:%s', $remote_host->host,
        $args{remote_target};

    # add optional arguments
    if ( my $user = $remote_host->user ) {
        $remote_target = $user . '@' . $remote_target;
    }

    # if an identity file is specified, override the underlysing ssh
    # command to supply it along with the port
    if ( my $identity_file = $remote_host->identity_file ) {
        push @rsync_cmd, '-e',
            sprintf 'ssh -o StrictHostKeyChecking=no -i "%s" -p %s',
            $identity_file,
            $remote_host->port;
    } else {
        # otherwise just supply the port
        push @rsync_cmd, sprintf 'ssh -p %s', $remote_host->port;
    }

    # add the source and destination last
    push @rsync_cmd, $args{local_source}, $remote_target;

    # run the rsync and croak on any errors
    my ( $in, $out, $err ) = ( undef, undef, undef );
    IPC::Run3::run3( \@rsync_cmd, \$in, \$out, \$err ) or croak $err;
    return 1;
}




# OVERRIDE SPAWN TASK FUNCTIONALITY

# Override run to transfer the datafile working dir to
# the remote host

sub run {
    my ( $class, %args ) = @_;

    # we only need to do something if we have a datafile
    if ( $args{datafile} ) {

        # transfer the datafile working dir ahead of time
        # to the remote host
        my $dir = $class->_remote_transfer_object(
            $args{datafile}->storage->working_dir, \%args );

        # set the data dir to the location it will be on the remote
        # (must be stringified to be encoded for the argsfile)
        $args{datafile_dir} = $dir->stringify;
    }

    # call the base run method with modified datafile source directory
    return $class->SUPER::run(%args);
}


# Override run with argsfile to transfer it to the remote host

sub _run_self_with_argsfile {
    my ( $class, $argsfile, $args ) = @_;

    # move the argsfile to the remote host
    $argsfile = $class->_remote_transfer_object( $argsfile, $args, );

    # call the original method and pass it the remote
    # argsfile location in place of the local one
    return $class->SUPER::_run_self_with_argsfile( $argsfile, $args );
}


# Override exec command to run on the remote host

sub _exec_command {
    my ( $class, $command, $args ) = @_;

    # now that all of the things we need are available on the
    # remote host, we can proceed to run our commands there

    # get the remote host info
    my $remote_host = $args->{remote_host_instance};

    # build a new temp file to store the commands
    my $command_file
        = Core::tmp_dir()->file( Digest::MD5::md5_hex($command) );

    $command_file->spew(
        # add the shebang line and command
        "#!/usr/bin/env bash\n" . $command
            # XXX : sleep here so that execution
            # cannot finish between starting the remote command and detecting
            # the PID (pretty hard to happen, but theoretically could)
            . "\nsleep 5"
    );

    # move the command file to the remote host
    $command_file = $class->_remote_transfer_object( $command_file, $args );
    # (and make it user executable)
    $remote_host->run( 1, qq!chmod u+x $command_file! );

    # spawn a background process running on the remote host
    $remote_host->run( 0, qq/screen -d -m $command_file/ );

    # find the PID of the remote command
    my $pid = $remote_host->run( 0, qq!pgrep -f "$command_file"! );
    $pid = ( $pid =~ /^(\d+)/ )[0];

    # if the command has finished already, we should probably bail
    # as it likely didn't execute
    unless ($pid) {
        croak "No PID found for remote command. "
            . "It probably failed (file: $command_file)";
    }

    # return a process instance representing the remote runnng process
    return $class->_create_remote_process(
        spawntask_args => $args,
        remote_host    => $remote_host,
        pid            => $pid,
    );
}

sub _create_remote_process {
    my ( $class, %args ) = @_;

    # extract spawn task args for use with _exec_command
    # during cleanup
    my $spawntask_args = delete $args{spawntask_args};

    # create the remote process instance
    return PROCESS_CLASS()->new(
        %args,

        # define a cleanup hook so we can remove our temporary files
        # on the remote afterwards
        cleanup_sub => sub {

            # build command to run on remote
            my $command = sprintf q!%s -MFile::Path -E 'rmtree(q[%s])'!,
                $^X, $class->remote_process_temp_directory;

            # execute it using the host instance
            $spawntask_args->{remote_host_instance}->run( 0, $command );
        }
    );
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

