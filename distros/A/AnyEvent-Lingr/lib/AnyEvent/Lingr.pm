package AnyEvent::Lingr;
use Mouse;

our $VERSION = '0.07';

use AnyEvent::HTTP;

use Carp;
use JSON;
use Log::Minimal;
use Scalar::Util ();
use Try::Tiny;
use URI;

has ['user', 'password'] => (
    is       => 'ro',
    required => 1,
);

has 'api_key' => (
    is => 'ro',
);

has 'endpoint' => (
    is      => 'ro',
    default => 'http://lingr.com/api/',
);

has 'session' => (
    is => 'rw',
);

has ['on_error', 'on_room_info', 'on_event'] => (
    is  => 'rw',
    isa => 'CodeRef',
);

has 'counter' => (
    is  => 'rw',
    isa => 'Int',
);

has '_polling_guard' => (
    is      => 'rw',
    clearer => '_clear_polling_guard',
);

no Mouse;

sub request {
    my ($self, $http_method, $method, $params, $cb) = @_;

    my $uri = URI->new($self->endpoint . $method);
    $uri->query_form($params);

    my $cb_wrap = sub {
        my ($body, $hdr) = @_;

        my $json = try { decode_json $body };
        $cb->($json, $hdr);
    };

    if ($http_method eq 'GET') {
        http_get $uri, $cb_wrap;
    } elsif ($http_method eq 'POST') {
        my $body = $uri->query;
        $uri->query(undef);
        http_post $uri, $body, $cb_wrap;
    } else {
        croak "unsupported http method: $http_method"
    }

    1;
}

sub get {
    shift->request('GET', @_);
}

sub post {
    shift->request('POST', @_);
}

sub _on_error {
    my ($self, $res, $hdr) = @_;

    $self->_clear_polling_guard;

    if (my $cb = $self->on_error) {
        if ($res) {
            $cb->($res->{detail});
        }
        else {
            $cb->($hdr->{Status} . ': ' . $hdr->{Reason});
        }
    }
    else {
        debugf 'on_error callback does not set';
        critf "res:%s hdr:%s", ddf($res), ddf($hdr);
    }
}

sub start_session {
    my ($self) = @_;

    debugf "starting session...";

    if ($self->session) {
        debugf "found old session:%s reusing...", $self->session;

        $self->get('session/verify', { session => $self->session }, sub {
            my ($res, $hdr) = @_;
            return unless $self;

            if ($res and $res->{status} eq 'ok') {
                infof "session verified: %s", $res->{session};
                $self->_get_channels;
            }
            else {
                debugf "session verify failed: %s", ddf($res || $hdr);
                $self->session(undef);
                $self->_on_error($res, $hdr);
            }
        });
    }
    else {
        debugf "create new session...";

        $self->post('session/create', {
            user     => $self->user,
            password => $self->password,
            $self->api_key ? (api_key => $self->api_key) : (),
        }, sub {
            my ($res, $hdr) = @_;
            return unless $self;

            if ($res and $res->{status} eq 'ok') {
                debugf "session created: %s", $res->{session};
                $self->session( $res->{session} );
                $self->_get_channels;
            }
            else {
                debugf "session create failed: %s", ddf($res || $hdr);
                $self->_on_error($res, $hdr);
            }
        });
    }

    Scalar::Util::weaken($self);
}

sub update_room_info {
    my ($self) = @_;
    $self->_get_channels;
}

sub _get_channels {
    my ($self) = @_;

    debugf "getting joined channels";

    $self->get('user/get_rooms', { session => $self->session }, sub {
        my ($res, $hdr) = @_;
        return unless $self;

        if ($res and $res->{status} eq 'ok') {
            debugf "got rooms: %s", ddf($res->{rooms});
            $self->_update_room_info( $res->{rooms} );
        }
        else {
            $self->_on_error($res, $hdr);
        }
    });
    Scalar::Util::weaken($self);
}

sub _update_room_info {
    my ($self, $rooms) = @_;

    $self->get('room/show', { session => $self->session, room => join ',', @{ $rooms } }, sub {
        my ($res, $hdr) = @_;
        return unless $self;

        if ($res and $res->{status} eq 'ok') {
            debugf "got room infos";
            if ($self->on_room_info) {
                $self->on_room_info->($res->{rooms});
            }
            else {
                debugf "no room info callback";
            }

            $self->_start_observe($rooms);
        }
        else {
            $self->_on_error($res, $hdr);
        }
    });
    Scalar::Util::weaken($self);
}

sub _start_observe {
    my ($self, $rooms) = @_;

    $self->post('room/subscribe', {
        session => $self->session,
        rooms   => join(',', @$rooms),
        reset   => 1,
    }, sub {
        my ($res, $hdr) = @_;
        return unless $self;

        if ($res and $res->{status} eq 'ok') {
            $self->counter( $res->{counter} );
            $self->_polling;
        }
        else {
            $self->_on_error($res, $hdr);
        }
    });
    Scalar::Util::weaken($self);
}

