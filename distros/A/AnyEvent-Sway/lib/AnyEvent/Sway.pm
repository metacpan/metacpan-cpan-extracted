package AnyEvent::Sway;
# vim:ts=4:sw=4:expandtab

use strict;
use warnings;
use JSON::XS;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent;
use Encode;
use Scalar::Util qw(tainted);
use Carp;

=head1 NAME

AnyEvent::Sway - communicate with the Sway window manager

=cut

our $VERSION = '0.18';

=head1 VERSION

Version 0.18

=head1 SYNOPSIS

This module connects to the Sway window manager using the UNIX socket based
IPC interface it provides (if enabled in the configuration file). You can
then subscribe to events or send messages and receive their replies.

    use AnyEvent::Sway qw(:all);

    my $sway = sway();

    $sway->connect->recv or die "Error connecting";
    say "Connected to Sway";

    my $workspaces = $sway->message(TYPE_GET_WORKSPACES)->recv;
    say "Currently, you use " . @{$workspaces} . " workspaces";

...or, using the sugar methods:

    use AnyEvent::Sway;

    my $workspaces = Sway->get_workspaces->recv;
    say "Currently, you use " . @{$workspaces} . " workspaces";

A somewhat more involved example which dumps the Sway layout tree whenever there
is a workspace event:

    use Data::Dumper;
    use AnyEvent;
    use AnyEvent::Sway;

    my $sway = sway();

    $sway->connect->recv or die "Error connecting to Sway";

    $sway->subscribe({
        workspace => sub {
            $sway->get_tree->cb(sub {
                my ($tree) = @_;
                say "tree: " . Dumper($tree);
            });
        }
    })->recv->{success} or die "Error subscribing to events";

    AE::cv->recv

=head1 EXPORT

=head2 $sway = sway([ $path ]);

Creates a new C<AnyEvent::Sway> object and returns it.

C<path> is an optional path of the UNIX socket to connect to. It is strongly
advised to NOT specify this unless you're absolutely sure you need it.
C<AnyEvent::Sway> will automatically figure it out by querying the running Sway
instance on the current DISPLAY which is almost always what you want.

=head1 SUBROUTINES/METHODS

=cut

use Exporter qw(import);
use base 'Exporter';

our @EXPORT = qw(sway);

use constant TYPE_RUN_COMMAND => 0;
use constant TYPE_COMMAND => 0;
use constant TYPE_GET_WORKSPACES => 1;
use constant TYPE_SUBSCRIBE => 2;
use constant TYPE_GET_OUTPUTS => 3;
use constant TYPE_GET_TREE => 4;
use constant TYPE_GET_MARKS => 5;
use constant TYPE_GET_BAR_CONFIG => 6;
use constant TYPE_GET_VERSION => 7;
use constant TYPE_GET_BINDING_MODES => 8;
use constant TYPE_GET_CONFIG => 9;
use constant TYPE_SEND_TICK => 10;
use constant TYPE_SYNC => 11;
use constant TYPE_GET_BINDING_STATE => 12;

