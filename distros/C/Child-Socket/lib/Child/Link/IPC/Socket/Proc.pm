package Child::Link::IPC::Socket::Proc;
use strict;
use warnings;

use IO::Socket::UNIX;
use Carp qw/croak/;

use base qw/
    Child::Link::IPC::Socket
    Child::Link::Proc
/;

sub socket_pid { shift->pid };

sub post_init {
    my $self = shift;
    $self->connect( 5 );
}

sub new_from_file {
    my $class = shift;
    my ( $file ) = @_;
    my $self = bless( { _socket_file => $file }, $class );
    my $pid = $self->connect( 5 );
    $self->_pid( $pid );
    return $self;
}

sub connect {
    my $self = shift;
    return if $self->connected;
    my ( $timeout ) = @_;

    my $file = $self->socket_file;
    while ( ! -e $file && $timeout ) {
        $timeout--;
        sleep 1;
    }

    return unless -e $file;

    my $socket = IO::Socket::UNIX->new( $file )
        || croak ( "Could not connect to socket '" . $file . "': $!" );

    $self->_ipc( $socket );
    $self->_connected( 1 );
    chomp( my $pid = <$socket> );

    return $pid;
}

1;

=head1 NAME

Child::Link::IPC::Socket::Proc - Socket based link to child process.

=head1 SEE ALSO

L<Child::Socket>

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Child is free software; Standard perl licence.

Child is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
