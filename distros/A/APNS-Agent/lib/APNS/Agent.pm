package APNS::Agent;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.06";

use AnyEvent::APNS;
use Cache::LRU;
use Encode qw/decode_utf8/;
use JSON::XS;
use Log::Minimal;
use Plack::Request;
use Router::Boom::Method;

use Class::Accessor::Lite::Lazy 0.03 (
    new => 1,
    ro => [qw/
        certificate
        private_key
        sandbox
        debug_port
    /],
    ro_lazy => {
        on_error_response   => sub {
            sub {
                my $self = shift;
                my %d = %{$_[0]};
                warnf "identifier:%s\tstate:%s\ttoken:%s", $d{identifier}, $d{state}, $d{token} || '';
            }
        },
        disconnect_interval => sub { 60 },
        send_interval       => sub { 0.01 },
        _sent_cache         => sub { Cache::LRU->new(size => 10000) },
        _queue              => sub { [] },
        __apns              => '_build_apns',
        _sent               => sub { 0 },
    },
    rw => [qw/_last_sent_at _disconnect_timer/],
);

sub to_app {
    my $self = shift;

    my $router = Router::Boom::Method->new;
    $router->add(POST => '/'        => '_do_main');
    $router->add(GET  => '/monitor' => '_do_monitor');

    sub {
        my $env = shift;
        my ($target_method) = $router->match(@$env{qw/REQUEST_METHOD PATH_INFO/});

        return [404, [], ['NOT FOUND']] unless $target_method;

        my $req = Plack::Request->new($env);
        $self->$target_method($req);
    };
}

sub _do_main {
    my ($self, $req) = @_;

    my $token = $req->param('token') or return [400, [], ['Bad Request']];

    my $payload;
    if (my $payload_json = $req->param('payload') ) {
        state $json_driver = JSON::XS->new->utf8;
        local $@;
        $payload = eval { $json_driver->decode($payload_json) };
        return [400, [], ['BAD REQUEST']] if $@;
    }
    elsif (my $alert = $req->param('alert')) {
        $payload = +{
            alert => decode_utf8($alert),
        };
    }
    return [400, [], ['BAD REQUEST']] unless $payload;

    my @payloads = map {[$_, $payload]} split /,/, $token;
    push @{$self->_queue}, @payloads;

    infof "event:payload queued\ttoken:%s", $token;
    if ($self->__apns->connected) {
        $self->_sending;
    }
    else {
        $self->_connect_to_apns;
    }
    return [200, [], ['Accepted']];
}

sub _do_monitor {
    my ($self, $req) = @_;

    my $result = {
        sent   => $self->_sent,
        queued => scalar( @{ $self->_queue } ),
    };
    my $body = encode_json($result);

    return [200, [
        'Content-Type'   => 'application/json; charset=utf-8',
        'Content-Length' => length($body),
    ], [$body]];
}

sub _build_apns {
    my $self = shift;

    AnyEvent::APNS->new(
        certificate => $self->certificate,
        private_key => $self->private_key,
        sandbox     => $self->sandbox,
        on_error    => sub {
            my ($handle, $fatal, $message) = @_;

            my $t; $t = AnyEvent->timer(
                after    => 0,
                interval => 10,
                cb       => sub {
                    undef $t;
                    infof "event:reconnect";
                    $self->_connect_to_apns;
                },
            );
            warnf "event:error\tfatal:$fatal\tmessage:$message";
        },
        on_connect  => sub {
            infof "event:on_connect";
            $self->_disconnect_timer($self->_build_disconnect_timer);

            if (@{$self->_queue}) {
                $self->_sending;
            }
        },
        on_error_response => sub {
            my ($identifier, $state) = @_;
            my $data = $self->_sent_cache->get($identifier) || {};
            $self->on_error_response->($self, {
                identifier => $identifier,
                state      => $state,
                token      => $data->{token},
                payload    => $data->{payload},
            });
        },
        ($self->debug_port ? (debug_port => $self->debug_port) : ()),
    );
}

