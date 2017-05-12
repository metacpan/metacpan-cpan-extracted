use strict;
use warnings;
package AnyEvent::Mattermost;
$AnyEvent::Mattermost::VERSION = '0.002';
# ABSTRACT: AnyEvent module for interacting with Mattermost APIs

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Mattermost - AnyEvent module for interacting with the Mattermost APIs

=cut

use AnyEvent;
use AnyEvent::WebSocket::Client 0.37;
use Carp;
use Furl;
use JSON;
use Time::HiRes qw( time );
use Try::Tiny;

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Mattermost;

    my $host = "https://mattermost.example.com/";
    my $team = "awesome-chat";
    my $user = "janedoe@example.com";
    my $pass = "foobar123";

    my $cond = AnyEvent->condvar;
    my $mconn = AnyEvent::Mattermost->new($host, $team, $user, $pass);

    $mconn->on('posted' => sub {
        my ($self, $message) = @_;
        printf "<%s> %s\n", $message->{data}{sender_name}, $message->{data}{post}";
    });

    $mconn->start;
    AnyEvent->condvar->recv;

=head1 DESCRIPTION

This module provides an L<AnyEvent> based interface to Mattermost chat servers
using the Web Service API.

It is very heavily inspired by L<AnyEvent::SlackRTM> and I owe a debt of
gratitude to Andrew Hanenkamp for his work on that module.

This library is still very basic and currently attempts to implement little
beyond authentication and simple message receiving and sending. Feature parity
with SlackRTM support is a definite goal, and then beyond that it would be nice
to support all the stable Mattermost API features. Baby steps.

=head1 METHODS

=cut

=head2 new

    $mconn = AnyEvent::Mattermost->new( $host, $team, $email, $password );

Creates a new AnyEvent::Mattermost object. No connections are opened and no
callbacks are registered yet.

The C<$host> parameter must be the HTTP/HTTPS URL of your Mattermost server. If
you omit the scheme and provide only a hostname, HTTPS will be assumed. Note
that Mattermost servers configured over HTTP will also use unencrypted C<ws://>
for the persistent WebSockets connection for receiving incoming messages. You
should use HTTPS unless there is no other choice.

C<$team> must be the Mattermost team's short name (the version which appears in
the URLs when connected through the web client).

C<$email> must be the email address of the account to be used for logging into
the Mattermost server. The short username is not supported for logins via the
Mattermost APIs, only the email address.

C<$password> is hopefully self-explanatory.

=cut

