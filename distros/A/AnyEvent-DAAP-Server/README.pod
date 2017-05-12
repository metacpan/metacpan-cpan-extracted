package AnyEvent::DAAP::Server;
use Any::Moose;
use AnyEvent::DAAP::Server::Connection;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Net::Rendezvous::Publish;
use Net::DAAP::DMAP qw(dmap_pack);
use HTTP::Request;
use Router::Simple;
use URI::QueryParam;

our $VERSION = '0.01';

has name => (
    is  => 'rw',
    isa => 'Str',
    default => sub { ref $_[0] },
);

has port => (
    is  => 'rw',
    isa => 'Int',
    default => 3689,
);

has rendezvous_publisher => (
    is  => 'rw',
    isa => 'Net::Rendezvous::Publish',
    default => sub { Net::Rendezvous::Publish->new },
);

has rendezvous_service => (
    is  => 'rw',
    isa => 'Net::Rendezvous::Publish::Service',
    lazy_build => 1,
);

sub _build_rendezvous_service {
    my $self = shift;
    return $self->rendezvous_publisher->publish(
        port => $self->port,
        name => $self->name,
        type => '_daap._tcp',
    );
}

has db_id => (
    is => 'rw',
    default => '13950142391337751523', # XXX magic value (from Net::DAAP::Server)
);

has tracks => (
    is  => 'rw',
    isa => 'HashRef[AnyEvent::DAAP::Server::Track]',
    default => sub { +{} },
);

has global_playlist => (
    is  => 'rw',
    isa => 'AnyEvent::DAAP::Server::Playlist',
    default => sub { AnyEvent::DAAP::Server::Playlist->new },
);

has playlists => (
    is  => 'rw',
    isa => 'HashRef[AnyEvent::DAAP::Server::Playlist]',
    default => sub { +{} },
);

has revision => (
    is  => 'rw',
    isa => 'Int',
    default => 1,
);

has connections => (
    is  => 'rw',
    isa => 'ArrayRef[AnyEvent::DAAP::Server::Connection]',
    default => sub { +[] },
);

