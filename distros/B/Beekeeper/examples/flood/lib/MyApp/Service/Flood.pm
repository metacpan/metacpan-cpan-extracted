package MyApp::Service::Flood;

use strict;
use warnings;

use Beekeeper::Client;


sub notify {
    my ($self, $params) = @_;

    my $client = Beekeeper::Client->instance;

    $client->send_notification(
        method => 'myapp.flood.msg', 
        params => $params,
    );
}

sub echo {
    my ($self, $params) = @_;

    my $client = Beekeeper::Client->instance;

    my $resp = $client->call_remote(
        method => 'myapp.flood.echo',
        params => $params,
    );

    return $resp->result;
}

sub fire_echo {
    my ($self, $params) = @_;

    my $client = Beekeeper::Client->instance;

    $client->fire_remote(
        method => 'myapp.flood.echo',
        params => $params,
    );
}

sub async_echo {
    my ($self, $params, $on_success) = @_;

    my $client = Beekeeper::Client->instance;

    $client->call_remote_async(
        method     => 'myapp.flood.echo',
        params     => $params,
        on_success => $on_success,
    );
}

1;
