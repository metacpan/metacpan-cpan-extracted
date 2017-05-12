#!/usr/bin/perl -w
use lib qw(t/lib);
use strict;
use Test::More qw(no_plan);
use POE qw(Filter::JSON);

package TestPlugin;
use Cogwheel;

BEGIN {
    extends qw(Cogwheel::Plugin);
}

after setup_connection => sub {
    my ( $self, $sprocket, $con, $socket ) = @_;
    $con->filter->push(
        POE::Filter::JSON->new( delimiter => 0, allow_nonref => 1 ) );
};

after remote_connected => sub {
    my ( $self, $client, $con, $socket ) = @_;
    ::pass('Client Connected');
    $con->send( ['dahut'] );
    return 1;
};

after local_connected => sub {
    my ( $self, $client, $con, $socket ) = @_;
    ::pass('Server Connected');
    return 1;
};

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
use Cogwheel::Client;
use Cogwheel::Server;

my $server = Cogwheel::Server->new(
    ListenAddress => '127.0.0.1',
    ListenPort    => '8080',
    Plugins       => [
        {
            plugin   => TestPlugin->new(),
            priority => 0,
        },
    ],
);

my $client = Cogwheel::Client->new(
    ClientList => ['localhost:8080'],
    Plugins    => [
        {
            Plugin   => TestPlugin->new(),
            Priority => 0,
        },
    ],
);

POE::Kernel->run();
