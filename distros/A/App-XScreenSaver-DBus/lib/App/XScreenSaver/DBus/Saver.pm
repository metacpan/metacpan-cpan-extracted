package App::XScreenSaver::DBus::Saver;
use v5.20;
use Moo;
use experimental qw(signatures postderef);
use curry;
use Log::Any;
use Try::Tiny;
use IPC::Run;
use App::XScreenSaver::DBus::SaverProxy;
our $VERSION = '1.0.5'; # VERSION
# ABSTRACT: implements the "idle inhibition" protocol


has reactor => ( is => 'ro', required => 1 );


has bus => ( is => 'lazy', builder => sub { Net::DBus->session() } );


has dbus_srv => (
    is => 'lazy',
    builder => sub { shift->bus->get_service('org.freedesktop.DBus') },
);


has dbus_obj => (
    is => 'lazy',
    builder => sub { shift->dbus_srv->get_object('/org/freedesktop/DBus') },
);


has service => (
    is => 'lazy',
    builder => sub {
        # this is the service name
        shift->bus->export_service('org.freedesktop.ScreenSaver');
    },
);


has paths => (
    is => 'ro',
    default => sub { [qw(/ScreenSaver /org/freedesktop/ScreenSaver)] },
);


has log => ( is => 'lazy', builder => sub { Log::Any->get_logger } );

has _proxies => ( is => 'rw' );
has _prod_id => ( is => 'rw' );
has _inhibits => ( is => 'rw', default => sub { +{} } );


sub start($self) {
    # export to dbus
    $self->_proxies([ map {
        App::XScreenSaver::DBus::SaverProxy->new(
            $self->service,
            $_,
            $self,
        )
    } $self->paths->@* ]);

    $self->_prod_id(
        $self->reactor->add_timeout(
            60_000,
            Net::DBus::Callback->new(
                method => $self->curry::weak::_prod_screensaver
            ),
            0, # this means "don't call my yet"
        ),
    );

    $self->dbus_obj->connect_to_signal(
        'NameOwnerChanged',
        $self->curry::weak::_name_owner_changed,
    );

    return;
}

sub Inhibit($self,$name,$reason,$sender) {
    my $cookie;
    do {
        $cookie = int(rand(2**31))
    } until !exists $self->_inhibits->{$cookie};

    $self->_inhibits->{$cookie} = [ $name, $reason, $sender ];

    $self->log->debugf(
        '<%s> (%s) stops screensaver for <%s> (cookie %d) - %d active',
        $name, $sender, $reason, $cookie, scalar(keys $self->_inhibits->%*),
    );

    # that 1 means "start calling me"
    $self->reactor->toggle_timeout($self->_prod_id, 1);

    return $cookie;
}

sub UnInhibit($self,$cookie,$this_sender) {
    my $inhibit = delete $self->_inhibits->{$cookie}
        or return;
    my ($name, $reason, $sender) = @$inhibit;

    $self->log->debugf(
        '<%s> (was %s, is %s) resumed screensaver for <%s> (cookie %d) - %d left',
        $name, $sender, $this_sender, $reason, $cookie, scalar(keys $self->_inhibits->%*),
    );

    # if there's no more inhibitions, stop prodding the screen saver
    $self->reactor->toggle_timeout($self->_prod_id, 0)
        unless $self->_inhibits->%*;

    return;
}

sub _name_owner_changed($self,$bus_name,$old,$new) {
    $self->log->tracef('<%s> changed from <%s> to <%s>',
                 $bus_name, $old, $new);

    for my $cookie (sort keys $self->_inhibits->%*) {
        my ($name, $reason, $sender) = @{$self->_inhibits->{$cookie}};
        # is this inhibit from that bus name?
        next unless $sender && $sender eq $bus_name;
        # did the bus client just disconnect?
        next unless $old && !$new;

        # if so, remove the inhibit
        my $inhibit = delete $self->_inhibits->{$cookie};

        $self->log->debugf(
            '<%s> (%s) disconnected from the bus (it stopped screensaver for <%s>, cookie %d) - %d left',
            $name, $bus_name, $reason, $cookie, scalar(keys $self->_inhibits->%*),
        );
    }

    # if there's no more inhibitions, stop prodding the screen saver
    $self->reactor->toggle_timeout($self->_prod_id, 0)
        unless $self->_inhibits->%*;
}

sub _prod_screensaver($self) {
    $self->log->debug('prodding xscreensaver');
    my ($out, $err);
    IPC::Run::run(
        [qw(xscreensaver-command -deactivate)],
        \undef, \$out, \$err,
    );
    $self->log->tracef('xscreensaver-command -deactivate said <%s>',$out);
    $self->log->warnf('xscreensaver-command -deactivate errored <%s>',$err)
        if $err;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XScreenSaver::DBus::Saver - implements the "idle inhibition" protocol

=head1 VERSION

version 1.0.5

=head1 SYNOPSIS

    use Net::DBus::Reactor;
    use App::XScreenSaver::DBus::InhibitSleep;

    my $reactor = Net::DBus::Reactor->new;
    my $s = App::XScreenSaver::DBus::Saver->new(reactor => $reactor);
    $s->start;

    $reactor->run;

=head1 ATTRIBUTES

=head2 C<reactor>

the event loop

=head2 C<bus>

the DBus session bus

=head2 C<dbus_srv>

the DBus manager DBus service

=head2 C<dbus_obj>

the DBus manager DBus object

=head2 C<service>

the DBus service we export

=head2 C<paths>

the paths at which we export our DBus object

there's two of them because different applications expect this object
at different paths

=head2 C<log>

a logger

=head1 METHODS

=head2 C<start>

Exports our object to the session bus, and starts listening for
C<NameOwnerChanged> events.

Those events are emitted when a client attaches or detaches from the
bus. A client may die before releasing the idle inhibition, so we want
to be notified when that happens, and release that inhibition.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
