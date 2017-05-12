package App::HistHub;
use Moose;

our $VERSION = '0.01';

use POE qw/
    Wheel::FollowTail
    Component::Client::HTTPDeferred
    /;

use JSON::XS ();
use HTTP::Request::Common;
use Fcntl ':flock';

has hist_file => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has tailor => (
    is  => 'rw',
    isa => 'POE::Wheel::FollowTail',
);

has ua => (
    is      => 'rw',
    isa     => 'POE::Component::Client::HTTPDeferred',
    lazy    => 1,
    default => sub {
        POE::Component::Client::HTTPDeferred->new;
    },
);

has json_driver => (
    is      => 'rw',
    isa     => 'JSON::XS',
    lazy    => 1,
    default => sub {
        JSON::XS->new->latin1;
    },
);

has poll_delay => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 5 },
);

has update_queue => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has api_endpoint => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has api_uid => (
    is  => 'rw',
    isa => 'Str',
);

=head1 NAME

App::HistHub - Sync shell history between multiple PC.

=head1 SYNOPSIS

    use App::HistHub;
    
    my $hh = App::HistHub->new(
        hist_file    => 'path to your history file',
        api_endpoint => 'http://localhost:3000/',
    );
    $hh->run;

=head1 DESCRIPTION

App::HistHub is an application that enables you to sync shell history between multiple computers.

This application consists of two modules: client module (histhubd.pl) and server module (histhub_server.pl).

You need one histhub server. To bootup the server, type following command:

    histhub_server

This server receive updating history data from one client, and broadcast to others.

You also need one client daemon in each computer that you want to share history. To boot client, type following command:

    histhubd --histfile=/path/to/your_history_file --server=http://your_server_address

This client send updated history to server, and receive new history from other clients.

=head1 METHODS

=head2 new

    my $hh = App::HistHub->new( %options );

Create HistHub object.

Available obtions are:

=over 4

=item hist_file

History file path to watch update

=item api_endpoint

Update API URL.

=back

=head2 spawn

Create POE session and return session object.

=cut

sub spawn {
    my $self = shift;

    POE::Session->create(
        object_states => [
            $self => {
                map { $_ => "poe_$_" } qw/_start init poll set_poll hist_line hist_rollover/
            },
        ],
    );
}

=head2 run

Spawn and start POE::Kernel

=cut

sub run {
    my $self = shift;
    $self->spawn;
    POE::Kernel->run;
}

=head2 uri_for

    $hh->uri_for( $path )

Build api url

=cut

sub uri_for {
    my ($self, $path) = @_;

    (my $url = $self->api_endpoint) =~ s!/+$!!;
    $url . $path;
}

=head2 append_history

    $hh->append_history( $session, $api_response );

Update history file

=cut

sub append_history {
    my ($self, $session, $data) = @_;

    my $json = $self->json_driver->decode($data);
    if ($json->{error}) {
        warn 'api poll error: '. $json->{error};
    }
    elsif ($json->{result}) {
        $self->{tailer} = undef;

        open my $fh, '>>', $self->hist_file;

        flock($fh, LOCK_EX);
        seek($fh, 0, 2);

        print $fh $json->{result};

        flock($fh, LOCK_UN);
        close $fh;

        $poe_kernel->post( $session->ID => 'init' );
    }
}

=head1 POE METHODS

=head2 poe__start

=cut

sub poe__start {
    my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];

    my $d = $self->ua->request( GET $self->api_endpoint . '/api/init' );
    $d->addCallback(sub {
        my $res = shift;
        my $json = $self->json_driver->decode($res->content);

        if ($json->{error}) {
            die 'api response error: ' . $json->{error};
        }
        else {
            $self->api_uid( $json->{result}{uid} );
            $kernel->post( $session->ID, 'init' );
        }
    });
    $d->addErrback(sub {
        my $res = shift;
        die 'api response error: ', $res->status_line;
    });
}

=head2 poe_init

=cut

sub poe_init {
    my ($self, $kernel) = @_[OBJECT, KERNEL];

    my $tailor = POE::Wheel::FollowTail->new(
        Filename   => $self->hist_file,
        InputEvent => 'hist_line',
        ResetEvent => 'hist_rollover',
    );
    $self->tailor( $tailor );

    $kernel->yield('set_poll');
}

=head2 poe_hist_line

=cut

sub poe_hist_line {
    my ($self, $kernel, $line) = @_[OBJECT, KERNEL, ARG0];

    push @{ $self->update_queue }, $line;
    $kernel->yield('set_poll');
}

=head2 poe_hist_rollover

=cut

sub poe_hist_rollover {
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    
}

=head2 poe_set_poll

=cut

sub poe_set_poll {
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    $kernel->delay( poll => $self->poll_delay );
}

=head2 poe_poll

=cut

sub poe_poll {
    my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];

    $kernel->yield('set_poll');

    my $d = $self->ua->request(
        POST $self->uri_for('/api/poll'),
        [ uid => $self->api_uid, data => join '', @{ $self->update_queue } ]
    );
    $self->update_queue([]);

    $d->addCallback(sub { $self->append_history($session, shift->content) });
    $d->addErrback(sub { warn 'api poll error: ' . shift->status_line });
    $d->addBoth(sub { $kernel->post($session->ID => 'set_poll') });
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
