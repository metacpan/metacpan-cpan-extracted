
package Clio::Server::TCP;
BEGIN {
  $Clio::Server::TCP::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Server::TCP::VERSION = '0.02';
}
# ABSTRACT: Clio TCP Server

use strict;
use Moo;

use AnyEvent;
use AnyEvent::Socket qw( tcp_server );

extends qw( Clio::Server );

with 'Clio::Role::UUIDMaker';


sub start {
    my $self = shift;

    my $config = $self->c->config;

    my $log = $self->c->log;

    my $listen = $config->server_host_port;

    my $clients_manager = $self->clients_manager;

    my $guard = tcp_server $listen->{host}, $listen->{port}, sub {
        my ($fh, $host, $port) = @_;

        my $uuid = $self->create_uuid;

        my $client = $clients_manager->new_client(
            id => $uuid, 
            fh => $fh,
        );

        if ( my $process = $self->c->process_manager->get_first_available ) {

            $client->attach_to_process( $process );
            $process->add_client( $client );
        } else {
            $client->write("Too many connections\r\n");
            $clients_manager->disconnect_client( $client->id );
        }
    };

    $log->info("Started ", __PACKAGE__, " on $listen->{host}:$listen->{port}");
    AnyEvent->condvar->recv;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Server::TCP - Clio TCP Server

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    # TCP socket server
    <Server>
        Listen 0:12346

        Class TCP
        <Client>
            Class Handle

            OutputFilter LineEnd
        </Client>
    </Server>

=head1 DESCRIPTION

Starts TCP server on specified host/port.

Extends the L<Clio::Server>.

Consumes the L<Clio::Role::UUIDMaker>.

=head1 METHODS

=head2 start

Start server and wait for incoming connections.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

