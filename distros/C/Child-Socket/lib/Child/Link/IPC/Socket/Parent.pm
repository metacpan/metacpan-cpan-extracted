package Child::Link::IPC::Socket::Parent;
use strict;
use warnings;

use Child::Util;
use IO::Socket::UNIX;

use base qw/
    Child::Link::IPC::Socket
    Child::Link::Parent
/;

add_accessors qw/listener/;

sub socket_pid { $$ };

sub post_init {
    my $self = shift;
    my $file = $self->socket_file;

    $self->_listener(
        IO::Socket::UNIX->new(
            Local => $file,
            Listen => 1,
        ) || die ( "Could not create socket: $!" )
    );

    $self->connect( 5 );
}

sub connect {
    my $self = shift;
    return if $self->connected;

    my ( $timeout ) = @_;
    my $client;

    while (!( $client = $self->_listener->accept ) && $timeout ) {
        $timeout--;
        sleep 1;
    }

    return unless $client;

    $self->_ipc( $client );
    $self->_connected( 1 );
    $self->say( $$ );

    return $client;
}

1;

=head1 NAME

Child::Link::IPC::Socket::Parent - Socket based link to parent process.

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