sub new {
    my ($class, $host, $team, $user, $pass) = @_;

    croak "must provide a Mattermost server address"
        unless defined $host && length($host) > 0;
    croak "must provide a Mattermost team name"
        unless defined $team && length($team) > 0;
    croak "must provide a login email and password"
        unless defined $user && defined $pass && length($user) > 0 && length($pass) > 0;

    $host = "https://$host" unless $host =~ m{^https?://}i;
    $host .= '/' unless substr($host, -1, 1) eq '/';

    return bless {
        furl     => Furl->new( agent => "AnyEvent::Mattermost" ),
        host     => $host,
        team     => $team,
        user     => $user,
        pass     => $pass,
        registry => {},
        channels => {},
    }, $class;
}

=head2 start

    $mconn->start();

Opens the connection to the Mattermost server, authenticates the previously
provided account credentials and performs an initial data request for user,
team, and channel information.

Any errors encountered will croak() and the connection will be aborted.

=cut

sub start {
    my ($self) = @_;

    my $data = $self->_post('api/v3/users/login', {
        name     => $self->{'team'},
        login_id => $self->{'user'},
        password => $self->{'pass'},
    });

    croak "could not log in" unless exists $self->{'token'};

    my $userdata = $self->_get('api/v3/users/initial_load');

    croak "did not receive valid initial_load user data"
        unless exists $userdata->{'user'}
            && ref($userdata->{'user'}) eq 'HASH'
            && exists $userdata->{'user'}{'id'};

    croak "did not receive valid initial_load teams data"
        unless exists $userdata->{'teams'}
            && ref($userdata->{'teams'}) eq 'ARRAY'
            && grep { $_->{'name'} eq $self->{'team'} } @{$userdata->{'teams'}};

    $self->{'userdata'} = $userdata->{'user'};
    $self->{'teamdata'} = (grep { $_->{'name'} eq $self->{'team'} } @{$userdata->{'teams'}})[0];

    my $wss_url = $self->{'host'} . 'api/v3/users/websocket';
    $wss_url =~ s{^http(s)?}{ws$1}i;

    $self->{'client'} = AnyEvent::WebSocket::Client->new(
        http_headers => $self->_headers
    );

    $self->{'client'}->connect($wss_url)->cb(sub {
        my $client = shift;

        my $conn = try {
            $client->recv;
        }
        catch {
            die $_;
        };

        $self->{'started'}++;
        $self->{'conn'} = $conn;

        $conn->on(each_message => sub { $self->_handle_incoming(@_) });
    });
}

=head2 stop

    $mconn->stop();

Closes connection with Mattermost server and ceases processing messages.
Callbacks which have been registered are left in place in case you wish to
start() the connection again.

If you wish to remove callbacks, without disposing of the AnyEvent::Mattermost
object itself, you will need to call on() and pass C<undef> for each events'
callback value (rather than the anonymous subroutines you had provided when
registering them).

=cut

sub stop {
    my ($self) = @_;

    $self->{'conn'}->close;
}

=head2 on

    $mconn->on( $event1 => sub {}, [ $event2 => sub {}, ... ] );

Registers a callback for the named event type. Multiple events may be registered
in a single call to on(), but only one callback may exist for any given event
type. Any subsequent callbacks registered to an existing event handler will
overwrite the previous callback.

Every callback will receive two arguments: the AnyEvent::Mattermost object and
the raw message data received over the Mattermost WebSockets connection. This
message payload will take different forms depending on the type of event which
occurred, but the top-level data structure is always a hash reference with at
least the key C<event> (with a value matching that which you used to register
the callback). Most event types include a C<data> key, whose value is a hash
reference containing the payload of the event. For channel messages this will
include things like the sender's name, the channel name and type, and of course
the message itself.

For more explanation of event types, hope that the Mattermost project documents
them at some point. For now, L<Data::Dumper> based callbacks are your best bet.

=cut

sub on {
    my ($self, %registrations) = @_;

    foreach my $type (keys %registrations) {
        my $cb = $registrations{$type};
        $self->{'registry'}{$type} = $cb;
    }
}

=head2 send

    $mconn->send( \%message );

Posts a message to the Mattermost server. This method is currently fairly
limited and supports only providing a channel name and a message body. There
are formatting, attachment, and other features that are planned to be
supported in future releases.

The C<\%message> hash reference should contain at bare minimum two keys:

=over 4

=item * channel

The name of the channel to which the message should be posted. This may be
either the short name (which appears in URLs in the web UI) or the display
name (which may contain spaces). In the case of conflicts, the display name
takes precedence, on the theory that it is the most enduser-visible name of
channels and thus the least surprising.

=item * message

The body of the message to be posted. This may include any markup options that
are supported by Mattermost, which includes a subset of the Markdown language
among other things.

=back

To announce your presence to the default Mattermost channel (Town Square, using
its short name), you might call the method like this:

    $mconn->send({ channel => "town-square", message => "Hey everybody!" });

=cut

sub send {
    my ($self, $data) = @_;

    croak "cannot send message because connection has not yet started"
        unless $self->started;

    croak "send payload must be a hashref"
        unless defined $data && ref($data) eq 'HASH';
    croak "message must be a string of greater than zero bytes"
        unless exists $data->{'message'} && !ref($data->{'message'}) && length($data->{'message'}) > 0;
    croak "message must have a destination channel"
        unless exists $data->{'channel'} && length($data->{'channel'}) > 0;

    my $team_id = $self->{'teamdata'}{'id'};
    my $user_id = $self->{'userdata'}{'id'};
    my $channel_id = $self->_get_channel_id($data->{'channel'});

    my $create_at = int(time() * 1000);

    my $res = $self->_post('api/v3/teams/' . $team_id . '/channels/' . $channel_id . '/posts/create', {
        user_id         => $user_id,
        channel_id      => $channel_id,
        message         => $data->{'message'},
        create_at       => $create_at+0,
        filenames       => [],
        pending_post_id => $user_id . ':' . $create_at,
    });
}


=head1 INTERNAL METHODS

The following methods are not intended to be used by code outside this module,
and their signatures (even their very existence) are not guaranteed to remain
stable between versions. However, if you're the adventurous type ...

=cut

=head2 ping

    $mconn->ping();

Pings the Mattermost server over the WebSocket connection to maintain online
status and ensure the connection remains alive. You should not have to call
this method yourself, as start() sets up a ping callback on a timer for you.

=cut

sub ping {
    my ($self) = @_;

    $self->{'conn'}->send("ping");
}

=head2 started

    $mconn->started();

Returns a boolean status indicating whether the Mattermost WebSockets API
connection has started yet.

=cut

sub started {
    my ($self) = @_;

    return $self->{'started'} // 0;
}

=head1 LIMITATIONS

=over 4

=item * Only basic message sending and receiving is currently supported.

=back

=head1 CONTRIBUTING

If you would like to contribute to this module, report bugs, or request new
features, please visit the module's official GitHub project:

L<https://github.com/jsime/anyevent-mattermost>

=head1 AUTHOR

Jon Sime <jonsime@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jon Sime.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

sub _do {
    my ($self, $type, @args) = @_;

    if (defined $self->{'registry'}{$type}) {
        $self->{'registry'}{$type}->($self, @args);
    }
}

sub _handle_incoming {
    my ($self, $conn, $raw) = @_;

    my $msg = try {
        decode_json($raw->body);
    }
    catch {
        my $message = $raw->body;
        croak "unable to decode incoming message: $message";
    };

    if ($msg->{'event'} eq 'hello') {
        $self->{'hello'}++;
        $self->_do($msg->{'event'}, $msg);
    } else {
        $self->_do($msg->{'event'}, $msg);
    }
}

sub _get_channel_id {
    my ($self, $channel_name) = @_;

    unless (exists $self->{'channels'}{$channel_name}) {
        my $data = $self->_get('api/v3/teams/' . $self->{'teamdata'}{'id'} . '/channels/');

        croak "no channels returned"
            unless defined $data && ref($data) eq 'HASH'
                && exists $data->{'channels'} && ref($data->{'channels'}) eq 'ARRAY';

        foreach my $channel (@{$data->{'channels'}}) {
            next unless ref($channel) eq 'HASH'
                && exists $channel->{'id'} && exists $channel->{'name'};

            $self->{'channels'}{$channel->{'name'}} = $channel->{'id'};
            $self->{'channels'}{$channel->{'display_name'}} = $channel->{'id'};
        }

        # Ensure that we got the channel we were looking for.
        croak "channel $channel_name was not found"
            unless exists $self->{'channels'}{$channel_name};
    }

    return $self->{'channels'}{$channel_name};
}

sub _get {
    my ($self, $path) = @_;

    my $furl = $self->{'furl'};
    my $res = $furl->get($self->{'host'} . $path, $self->_headers);

    my $data = try {
        decode_json($res->content);
    } catch {
        my $status = $res->status;
        my $message = $res->content;
        croak "unable to call $path: $status $message";
    };

    return $data;
}

sub _post {
    my ($self, $path, $postdata) = @_;

    my $furl = $self->{'furl'};

    my $res = try {
        $furl->post($self->{'host'} . $path, $self->_headers, encode_json($postdata));
    } catch {
        croak "unable to post to mattermost api: $_";
    };

    # Check for session token and update if it was present in response.
    if (my $token = $res->header('Token')) {
        $self->{'token'} = $token;
    }

    my $data = try {
        decode_json($res->content);
    } catch {
        my $status = $res->status;
        my $message = $res->content;
        croak "unable to call $path: $status $message";
    };

    return $data;
}

sub _headers {
    my ($self) = @_;

    my $headers = [
        'Content-Type'      => 'application/json',
        'X-Requested-With'  => 'XMLHttpRequest',
    ];

    # initial_load is fine with just the Cookie, other endpoints like channels/
    # require Authorization. We'll just always include both to be sure.
    if (exists $self->{'token'}) {
        push(@{$headers},
            'Cookie'        => 'MMAUTHTOKEN=' . $self->{'token'},
            'Authorization' => 'Bearer ' . $self->{'token'},
        );
    }

    return $headers;
}

1;
