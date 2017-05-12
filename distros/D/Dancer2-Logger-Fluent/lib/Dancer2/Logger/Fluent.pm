package Dancer2::Logger::Fluent;

use strict;
use 5.008_005;
our $VERSION = '0.06';

use Moo;
use Fluent::Logger;
use IO::Socket::INET;
use IO::Socket::UNIX;

use File::Basename 'basename';
use Time::Moment;
use Sys::Hostname;

use Dancer2::Core::Types;
with 'Dancer2::Core::Role::Logger';

has tag_prefix => (
    is        => 'lazy',
    isa       => Str,
);

has host => (
    is        => 'ro',
    isa       => Str,
);

has port => (
    is        => 'ro',
    isa       => Str,
);

has timeout => (
    is        => 'ro',
    isa       => Num,
    predicate => '_has_timeout',
);

has socket => (
    is        => 'ro',
    isa       => Str,
);

has prefer_integer => (
    is        => 'ro',
    isa       => Str,
    predicate => '_has_prefer_integer',
);

has event_time => (
    is        => 'ro',
    isa       => Bool,
);

has buffer_limit => (
    is        => 'ro',
    isa       => Int,
    predicate => '_has_buffer_limit',
);

has buffer_overflow_handler => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => '_has_buffer_overflow_handler',
);

has truncate_buffer_at_overflow => (
    is        => 'ro',
    isa       => Bool,
);

sub _build_tag_prefix {
    my $self = shift;
    return $self->{tag_prefix} || $self->app_name || $ENV{DANCER_APPDIR} || basename($0);
}

sub _connect {
    my $self = shift;
    return defined $self->socket
        ? IO::Socket::UNIX->new( Peer => $self->socket )
        : IO::Socket::INET->new(
            PeerAddr  => $self->host || '127.0.0.1',
            PeerPort  => $self->port || 24224,
            Proto     => 'tcp',
            Timeout   => $self->_has_timeout ? $self->timeout : 3.0,
            ReuseAddr => 1,
    );
}

sub _fluent {
    my $self = shift;

    return unless $self->_connect;

    unless ( exists $self->{_fluent} ) {
        $self->{_fluent} = Fluent::Logger->new(
            host                        => $self->host || '127.0.0.1',
            port                        => $self->port || 24224,
            timeout                     => $self->_has_timeout ? $self->timeout : 3.0,
            socket                      => $self->socket,
            prefer_integer              => $self->_has_prefer_integer ? $self->prefer_integer : 1,
            event_time                  => $self->event_time || 0,
            buffer_limit                => $self->_has_buffer_limit ? $self->buffer_limit : 8388608,
            buffer_overflow_handler     => $self->_has_buffer_overflow_handler ? $self->buffer_overflow_handler : sub { undef },
            truncate_buffer_at_overflow => $self->truncate_buffer_at_overflow || 0,
        );
    }

    return $self->{_fluent};
}

sub DESTROY {
    my $self = shift;
    return unless $self->_fluent;
    $self->_fluent->{pending} ||= '';  # Fluent::Logger->close performs length checks without checking if value is defined first
    $self->_fluent->close;
}

sub log {
    my ($self, $level, $message) = @_;

    my $fluent_message = {
        env       => $ENV{DANCER_ENVIRONMENT} || $ENV{PLACK_ENV} || 'development',
        timestamp => Time::Moment->now_utc->strftime("%Y-%m-%dT%H:%M:%S.%6N%Z"),
        host      => hostname(),
        level     => $level,
        message   => $message,
        pid       => $$
    };

    # Queue pending messages until connectivity is restored
    unless ( $self->_fluent ) {
        push @{ $self->{pending} }, $fluent_message;
        return;
    }

    if ( exists $self->{pending} and @{ $self->{pending} } ) {
        while ( my $pending_message = shift @{ $self->{pending} } ) {
            $self->_fluent->post( $self->tag_prefix, $pending_message );
        }
    }
    $self->_fluent->post( $self->tag_prefix, $fluent_message );
}

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Logger::Fluent - Dancer2 logger engine for Fluent::Logger

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Dancer2::Logger::Fluent;

=head1 DESCRIPTION

Implements a structured event logger for Fluent via L<Fluent::Logger>.

When a connection to the C<fluentd> agent can't be established, messages
are "queued" internally. These messages will be flushed upon subsequent
calls to C<log()>, as soon as a connection is established.

=head1 METHODS

=head2 log($level, $message)

Writes the log message to Fluent.

=head1 CONFIGURATION

The setting B<logger> should be set to C<Fluent> in order to use this logging
engine in a Dancer2 application.

Below is a simple sample configuration:

  logger: "Fluent"

  engines:
    logger:
      Fluent:
        tag_prefix: "myapp"
        host: "127.0.0.1"
        port: 24224

The full list of allowed options are as follows:

=over 4

=item tag_prefix

Tag prepended to every message, defaults to the configured I<appname> or,
if not defined, to the executable's basename.

=item host

Host running the C<fluentd> agent, defaults to '127.0.0.1'.

=item port

Port listened by the C<fluentd> agent, defaults to 24224.

=item timeout

Timeout in seconds, defaults to 3.0 as implemented in
L<Fluent::Logger>.

=item socket

Socket file location, defaults to undef as implemented in
L<Fluent::Logger>.

=item prefer_integer

Whether integer is preferred as cascaded to
Data::MessagePack->prefer_integer.  Defaults to 1.

=item event_time

Whether event timestamps (includes nanoseconds as supported by
C<fluentd> >= 0.14.0) will be included. Defaults to 0.

=item buffer_limit

Buffer size limit, defaults to 8388608 (8MB) as implemented in
L<Fluent::Logger>.

=item buffer_overflow_handler

Custom coderef to handle buffer overflow in the event of connection
failure, to mitigate loss of data in the event of connection failure.

=item truncate_buffer_at_overflow

When I<truncate_buffer_at_overflow> is true and pending buffer size is
larger than I<buffer_limit>, pending buffer will still be kept but last
message will not be sent and will not be appended to the buffer.
Defaults to 0.

=back

=head1 MESSAGE FORMAT

Messages to C<fluentd> will be a hash containing the following:

  {
    env       => $environment,
    timestamp => $current_timestamp,
    host      => $hostname,
    level     => $level,
    message   => $message,
    pid       => $$
  }

=head1 AUTHOR

Arnold Tan Casis E<lt>atancasis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2017- Arnold Tan Casis

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

See L<Dancer2> for details about logging in route handlers.

See L<http://fluent.github.com> for details on C<fluentd> itself.

=cut