our %EXPORT_TAGS = ( 'all' => [
    qw(sway TYPE_RUN_COMMAND TYPE_COMMAND TYPE_GET_WORKSPACES TYPE_SUBSCRIBE TYPE_GET_OUTPUTS
       TYPE_GET_TREE TYPE_GET_MARKS TYPE_GET_BAR_CONFIG TYPE_GET_VERSION
       TYPE_GET_BINDING_MODES TYPE_GET_CONFIG TYPE_SEND_TICK TYPE_SYNC
       TYPE_GET_BINDING_STATE)
] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

my $magic = "i3-ipc";

# TODO: auto-generate this from the header file? (Sway/ipc.h)
my $event_mask = (1 << 31);
my %events = (
    workspace => ($event_mask | 0),
    output => ($event_mask | 1),
    mode => ($event_mask | 2),
    window => ($event_mask | 3),
    barconfig_update => ($event_mask | 4),
    binding => ($event_mask | 5),
    shutdown => ($event_mask | 6),
    tick => ($event_mask | 7),
    _error => 0xFFFFFFFF,
);

sub sway
{
    AnyEvent::Sway->new(@_)
}

# Calls Sway, even when running in taint mode.
sub _call_sway
{
    my ($args) = @_;

    my $path_tainted = tainted($ENV{PATH});
    # This effectively circumvents taint mode checking for $ENV{PATH}. We
    # do this because users might specify PATH explicitly to call Sway in a
    # custom location (think ~/.bin/).
    (local $ENV{PATH}) = ($ENV{PATH} =~ /(.*)/);

    # In taint mode, we also need to remove all relative directories from
    # PATH (like . or ../bin). We only do this in taint mode and warn the
    # user, since this might break a real-world use case for some people.
    if ($path_tainted) {
        my @dirs = split /:/, $ENV{PATH};
        my @filtered = grep !/^\./, @dirs;
        if (scalar @dirs != scalar @filtered) {
            $ENV{PATH} = join ':', @filtered;
            warn qq|Removed relative directories from PATH because you | .
                 qq|are running Perl with taint mode enabled. Remove -T | .
                 qq|to be able to use relative directories in PATH. | .
                 qq|New PATH is "$ENV{PATH}"|;
        }
    }
    # Otherwise the qx() operator wont work:
    delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
    chomp(my $result = qx(sway $args));
    # Circumventing taint mode again: the socket can be anywhere on the
    # system and that’s okay.
    if ($result =~ /^([^\0]+)$/) {
        return $1;
    }

    warn "Calling sway $args failed. Is DISPLAY set and is sway in your PATH?";
    return undef;
}

=head2 $sway = AnyEvent::Sway->new([ $path ])

Creates a new C<AnyEvent::Sway> object and returns it.

C<path> is an optional path of the UNIX socket to connect to. It is strongly
advised to NOT specify this unless you're absolutely sure you need it.
C<AnyEvent::Sway> will automatically figure it out by querying the running Sway
instance on the current DISPLAY which is almost always what you want.

=cut
sub new
{
    my ($class, $path) = @_;

    $path = _call_sway('--get-socketpath') unless $path;

    # This is the old default path (v3.*). This fallback line can be removed in
    # a year from now. -- Michael, 2012-07-09
    $path ||= '~/.sway/ipc.sock';

    # Check if we need to resolve ~
    if ($path =~ /~/) {
        # We use getpwuid() instead of $ENV{HOME} because the latter is tainted
        # and thus produces warnings when running tests with perl -T
        my $home = (getpwuid($<))[7];
        confess "Could not get home directory" unless $home and -d $home;
        $path =~ s/~/$home/g;
    }

    bless { path => $path } => $class;
}

=head2 $sway->connect

Establishes the connection to Sway. Returns an C<AnyEvent::CondVar> which will
be triggered with a boolean (true if the connection was established) as soon as
the connection has been established.

    if ($sway->connect->recv) {
        say "Connected to Sway";
    }

=cut
sub connect
{
    my ($self) = @_;
    my $cv = AnyEvent->condvar;

    tcp_connect "unix/", $self->{path}, sub {
        my ($fh) = @_;

        return $cv->send(0) unless $fh;

        $self->{ipchdl} = AnyEvent::Handle->new(
            fh => $fh,
            on_read => sub { my ($hdl) = @_; $self->_data_available($hdl) },
            on_error => sub {
                my ($hdl, $fatal, $msg) = @_;
                delete $self->{ipchdl};
                $hdl->destroy;

                my $cb = $self->{callbacks};

                # Trigger all one-time callbacks with undef
                for my $type (keys %{$cb}) {
                    next if ($type & $event_mask) == $event_mask;
                    $cb->{$type}->();
                    delete $cb->{$type};
                }

                # Trigger _error callback, if set
                my $type = $events{_error};
                return unless defined($cb->{$type});
                $cb->{$type}->($msg);
            }
        );

        $cv->send(1)
    };

    return $cv;
}

sub _data_available
{
    my ($self, $hdl) = @_;

    $hdl->unshift_read(
        chunk => length($magic) + 4 + 4,
        sub {
            my $header = $_[1];
            # Unpack message length and read the payload
            my ($len, $type) = unpack("LL", substr($header, length($magic)));
            $hdl->unshift_read(
                chunk => $len,
                sub { $self->_handle_sway_message($type, $_[1]) }
            );
        }
    );
}

sub _handle_sway_message
{
    my ($self, $type, $payload) = @_;

    return unless defined($self->{callbacks}->{$type});

    my $cb = $self->{callbacks}->{$type};
    $cb->(decode_json $payload);

    return if ($type & $event_mask) == $event_mask;

    # If this was a one-time callback, we delete it
    # (when connection is lost, all one-time callbacks get triggered)
    delete $self->{callbacks}->{$type};
}

=head2 $sway->subscribe(\%callbacks)

Subscribes to the given event types. This function awaits a hashref with the
key being the name of the event and the value being a callback.

    my %callbacks = (
        workspace => sub { say "Workspaces changed" }
    );

    if ($sway->subscribe(\%callbacks)->recv->{success}) {
        say "Successfully subscribed";
    }

The special callback with name C<_error> is called when the connection to Sway
is killed (because of a crash, exit or restart of Sway most likely). You can
use it to print an appropriate message and exit cleanly or to try to reconnect.

    my %callbacks = (
        _error => sub {
            my ($msg) = @_;
            say "I am sorry. I am so sorry: $msg";
            exit 1;
        }
    );

    $sway->subscribe(\%callbacks)->recv;

=cut
sub subscribe
{
    my ($self, $callbacks) = @_;

    # Register callbacks for each message type
    for my $key (keys %{$callbacks}) {
        my $type = $events{$key};
        $self->{callbacks}->{$type} = $callbacks->{$key};
    }

    $self->message(TYPE_SUBSCRIBE, [ keys %{$callbacks} ])
}

=head2 $sway->message($type, $content)

Sends a message of the specified C<type> to Sway, possibly containing the data
structure C<content> (or C<content>, encoded as utf8, if C<content> is a
scalar), if specified.

    my $reply = $sway->message(TYPE_RUN_COMMAND, "reload")->recv;
    if ($reply->{success}) {
        say "Configuration successfully reloaded";
    }

=cut
sub message
{
    my ($self, $type, $content) = @_;

    confess "No message type specified" unless defined($type);

    confess "No connection to Sway" unless defined($self->{ipchdl});

    my $payload = "";
    if ($content) {
        if (not ref($content)) {
            # Convert from Perl’s internal encoding to UTF8 octets
            $payload = encode_utf8($content);
        } else {
            $payload = encode_json $content;
        }
    }
    my $message = $magic . pack("LL", length($payload), $type) . $payload;
    $self->{ipchdl}->push_write($message);

    my $cv = AnyEvent->condvar;

    # We don’t preserve the old callback as it makes no sense to
    # have a callback on message reply types (only on events)
    $self->{callbacks}->{$type} =
        sub {
            my ($reply) = @_;
            $cv->send($reply);
            undef $self->{callbacks}->{$type};
        };

    $cv
}

=head1 SUGAR METHODS

These methods intend to make your scripts as beautiful as possible. All of
them automatically establish a connection to Sway blockingly (if it does not
already exist).

=cut

sub _ensure_connection
{
    my ($self) = @_;

    return if defined($self->{ipchdl});

    $self->connect->recv or confess "Unable to connect to Sway (socket path " . $self->{path} . ")";
}

=head2 get_workspaces

Gets the current workspaces from Sway.

    my $ws = sway->get_workspaces->recv;
    say Dumper($ws);

=cut
sub get_workspaces
{
    my ($self) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_GET_WORKSPACES)
}

