package Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);




=head1 NAME

Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host -
represents a spawned import task process on a remote host

=head1 DESCRIPTION

Used by L<Data::AnyXfer::Elastic::Import::SpawnTask::Remote> to represent
a target remote host.

=cut

has host => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has port => (
    is      => 'ro',
    isa     => Int,
    default => 22,
);

has user => (
    is  => 'ro',
    isa => Str,
);

has identity_file => (
    is  => 'ro',
    isa => Str,
);

has debug => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


=head1 METHODS

=head2 process_alive

    if ( $host->process_is_alive($pid) ) { }

Check whether the process is still alive on the host.

=cut

sub process_is_alive {
    my ( $self, $pid ) = @_;

    $self->_run_perl(
        sprintf 'kill( 0, %s ) || $! == POSIX::EPERM', $pid    #
    );
}


=head2 wait_for_process

    $host->wait_for_process($pid);

Blocks until the process finishes on the host.

=cut

sub wait_for_process {
    my ( $self, $pid ) = @_;
    sleep 10 while $self->process_is_alive($pid);
}


=head2 terminate_process

    $host->terminate_process($pid);

Attempts to terminate the process on the target host.
It will try C<SIGHUP>, C<SIGQUIT>, C<SIGINT>, and C<SIGKILL>,
once a second in turn (maximum try count is 5), before giving up.

=cut

sub terminate_process {
    my ( $self, $pid ) = @_;

    # process is already dead, nothing to do
    return 1 unless $self->process_is_alive($pid);

    # attempt to kill the process, using progressively
    # stronger signals
SIGNAL: {
        foreach my $signal (qw(HUP QUIT INT KILL)) {
            my $count = 5;
            while ( $count and $self->process_is_alive($pid) ) {
                --$count;
                $self->_run_perl("kill( \$signal, $pid )");
                last SIGNAL unless $self->process_is_alive($pid);
                sleep 3;
            }
        }
    }
    # if it's still alive here, give up and let the current process
    # continue
    return !$self->process_is_alive($pid);
}


=head2 run

    $host->run(0, qw(bash -c env));

Runs the specified command on the remote host. Command can be supplied
as a list for correct shell quoting (similar to L<system>).

The first argument when true connects the commands STDOUT and STDERR to
the current process.

=cut

sub run {
    my ( $self, $connect_output, @command ) = @_;

    # add user to host if supplied
    my $host = $self->host;
    if ( my $user = $self->user ) {
        $host = $user . '@' . $host;
    }

    # build ssh command
    my @ssh_command = (
        Core::Path::Utils->ssh,    #
        '-o', 'StrictHostKeyChecking=no',     #
        '-p', $self->port                     #
    );
    # if an identity file is specified, override the underlysing ssh
    # command to supply it
    if ( my $identity_file = $self->identity_file ) {
        push @ssh_command, '-i', $identity_file;
    }

    # add the user supplied command to the end of ssh
    push @ssh_command, $host, @command;

    if ( $self->debug ) {
        # XXX : Is there a nicer way to represent this
        # without adding another layer of escape sequence chaos?
        # This is good enough for now
        printf "Running command: %s\n", join( ' ', @ssh_command );
    }

    # spawn a background process running on the remote host
    # and return a process instance
    my ( $output, $err );
    if ($connect_output) {
        IPC::Run3::run3( \@ssh_command, \undef, \*STDOUT, \*STDERR )
            or croak $err;
        $output = 1;
    } else {
        IPC::Run3::run3( \@ssh_command, \undef, \$output, $err )
            or croak $err;
    }

    # return command output
    return $output;
}


sub _run_perl {
    my ( $self, $code ) = @_;
    $code =~ s/'/'"'"'/g;
    $self->run( 0, $^X, qw(-e), qq!'print ($code) ? 1 : 0'! );
}



1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