has router => (
    is  => 'rw',
    isa => 'Router::Simple',
    default => sub { Router::Simple->new },
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub BUILD {
    my $self = shift;
    $self->add_playlist($self->global_playlist);
}

sub publish {
    my $self = shift;
    $self->rendezvous_service; # build
}

sub setup {
    my $self = shift;

    my @route = (
        '/databases/{database_id}/items'                           => '_database_items',
        '/databases/{database_id}/containers'                      => '_database_containers',
        '/databases/{database_id}/containers/{container_id}/items' => '_database_container_items',
        '/databases/{database_id}/items/{item_id}.*'               => '_database_item',
    );

    while (my ($route, $method) = splice @route, 0, 2) {
        $self->router->connect($route => { method => $method });
    }

    $self->publish;

    tcp_server undef, $self->port, sub {
        my ($fh, $host, $port) = @_;
        my $connection = AnyEvent::DAAP::Server::Connection->new(server => $self, fh => $fh);
        $connection->handle->on_read(sub {
            my ($handle) = @_;
            $handle->push_read(
                regex => qr<\r\n\r\n>, sub {
                    my ($handle, $data) = @_;
                    my $request = HTTP::Request->parse($data);
                    my $path = $request->uri->path;
                    my $p = $self->router->match($path) || {};
                    my $method = $p->{method} || $path;
                    $method =~ s<[/-]><_>g;
                    $self->$method($connection, $request, $p);
                }
            );
        });
        push @{ $self->connections }, $connection;
    };
}

sub database_updated {
    my $self = shift;
    $self->{revision}++;
    foreach my $connection (@{ $self->connections }) {
        $connection->pause_cv->send if $connection->pause_cv;
    }
}

# XXX dmap_itemid is used as only its lower 3 bytes

sub add_track {
    my ($self, $track) = @_;
    $self->tracks->{ $track->dmap_itemid & 0xFFFFFF } = $track;
    $self->global_playlist->add_track($track);
}

sub add_playlist {
    my ($self, $playlist) = @_;
    $self->playlists->{ $playlist->dmap_itemid & 0xFFFFFF } = $playlist;
}

### Handlers

sub _server_info {
    my ($self, $connection) = @_;
    $connection->respond_dmap([[
        'dmap.serverinforesponse' => [
            [ 'dmap.status'                => 200 ],
            [ 'dmap.protocolversion'       => 2 ],
            [ 'daap.protocolversion'       => '3.11' ],
            [ 'dmap.itemname'              => $self->name ],
            [ 'dmap.loginrequired'         => 1 ],
            [ 'dmap.timeoutinterval'       => 1800 ],
            [ 'dmap.supportsautologout'    => 0 ],
            [ 'dmap.supportsupdate'        => 1 ],
            [ 'dmap.supportspersistentids' => 0 ],
            [ 'dmap.supportsextensions'    => 0 ],
            [ 'dmap.supportsbrowse'        => 0 ],
            [ 'dmap.supportsquery'         => 0 ],
            [ 'dmap.supportsindex'         => 0 ],
            [ 'dmap.supportsresolve'       => 0 ],
            [ 'dmap.databasescount'        => 1 ],
        ]
    ]]);
}

sub _login {
    my ($self, $connection) = @_;
    $connection->respond_dmap([[
        'dmap.loginresponse' => [
            [ 'dmap.status'    => 200 ],
            [ 'dmap.sessionid' => 42 ], # XXX does not have session, magic number
        ]
    ]]);
}

sub _update {
    my ($self, $connection, $req) = @_;

    if ($req->uri->query_param('delta')) {
        my $cv = $connection->pause(sub {
            $connection->respond_dmap([[
                'dmap.updateresponse' => [
                    [ 'dmap.status'         => 200 ],
                    [ 'dmap.serverrevision' => $self->revision ],
                ]
            ]]);
        });
        my $w; $w = AE::timer 60, 0, sub { undef $w; $cv->send };
    } else {
        $connection->respond_dmap([[
            'dmap.updateresponse' => [
                [ 'dmap.status'         => 200 ],
                [ 'dmap.serverrevision' => $self->revision ],
            ]
        ]]);
    }
}

sub _databases {
    my ($self, $connection) = @_;

    $connection->respond_dmap([[
        'daap.serverdatabases' => [
            [ 'dmap.status'              => 200 ],
            [ 'dmap.updatetype'          => 0 ],
            [ 'dmap.specifiedtotalcount' => 1 ],
            [ 'dmap.returnedcount'       => 1 ],
            [ 'dmap.listing' => [
                [ 'dmap.listingitem' => [
                    [ 'dmap.itemid'         => 1 ], # XXX magic
                    [ 'dmap.persistentid'   => $self->db_id ],
                    [ 'dmap.itemname'       => $self->name ],
                    [ 'dmap.itemcount'      => scalar keys %{ $self->tracks } ],
                    [ 'dmap.containercount' => 1 ],
                ] ],
            ] ],
        ]
    ]]);
}

sub _database_items {
    my ($self, $connection, $req, $args) = @_;
    # $args->{database_id};

    my $tracks = $self->__format_tracks_as_dmap($req, [ values %{ $self->tracks } ]);
    $connection->respond_dmap([[
        'daap.databasesongs' => [
            [ 'dmap.status'              => 200 ],
            [ 'dmap.updatetype'          => 0 ],
            [ 'dmap.specifiedtotalcount' => scalar @$tracks ],
            [ 'dmap.returnedcount'       => scalar @$tracks ],
            [ 'dmap.listing'             => $tracks ]
        ]
    ]]);
}

sub _database_containers {
    my ($self, $connection, $req, $args) = @_;
    # $args->{database_id};

    my @playlists = map { $_->as_dmap_struct } $self->global_playlist, values %{ $self->playlists };

    $connection->respond_dmap([[
        'daap.databaseplaylists' => [
            [ 'dmap.status'              => 200 ],
            [ 'dmap.updatetype'          => 0 ],
            [ 'dmap.specifiedtotalcount' => 1 ],
            [ 'dmap.returnedcount'       => 1 ],
            [ 'dmap.listing'             => \@playlists ],
        ]
    ]]);
}

sub _database_container_items {
    my ($self, $connection, $req, $args) = @_;
    # $args->{database_id}, $args->{container_id}

    my $playlist = $self->playlists->{ $args->{container_id} }
        or return $connection->respond(404);

    my $tracks = $self->__format_tracks_as_dmap($req, scalar $playlist->tracks);
    $connection->respond_dmap([[
        'daap.playlistsongs' => [
            [ 'dmap.status'              => 200 ],
            [ 'dmap.updatetype'          => 0 ],
            [ 'dmap.specifiedtotalcount' => scalar @$tracks ],
            [ 'dmap.returnedcount'       => scalar @$tracks ],
            [ 'dmap.listing'             => $tracks ]
        ]
    ]]);
}

sub _database_item {
    my ($self, $connection, $req, $args) = @_;
    # $args->{database_id}, $args->{item_id}

    my $track = $self->tracks->{ $args->{item_id} }
        or return $connection->respond(404);

    $track->stream($connection, $req, $args);
}

sub __format_tracks_as_dmap {
    my ($self, $req, $tracks) = @_;

    my @fields = ( qw(dmap.itemkind dmap.itemid dmap.itemname), split /,|%2C/i, scalar $req->uri->query_param('meta') || '' );

    my @tracks;
    foreach my $track (@$tracks) {
        push @tracks, [
            'dmap.listingitem' => [ map { [ $_ => $track->_dmap_field($_) ] } @fields ]
        ]
    }

    return \@tracks;
}

1;

__END__

=head1 NAME

AnyEvent::DAAP::Server - DAAP Server implemented with AnyEvent

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::DAAP::Server;
  use AnyEvent::DAAP::Server::Track::File::MP3;
  use File::Find::Rule;

  my $daap = AnyEvent::DAAP::Server->new(port => 3689);

  foreach my $file (find name => '*.mp3', in => '.') {
      my $track = AnyEvent::DAAP::Server::Track::File::MP3->new(file => $file);
      $daap->add_track($track);
  }

  $daap->setup;

  AE::cv->wait;


=head1 DESCRIPTION

AnyEvent::DAAP::Server is a DAAP Server implementation on AnyEvent.
It is like L<Net::DAAP::Server>, but does not find files automatically (see SYNOPSIS.)

=head1 METHODS

=over 4

=item my $daap = AnyEvent::DAAP::Server->new(name => 'AnyEvent::DAAP::Server', port => 3689);

Create new DAAP server instance.

=item $daap->setup;

Publish rendezvous service and setup handlers.
Afterwards you will want to call AnyEvent::CondVar's recv().

=item $daap->add_track($track);

Add a new track that is an instance of L<AnyEvent::DAAP::Server::Track>.

=item $daap->add_playlist($playlist);

Add a new playlist that is an instance of L<AnyEvent::DAAP::Server::Playlist>.

=item $daap->database_updated;

After add_track() or add_playlist(), call this method to notify clients that the database is updated.

=back

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

L<Net::DAAP::Server>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