sub _polling {
    my ($self) = @_;

    if ($self->_polling_guard) {
        debugf 'polling session is still active, ignoring this request';
        return;
    }

    my $uri = URI->new( $self->endpoint . 'event/observe' );
    $uri->port(8080);
    $uri->query_form({ session => $self->session, counter => $self->counter });

    my $guard = http_get $uri, timeout => 60, sub {
        my ($body, $hdr) = @_;
        return unless $self;

        my $res = try { decode_json $body };

        if ($res and $res->{status} eq 'ok') {
            if ($res->{counter}) {
                $self->counter( $res->{counter} );
            }
            if ($res->{events}) {
                if (my $cb = $self->on_event) {
                    $cb->($_) for @{ $res->{events} };
                }
                else {
                    debugf "no on_event callback";
                }
            }

            $self->_clear_polling_guard;
            $self->_polling;
        }
        else {
            $self->_on_error($res, $hdr);
        }
    };
    Scalar::Util::weaken($self);

    $self->_polling_guard( $guard );
}

sub say {
    my ($self, $room, $msg, $cb) = @_;

    $self->post('room/say', { session => $self->session, room => $room, text => $msg }, sub {
        my ($res, $hdr) = @_;
        return unless $self;

        if ($res and $res->{status} eq 'ok') {
            $cb->($res) if $cb;
        }
        else {
            $self->_on_error($res, $hdr);
        }
    });

    Scalar::Util::weaken($self);
}

1;

__END__

=head1 NAME

AnyEvent::Lingr - Asynchronous Lingr client.

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Lingr;
    
    my $lingr = AnyEvent::Lingr->new(
        user     => 'your lingr username',
        password => 'your lingr password',
        api_key  => 'your lingr api_key', # optional
    );
    
    # error handler
    $lingr->on_error(sub {
        my ($msg) = @_;
        warn 'Lingr error: ', $msg;
    
        # reconnect after 5 seconds,
        my $t; $t = AnyEvent->timer(
            after => 5,
            cb    => sub {
                $lingr->start_session;
                undef $t;
            },
        );
    });
    
    # room info handler
    $lingr->on_room_info(sub {
        my ($rooms) = @_;
    
        print "Joined rooms:\n";
        for my $room (@$rooms) {
            print "  $room->{id}\n";
        }
    });
    
    # event handler
    $lingr->on_event(sub {
        my ($event) = @_;
    
        # print message
        if (my $msg = $event->{message}) {
            print sprintf "[%s] %s: %s\n",
                $msg->{room}, $msg->{nickname}, $msg->{text};
        }
    });
    
    # start lingr session
    $lingr->start_session;

=head1 DESCRIPTION

AnyEvent::Lingr is asynchronous client interface for L<Lingr|http://lingr.com/>.

=head1 METHODS

=head2 new(%options)

Create AnyEvent::Lingr object. Available %options are:

=over

=item * user => 'Str' (required)

Lingr username

=item * password => 'Str' (required)

Lingr password

=item * api_key => 'Str' (optional)

Lingr api_key.

=item * session => 'Str' (optional)

Lingr session key. If this parameter is passed, this module try to reuse this key for calling session/verify api, otherwise create new session.

=back

    my $lingr = AnyEvent::Lingr->new(
        user     => 'your lingr username',
        password => 'your lingr password',
        api_key  => 'your lingr api_key', # optional
    );

=head2 start_session

Start lingr chat session.

This method runs following sequences:

=over

=item 1. Create session (or verify session if session parameter was passed)

=item 2. Get joined room list, and then fire C<on_room_info> callback.

=item 3. Subscribe all joined room events, and wait events...

=item 4. When some events is occurred, fire C<on_event> callback

=item 5. goto step 3.

=back

For stopping this loop, you just destroy lingr object by doing:

    undef $lingr;

For updating subscription list, you can use C<update_room_info> method:

    $lingr->update_room_info;

=head2 update_room_info

Update joined room info, and fire on_room_info callback.
This method also update subscription rooms which is target room for on_event callback.

=head2 say($room, $message [, $cb ])

Say something to lingr room.

    $lingr->say('perl_jp', 'hi!');

If you want response data, you can speficy callback.
The callback is invoked when the API call was successful.

    $lingr->say('perl_jp', 'hi there!', sub {
        my $res = shift;
        warn $res->{message}->{id};
    });

=head1 CALLBACKS

This module supports following three callbacks:

=over

=item * on_error->($msg)

=item * on_room_info->($rooms)

=item * on_event->($event)

=back

All callbacks can be set by accessor:

    $lingr->on_error(sub { ... });

Or by constructor:

    my $lingr = AnyEvent::Lingr->new(
        ...
        on_error => sub { ... },
    );

=head2 on_error->($msg)

Error callbacks.

C<$msg> is error message. If this message is form of "\d\d\d: message" like:

    595: Invalid argument

This is http level or connection level error. Otherwise C<$msg> is error message returned from lingr api server.

Both case, lingr session was closed before this callback, so you can restart session in this callback:

    $lingr->on_error(sub {
        my ($msg) = @_;
        warn 'Lingr error: ', $msg;
    
        # reconnect after 5 seconds,
        my $t; $t = AnyEvent->timer(
            after => 5,
            cb    => sub {
                $lingr->start_session;
                undef $t;
            },
        );
    });

=head2 on_room_info->($rooms)

Fired when after start_session or after update_room_info method.

C<$rooms> is ArrayRef of room information you joined.

=head2 on_event->($event)

Fired when some events is occurred in your subscribed rooms.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 Daisuke Murase All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
