package Mojolicious::Plugin::BoardStreams;
use v5.44;

our $VERSION = "v0.0.60";

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use BoardStreams::Hub;
use Mojo::Pg;
use Scalar::Util qw(blessed);

sub register ($self, $app, $conf) {
    my $pg = $conf->{pg} // die "The BoardStreams plugin needs a 'pg' option (a Mojo::Pg object or connection string)\n";
    $pg = Mojo::Pg->new($pg) unless blessed $pg;

    my $hub = BoardStreams::Hub->new(
        pg  => $pg,
        log => $app->log,
        map { $_ => $conf->{$_} } grep { defined $conf->{$_} } qw(retention retry_delay heartbeat_interval identify listener_check_interval),
    );
    $app->helper(boardstreams => sub { $hub });

    my $routes = $conf->{routes} // $app->routes;
    $routes->websocket($conf->{route} // '/boardstreams')->to(cb => sub ($c) { $hub->serve($c) })
        ->name('boardstreams');

    # Create the tables now, unless asked to wait. Either way the hub
    # creates them when they are first needed, which also covers
    # PostgreSQL being down right now.
    unless ($conf->{lazy_migrate}) {
        eval { $hub->migrate; 1 } or $app->log->warn("BoardStreams: cannot reach PostgreSQL yet: $@");
    }

    return $hub;
}

1;
