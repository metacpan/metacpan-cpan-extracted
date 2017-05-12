package AnyEvent::APNS;
use utf8;
use Any::Moose;

use AnyEvent 4.80;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::TLS;

require bytes;
use Carp qw(croak);
use Encode;
use Scalar::Util 'looks_like_number';
use JSON::Any;

our $VERSION = '0.10';

has certificate => (
    is       => 'rw',
    isa      => 'Str | ScalarRef',
    required => 1,
);

has private_key => (
    is       => 'rw',
    isa      => 'Str | ScalarRef',
    required => 1,
);

has sandbox => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has handler => (
    is        => 'rw',
    isa       => 'AnyEvent::Handle',
    predicate => 'connected',
    clearer   => 'clear_handler',
);

has json_driver => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        JSON::Any->new( utf8 => 1 );
    },
);

has on_error => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub { warn @_ } },
);

has on_eof => (
    is  => 'rw',
    isa => 'CodeRef',
);

has on_connect => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub {} },
);

has on_error_response => (
    is  => 'rw',
    isa => 'CodeRef',
);

has debug_port => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'is_debug',
);

has _con_guard => (
    is  => 'rw',
    isa => 'Object',
);

has last_identifier => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 0; }
);

no Any::Moose;

sub send {
    my $self = shift;
    my ($token, $payload, $expiry) = @_;

    my $json = encode_utf8( $self->json_driver->encode($payload) );

    # http://developer.apple.com/library/ios/#DOCUMENTATION/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html
    # Expiry—A fixed UNIX epoch date expressed in seconds (UTC) that identifies when the notification is no longer valid and can be discarded. The expiry value should be in network order (big endian). If the expiry value is positive, APNs tries to deliver the notification at least once. You can specify zero or a value less than zero to request that APNs not store the notification at all.
    # default to 24 hours
    $expiry  = defined $expiry ? $expiry : time() + 3600 * 24;

    # Identifier—An arbitrary value that identifies this notification. This same identifier is returned in a error-response packet if APNs cannot interpret a notification.
    my $next_identifier = $self->_increment_identifier;

    my $h = $self->handler;

    $h->push_write( pack('C', 1) ); # command
    $h->push_write( pack('N', $next_identifier) );
    $h->push_write( pack('N', $expiry) );
    $h->push_write( pack('n', bytes::length($token)) ); # token length
    $h->push_write( $token );                           # device token

    # Apple Push Notification Service refuses string values as badge number
    if ($payload->{aps}{badge} && looks_like_number($payload->{aps}{badge})) {
        $payload->{aps}{badge} += 0;
    }

    # The maximum size allowed for a notification payload is 256 bytes;
    # Apple Push Notification Service refuses any notification that exceeds this limit.
    if ( (my $exceeded = bytes::length($json) - 256) > 0 ) {
        if (ref $payload->{aps}{alert} eq 'HASH') {
            $payload->{aps}{alert}{body} =
                $self->_trim_utf8($payload->{aps}{alert}{body}, $exceeded);
        }
        else {
            $payload->{aps}{alert} = $self->_trim_utf8($payload->{aps}{alert}, $exceeded);
        }

        $json = encode_utf8( $self->json_driver->encode($payload) );
    }

    $h->push_write( pack('n', bytes::length($json)) ); # payload length
    $h->push_write( $json );                           # payload

    return $next_identifier;
}

sub _trim_utf8 {
    my ($self, $string, $trim_length) = @_;

    my $string_bytes = encode_utf8($string);
    my $trimmed = '';

    my $start_length = bytes::length($string_bytes) - $trim_length;
    return $trimmed if $start_length <= 0;

    for my $len ( reverse $start_length - 6 .. $start_length ) {
        local $@;
        eval {
            $trimmed = decode_utf8(substr($string_bytes, 0, $len), Encode::FB_CROAK);
        };
        last if $trimmed;
    }

    return $trimmed;
}

sub connect {
    my $self = shift;

    if ($self->connected && $self->handler) {
        warn 'Already connected!';
        return;
    }

    my $host = $self->sandbox
        ? 'gateway.sandbox.push.apple.com'
        : 'gateway.push.apple.com';
    my $port = 2195;

    if ($self->is_debug) {
        $host = '127.0.0.1';
        $port = $self->debug_port;
    }
    my $g = tcp_connect $host, $port, sub {
        my ($fh) = @_
            or return $self->on_error->(undef, 1, $!);

        my $tls_setting = {};
        if (ref $self->certificate) {
            $tls_setting->{cert}      = ${ $self->certificate };
        }
        else {
            $tls_setting->{cert_file} = $self->certificate;
        }

        if (ref $self->private_key) {
            $tls_setting->{key}       = ${ $self->private_key };
        }
        else {
            $tls_setting->{key_file}  = $self->private_key;
        }

        my $handle = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub {
                $self->on_error->(@_);
                $self->clear_handler;
                $_[0]->destroy;
            },
            !$self->is_debug ? (
                tls      => 'connect',
                tls_ctx  => $tls_setting,
            ) : (),
        );
        $self->handler( $handle );

        if ($self->on_eof) {
            $handle->on_eof(sub {
                $self->on_eof->(@_);
                $self->clear_handler;
                $_[0]->destroy;
            });
        }

        if ( $self->on_error_response ) {
            $handle->on_read(
                sub {
                    $self->_on_read_with_error_callback( @_ );
                }
            );
        }
        else {
            $handle->on_read( sub { delete $_[0]->{rbuf} } );
        }

        $self->on_connect->();
    };

    Scalar::Util::weaken($self);
    $self->_con_guard($g);

    $self;
}