=head2 get_outputs

Gets the current outputs from Sway.

    my $outs = sway->get_outputs->recv;
    say Dumper($outs);

=cut
sub get_outputs
{
    my ($self) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_GET_OUTPUTS)
}

=head2 get_tree

Gets the layout tree from Sway (>= v4.0).

    my $tree = sway->get_tree->recv;
    say Dumper($tree);

=cut
sub get_tree
{
    my ($self) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_GET_TREE)
}

=head2 get_marks

Gets all the window identifier marks from Sway (>= v4.1).

    my $marks = sway->get_marks->recv;
    say Dumper($marks);

=cut
sub get_marks
{
    my ($self) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_GET_MARKS)
}

=head2 get_bar_config

Gets the bar configuration for the specific bar id from Sway (>= v4.1).

    my $config = sway->get_bar_config($id)->recv;
    say Dumper($config);

=cut
sub get_bar_config
{
    my ($self, $id) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_GET_BAR_CONFIG, $id)
}

=head2 get_version

Gets the Sway version via IPC, with a fall-back that parses the output of Sway
--version (for Sway < v4.3).

    my $version = sway->get_version()->recv;
    say "major: " . $version->{major} . ", minor = " . $version->{minor};

=cut
sub get_version
{
    my ($self) = @_;

    $self->_ensure_connection;

    my $cv = AnyEvent->condvar;

    my $version_cv = $self->message(TYPE_GET_VERSION);
    my $timeout;
    $timeout = AnyEvent->timer(
        after => 1,
        cb => sub {
            warn "Falling back to sway --version since the running Sway doesn’t support GET_VERSION yet.";
            my $version = _call_sway('--version');
            $version =~ s/^sway version //;
            my $patch = 0;
            my ($major, $minor) = ($version =~ /^([0-9]+)\.([0-9]+)/);
            if ($version =~ /^[0-9]+\.[0-9]+\.([0-9]+)/) {
                $patch = $1;
            }
            # Strip everything from the © sign on.
            $version =~ s/ ©.*$//g;
            $cv->send({
                major => int($major),
                minor => int($minor),
                patch => int($patch),
                human_readable => $version,
            });
            undef $timeout;
        },
    );
    $version_cv->cb(sub {
        undef $timeout;
        $cv->send($version_cv->recv);
    });

    return $cv;
}

=head2 get_config

Gets the raw last read config from Sway. Requires Sway >= 4.14

=cut
sub get_config
{
    my ($self) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_GET_CONFIG);
}

=head2 send_tick

Sends a tick event. Requires Sway >= 4.15

=cut
sub send_tick
{
    my ($self, $payload) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_SEND_TICK, $payload);
}

=head2 sync

Sends an Sway sync event. Requires Sway >= 4.16

=cut
sub sync
{
    my ($self, $payload) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_SYNC, $payload);
}

=head2 command($content)

Makes Sway execute the given command

    my $reply = sway->command("reload")->recv;
    die "command failed" unless $reply->{success};

=cut
sub command
{
    my ($self, $content) = @_;

    $self->_ensure_connection;

    $self->message(TYPE_RUN_COMMAND, $content)
}

=head1 AUTHOR

John Mertz, C<< <git at john.me.tz> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-sway at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-Sway>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::Sway

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-Sway>

=item * The Sway window manager website

L<https://swaywm.org>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2022 (C) John Mertz

Forked from AnyEvent::I3 by Michael Stapelberg

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See https://dev.perl.org/licenses/ for more information.


=cut

1; # End of AnyEvent::Sway