sub _apns {
    my $self = shift;

    my $apns = $self->__apns;
    $apns->connect unless $apns->connected;
    $apns;
}
sub _connect_to_apns { goto \&_apns }

sub _build_disconnect_timer {
    my $self = shift;

    if (my $interval = $self->disconnect_interval) {
        AnyEvent->timer(
            after    => $interval,
            interval => $interval,
            cb       => sub {
                if ($self->{__apns} && (time - ($self->_last_sent_at || 0) > $interval)) {
                    delete $self->{__apns};
                    delete $self->{_disconnect_timer};
                    infof "event:close apns";
                }
            },
        );
    }
    else { undef }
}

sub _sending {
    my $self = shift;

    $self->{_send_timer} ||= AnyEvent->timer(
        after    => $self->send_interval,
        interval => $self->send_interval,
        cb       => sub {
            my $msg = shift @{ $self->_queue };
            if ($msg) {
                $self->_send(@$msg);
            }
            else {
                delete $self->{_send_timer};
            }
        },
    );
}

sub _send {
    my ($self, $token, $payload) = @_;

    local $@;
    my $identifier;
    eval {
        $identifier = $self->_apns->send(pack("H*", $token) => {
            aps => $payload,
        });
    };

    if (my $err = $@) {
        if ($err =~ m!Can't call method "push_write" on an undefined value!) {
            # AnyEvent::APNS->handle is missing
            delete $self->{_send_timer};
            unshift @{ $self->_queue }, [$token, $payload];
            $self->_connect_to_apns;
        }
        else {
            die $err;
        }
    }
    else {
        $self->_sent_cache->set($identifier => {
            token   => $token,
            payload => $payload,
        });
        $self->_last_sent_at(time);
        infof "event:send\ttoken:$token\tidentifier:$identifier";
        $self->{_sent}++;
        $identifier;
    }
}

sub parse_options {
    my ($class, @argv) = @_;

    require Getopt::Long;
    require Pod::Usage;
    require Hash::Rename;

    my $p = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case auto_help pass_through bundling/]
    );
    $p->getoptionsfromarray(\@argv, \my %opt, qw/
        certificate=s
        private-key=s
        disconnect-interval=i
        sandbox!
        debug-port=i
    /) or Pod::Usage::pod2usage();
    Pod::Usage::pod2usage() if !$opt{certificate} || !$opt{'private-key'};

    Hash::Rename::hash_rename(\%opt, code => sub {tr/-/_/});
    (\%opt, \@argv);
}

sub run {
    my $self = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    if (!$args{listen} && !$args{port} && !$ENV{SERVER_STARTER_PORT}) {
        $args{port} = 4905;
    }
    require Plack::Loader;
    Plack::Loader->load(Twiggy => %args)->run($self->to_app);
}

1;
__END__

=encoding utf-8

=head1 NAME

APNS::Agent - agent server for APNS

=head1 SYNOPSIS

    use APNS::Agent;
    my $agent = APNS::Agent->new(
        certificate => '/path/to/certificate',
        private_key => '/path/to/private_key',
    );
    $agent->run;

=head1 DESCRIPTION

APNS::Agent is agent server for APNS. It is also backend class of L<apns-agent>.

This module provides consistent connection to APNS and cares reconnection. It utilizes
L<AnyEvent::APNS> internally.

B<THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.>

=head1 API PARAMETERS

APNS::Agent launches HTTP Server process which accepts only POST method and
C<application/x-www-form-urlencoded> format parameters.

Acceptable parameters as follows:

=over

=item C<token>

device token by HEX format. (Required)

=item C<payload>

JSON string for push notification. If you only want to send message, alternatively can use
C<alert> parameter.

One of C<payload> and C<alert> must be supplied. Both of C<payload> and C<alert> are specified,
the C<payload> parameter has priority.

=item C<alert>

push notification message.

=back

=head1 SEE ALSO

L<AnyEvent::APNS>

=head1 THANKS

Thank B<@shin1rosei> that many code of this module is taken from
L<https://github.com/shin1rosei/AnyEvent-APNS-Server>.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

