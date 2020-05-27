package Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Process;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);



extends 'Data::AnyXfer::Elastic::Import::SpawnTask::Process';

use POSIX ();
use Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host;

=head1 NAME

Data::AnyXfer::Elastic::Import::SpawnTask::Process -
represents a spawned import task process on a remote host

=head1 DESCRIPTION

Used by L<Data::AnyXfer::Elastic::Import::SpawnTask::Remote> to represent
a spawned task process.

Uses L<Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host> underneath.

=head1 ATTRIBUTES

=over

=item host_instance

REQUIRED.

A L<Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host> instance
for the target host.

=back

=cut

has remote_host => (
    is  => 'ro',
    isa => InstanceOf['Data::AnyXfer::Elastic::Import::SpawnTask::Remote::Host'],
    required => 1,
);


=head1 METHODS

=head2 alive

    if ( $process->alive ) { }

Check whether the process is still alive.

=cut

sub alive {
    my $self = shift;
    return $self->remote_host->process_is_alive( $self->pid );
}


=head2 wait

    $process->wait;

Blocks until the process finishes.

=cut

sub wait {
    my $self = shift;
    return $self->remote_host->wait_for_process( $self->pid );
}


=head2 terminate

    $process->terminate;

Attempts to terminate the process. It will try C<SIGHUP>, C<SIGQUIT>,
C<SIGINT>, and C<SIGKILL>, once a second in turn (maximum try count
is 5), before giving up.

=cut

sub terminate {
    my $self = shift;
    my $ret = $self->remote_host->terminate_process( $self->pid );
    $self->cleanup_sub->() if $ret;
    return $ret;
}


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

