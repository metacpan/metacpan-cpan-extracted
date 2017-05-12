
package Clio::Process;
BEGIN {
  $Clio::Process::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Process::VERSION = '0.02';
}
# ABSTRACT: Process wrapper

use strict;
use Moo;

use AnyEvent;
use AnyEvent::Run;

with 'Clio::Role::HasManager';


has 'id' => (
    is => 'ro',
    required => 1,
);


has 'command' => (
    is => 'ro',
    required => 1,
);

has '_clients' => (
    is => 'ro',
    default => sub { {} },
    init_arg => undef,
);

has '_handle' => (
    is => 'rw',
    init_arg => undef,
);


sub start {
    my $self = shift;

    my $log = $self->log;

    $self->_handle(
        AnyEvent::Run->new(
            cmd      => [ $self->command ],
            autocork => 0,
            no_delay => 1,
            priority => 19,
            on_error  => sub {
                my ($handle, $fatal, $msg) = @_;
                my $pid = $self->id;
                $log->fatal("Process $pid error: $msg");
                $self->manager->stop_process( $pid );
            },
            on_eof  => sub {
                my ($handle) = @_;
                my $pid = $self->id;
                $log->fatal("Process $pid reached EOF");
                $self->manager->stop_process( $pid );
            },
        )
    );

    my $reader; $reader = sub {
        my ($handle, $line, $eol) = @_;

        my $pid = $self->id;

        $log->trace("Process $pid reading: '$line'");

        for my $cid ( keys %{ $self->{_clients} } ) {
            $log->trace("Process $pid writing to client $cid");
            $self->_clients->{$cid}->write( $line );
        }

        $self->_handle->push_read( line => $reader );
    };
    $self->_handle->push_read( line => $reader );
}


sub stop {
    my $self = shift;
    
    $self->log->debug("Stopping process ", $self->id);

    my $cm = $self->manager->c->server->clients_manager;

    $cm->disconnect_client($_) for keys %{ $self->_clients };

    $self->_handle->destroy;
    $self->_handle(undef);
}


sub write {
    my $self = shift;
        
    $self->log->trace("Process ", $self->id, " writing '@_'");

    $self->_handle->push_write( @_ );
}


sub add_client {
    my ($self, $client) = @_;

    $self->_clients->{ $client->id } = $client;
}


sub remove_client {
    my ($self, $client_id) = @_;

    delete $self->_clients->{ $client_id };
}


sub clients_count {
    my $self = shift;

    return scalar keys %{ $self->_clients };
}


sub is_idle {
    my $self = shift;

    return $self->clients_count == 0;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Process - Process wrapper

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $process = Clio::Process->new(
        manager => $process_manager,
        id      => $uuid,
        command => $command,
    );

=head1 DESCRIPTION

All processes are managed by the L<Clio::ProcessManager>. Process runs the
C<$command> and writes to the connected clients the command output.

Can be wrapped with C<InputFilter>s and C<OutputFilter>s defined in
I<E<lt>CommandE<gt>> block.

Consumes the L<Clio::Role::HasManager>.

=head1 ATTRIBUTES

=head2 id

Process ID.

=head2 command

Command used by the process.

=head1 METHODS

=head2 start

    $process->start;

Starts the L<"command"> and passes the command output to the
connected clients.

On any error object will stop the command.

=head2 stop

    $process->stop;

Disconnects the connected clients and stops the command.

Invoked by L<Clio::ProcessManager>.

=head2 write

    $process->write( $line );

Writes C<$line> to the C<STDIN> of the command.

Can be altered by the C<InputFilter>I<s>.

=head2 add_client

    $process->add_client( $client );

Connects C<$client> to the process - from now on the output of the command
will be written to C<$client>.

=head2 remove_client

    $process->remove_client( $client->id );

Disconnects the C<$client> from the process.

=head2 clients_count

    my $connected_clients = $process->clients_count();

Returns the number of connected clients.

=head2 is_idle

    if ( $process->is_idle ) {
        $process->stop;
    }

Returns true if there are no clients connected, false otherwise.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

