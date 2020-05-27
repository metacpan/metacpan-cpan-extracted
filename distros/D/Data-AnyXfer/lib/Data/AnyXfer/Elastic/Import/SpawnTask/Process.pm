package Data::AnyXfer::Elastic::Import::SpawnTask::Process;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use POSIX ();


=head1 NAME

Data::AnyXfer::Elastic::Import::SpawnTask::Process -
represents a spawned import task process

=head1 DESCRIPTION

Used by L<Data::AnyXfer::Elastic::Import::SpawnTask> to represent a spawned
task process.

=cut


has pid => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has cleanup_sub => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub {
        sub { }
    },
);

sub DESTROY { shift->terminate }


=head1 METHODS

=head2 alive

    if ( $process->alive ) { }

Check whether the process is still alive.

=cut

sub alive {
    my $pid = shift->pid;
    kill( 0, $pid ) || $! == POSIX::EPERM;
}


=head2 wait

    $process->wait;

Blocks until the process finishes.

=cut

sub wait {
    my $self = shift;
    sleep 1 while $self->alive;
}


=head2 terminate

    $process->terminate;

Attempts to terminate the process. It will try C<SIGHUP>, C<SIGQUIT>,
C<SIGINT>, and C<SIGKILL>, once a second in turn (maximum try count
is 5), before giving up.

=cut

sub terminate {
    my $self = shift;

    # process is already dead, nothing to do
    unless ($self->alive) {
        $self->cleanup_sub->();
        return 1;
    }

    # attempt to kill the process, using progressively
    # stronger signals
    my $pid = $self->pid;
SIGNAL: {
        foreach my $signal (qw(HUP QUIT INT KILL)) {
            my $count = 5;
            while ( $count and $self->alive ) {
                --$count;
                kill( $signal, $pid );
                last SIGNAL unless $self->alive;
                sleep 1;
            }
        }
    }
    # if it's still alive here, give up and let the current process
    # continue
    if (!$self->alive) {
        $self->cleanup_sub->();
        return 1;
    } else {
        return 0;
    }
}


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