sub _on_read_with_error_callback {
    my ($self, $handle) = @_;
    $handle->push_read( chunk => 1,
                        sub {
                            my $command = unpack( 'C', $_[1] );
                            if ( $command != 8 ) {
                                # something is wrong
                                # auto reconnect
                                $self->clear_handler;
                                $self->connect;
                            }
                        });
    $handle->push_read( chunk => 5,
                        sub {
                            my $status     = unpack( 'C', substr( $_[1], 0, 1) );
                            my $identifier = unpack( 'N', substr( $_[1], 1, 4) );
                            $self->on_error_response->( $identifier => $status );
                        });
}

# 0 ... 2**32-1, 0 ... 2**32-1, 0 ...
sub _increment_identifier {
    my ($self) = @_;
    my $next_identifier = $self->last_identifier + 1;
    if ( $next_identifier >= 2 ** 32 ) {
        # identifier is only 4 bytes
        $next_identifier = 0;
    }
    $self->last_identifier( $next_identifier );
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords
apns SDK TODO iPhone multi-byte utf8

=head1 NAME

AnyEvent::APNS - Simple wrapper for Apple Push Notifications Service (APNS) provider

=head1 SYNOPSIS

    use AnyEvent::APNS;

    my $cv = AnyEvent->condvar;

    my $apns; $apns = AnyEvent::APNS->new(
        certificate => 'your apns certificate file',
        private_key => 'your apns private key file',
        sandbox     => 1,
        on_error    => sub { # something went wrong },
        on_connect  => sub {
            my $identifier = $apns->send( $device_token => {
                aps => {
                    alert => 'Message received from Bob',
                },
            });
        },
        on_error_response => sub {
            my ($identifier, $status) = @_;
            # something wrong
        },
    );
    $apns->connect;

    # disconnect and exit program as soon as possible after sending a message
    # otherwise $apns makes persistent connection with apns server
    $apns->handler->on_drain(sub {
        undef $_[0];
        $cv->send;
    });

    $cv->recv;

=head1 DESCRIPTION

This module helps you to create Apple Push Notifications Service (APNS) Provider.

=head1 NOTE FOR 0.01x USERS

From 0.02, this module does not connect in constructor.
You should call connect method explicitly to connect server.

=head1 METHODS

=head2 new

Create APNS object.

    my $apns = AnyEvent::APNS->new(
        certificate => 'your apns certificate file',
        private_key => 'your apns private key file',
        sandbox     => 1,
        on_error    => sub { # something went wrong },
    );

Supported arguments are:

=over 4

=item certificate => 'Str | ScalarRef'

    certificate => '/path/to/certificate_file',
    # or
    certificate => \$certificate,

Required. Either file path for certificate or scalar-ref of certificate data.

=item private_key => 'Str | ScalarRef'

    private_key => '/path/to/private_key',
    # or
    private_key => \$private_key,

Required. Either file path for private_key or scalar-ref of private-key data.

=item sandbox => 0|1

This is a flag indicate target service is provisioning (sandbox => 1) or distribution (sandbox => 0)

Optional (Default: 0)

=item on_error => $cb->($handle, $fatal, $message)

Callback to be called when something error occurs.
This is wrapper for L<AnyEvent::Handle>'s on_error callbacks. Look at the document for more detail.

Optional (Default: just warn error)

=item on_eof => $cb->($handle)

Callback to be called when an end-of-file condition is detected.

Optional. (Default: use on_error instead. read L<AnyEvent::Handle> for more detail)

=item on_connect => $cb->()

Callback to be called when connection established to apns server.

Optional (Default: empty coderef)

=item on_error_response => $cb->($identifier, $status)

Callback to be called when APNs detects notification malformed or otherwise unintelligible.

C<$status> codes are documented here: L<http://developer.apple.com/library/ios/#DOCUMENTATION/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html>

C<$identifier> is the return value of C<send>.

Optional (Default: ignore)

=back

=head2 $apns->connect;

Connect to apns server.

=head2 $apns->send( $device_token, \%payload )

Send apns messages with C<\%payload> to device specified C<$device_token>.

    my $identifier = $apns->send( $device_token => {
        aps => {
            alert => 'Message received from Bob',
        },
    });

C<$device_token> should be a binary 32bytes device token provided by iPhone SDK (3.0 or above)

C<\%payload> should be a hashref suitable to apple document: L<http://developer.apple.com/iPhone/library/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html>

Note: If you involve multi-byte strings in C<\%payload>, it should be utf8 decoded strings not utf8 bytes.

Store C<$identifier> with your C<$device_token> to react to C<on_error_response>.

=head2 $apns->handler

Return L<AnyEvent::Handle> object which is used to current established connection. It returns undef before connection completed.

=head1 TODO

=over 4

=item *

More correct error handling

=item *

Auto reconnection

=back

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
