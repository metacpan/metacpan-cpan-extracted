package Catalyst::Engine::SCGI;

use strict;
use warnings;

use base 'Catalyst::Engine::CGI';
eval "use SCGI";
die "Please install SCGI\n" if $@;
use IO::Socket;

our $VERSION = '0.03';

=head1 NAME

Catalyst::Engine::SCGI - SCGI Engine

=head1 DESCRIPTION

This is the SCGI engine.

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine::CGI>.

=head2 $self->run($c, $port, $detach)
 
Start the SCGI server.  If $port is not set default to port 9000. If $detach is set, server will go into the background.

=cut

sub run {
    my ( $self, $class, $port, $detach ) = @_;

    my $sock = 0;
    $port = 9000 unless defined $port;
    my $socket = IO::Socket::INET->new(
        Listen    => 5,
        ReuseAddr => 1,
        LocalPort => $port,
    ) or die "cannot bind to port $port: $!";
    $sock = SCGI->new( $socket, blocking => 1 )
      or die "Failed to open SCGI socket; $!";

    $self->daemon_fork()   if defined $detach;
    $self->daemon_detach() if defined $detach;
    while ( my $request = $sock->accept ) {
        eval { $request->read_env };
        if ($@) {

            # some error
        }
        else {
            $self->{_request} = $request;
            $class->handle_request( env => $request->env );
            # make sure to close once we are done.
            $request->close();
        }
    }
}

=head2 $self->finalize_headers ( $c )
 
 Write finalized headers to socket

=cut
sub finalize_headers {
    my ( $self, $c ) = @_;
    $c->response->header( Status => $c->response->status );
    $self->{_request}->connection->print(
        $c->response->headers->as_string("\015\012") . "\015\012" );
}

=head2 $self->write ( $c, $buffer )
 
 Write directly to socket

=cut
sub write {
    my ( $self, $c, $buffer ) = @_;

    unless ( $self->{_prepared_write} ) {
        $self->prepare_write($c);
        $self->{_prepared_write} = 1;
    }

    $self->{_request}->connection->print($buffer);
}

=head2 $self->read_chunk ( $c, $buffer, $readlen )
 
 Read Body content to $_[3]'s set length and direct output to $_[2].

=cut
sub read_chunk {
    my ( $self, $c ) = @_;
    my $rc = read( $self->{_request}->connection, $_[2], $_[3] );
    return $rc;
}

=head2 $self->daemon_fork()

Performs the first part of daemon initialisation.  Specifically,
forking.  STDERR, etc are still connected to a terminal.

=cut

sub daemon_fork {
    require POSIX;
    fork && exit;
}

=head2 $self->daemon_detach( )

Performs the second part of daemon initialisation.  Specifically,
disassociates from the terminal.

However, this does B<not> change the current working directory to "/",
as normal daemons do.  It also does not close all open file
descriptors (except STDIN, STDOUT and STDERR, which are re-opened from
F</dev/null>).

=cut

sub daemon_detach {
    my $self = shift;
    print "SCGI daemon started (pid $$)\n";
    open STDIN,  "+</dev/null" or die $!;
    open STDOUT, ">&STDIN"     or die $!;
    open STDERR, ">&STDIN"     or die $!;
    POSIX::setsid();
}

1;
