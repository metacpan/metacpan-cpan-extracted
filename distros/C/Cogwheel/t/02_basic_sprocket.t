#!/usr/bin/perl -w
use lib qw(t/lib);
use strict;
use Test::More qw(no_plan);

package TestPlugin;
use POE qw(Filter::JSON Filter::Line);
use base qw(Sprocket::Plugin);

sub new { my $class = shift; return $class->SUPER::new(@_); }

sub name { 'bob' }

sub as_string { shift->name };

sub remote_connected {
    my ( $self, $client, $con, $socket ) = @_;
    $self->take_connection($con);
    $con->filter->push(
        POE::Filter::JSON->new( delimiter => 0, allow_nonref => 1 ),
#        POE::Filter::Line->new(),
    );
    ::pass('Client Connected');
    $con->send( ['dahut'] );
    return 1;
}

sub local_connected {
    my ( $self, $client, $con, $socket ) = @_;
    $self->take_connection($con);
    $con->filter->push(
#       POE::Filter::Line->new(),
        POE::Filter::JSON->new( delimiter => 0, allow_nonref => 1 ),
    );
    ::pass('Server Connected');    
    return 1;
}

sub local_receive {
    my ( $self, $server, $con, $data ) = @_;
    ::is_deeply( $data, ['dahut'], 'got dahut' );
    $con->send( [ @$data, 'dahut' ] );
    return 1;
}

sub remote_receive {
    my ( $self, $client, $con, $data ) = @_;
    ::is_deeply( $data, [ 'dahut', 'dahut' ], 'got both dahuts!' );
    $con->close();
    $client->shutdown();
    return 1;
}

sub local_disconnected {
    my ( $self, $server, $con ) = @_;
    ::pass("server - disconnected");
    $server->shutdown();
    return 1;
}


sub remote_disconnected {
    my ( $self, $client, $con ) = @_;
    ::pass("client - disconnected");
    $client->shutdown();
    return 1;
}
package main;
use Sprocket::Server;
use Sprocket::Client;

my $server = Sprocket::Server->spawn(
    ListenPort => '31337',
    Plugins => [
        {
            plugin   => TestPlugin->new(),
            priority => 0,
        },
    ],
);

my $client = Sprocket::Client->spawn(
    ClientList => ['localhost:31337'],
    Plugins    => [
        {
            Plugin   => TestPlugin->new(),
            Priority => 0,
        },
    ],
);

POE::Kernel->run();
