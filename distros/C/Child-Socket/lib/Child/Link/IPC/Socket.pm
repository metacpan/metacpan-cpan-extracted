package Child::Link::IPC::Socket;
use strict;
use warnings;

use Child::Util;
use Carp 'croak';
use Scalar::Util 'blessed';

use base 'Child::Link::IPC';

add_accessors qw/socket_file connected/;

sub post_init {}

sub read_handle  { shift->_handle }
sub write_handle { shift->_handle }

sub _handle {
    my $self = shift;
    croak "Not connected (" . blessed($self)  . ':' . $self->pid . ")"
        unless $self->connected;
    return $self->ipc;
}

sub init {
    my $self = shift;
    my ( $file ) = @_;

    $file = $self->_generate_socket_file
        if $file =~ m/^\d+$/;

    $self->_socket_file( $file );

    $self->post_init( @_ );
}

sub _generate_socket_file {
    my $self = shift;
    require File::Spec;
    my $dir = File::Spec->tmpdir();
    my $pid = $self->socket_pid;
    my $name = "$dir/Child-Socket.$pid";
    $name =~ s|/+|/|g;
    return $name;
}

sub disconnect {
    my $self = shift;
    return unless $self->connected;
    my $handle = $self->ipc;
    close( $handle );
    $self->_connected( undef );
}

1;

=head1 NAME

Child::Link::IPC::Socket - Base object for socket based child links.

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
