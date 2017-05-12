package AnyEvent::RabbitMQ::Fork;
$AnyEvent::RabbitMQ::Fork::VERSION = '0.5';
# ABSTRACT: Run AnyEvent::RabbitMQ inside AnyEvent::Fork(::RPC)

=head1 NAME

AnyEvent::RabbitMQ::Fork - Run AnyEvent::RabbitMQ inside AnyEvent::Fork(::RPC)

=cut

use Moo;
use Types::Standard qw(CodeRef Str HashRef InstanceOf Bool Object);
use Scalar::Util qw(weaken);
use Carp qw(croak);
use File::ShareDir qw(dist_file);

use constant DEFAULT_AMQP_SPEC =>
  dist_file('AnyEvent-RabbitMQ', 'fixed_amqp0-9-1.xml');

use namespace::clean;

use AnyEvent::Fork;
use AnyEvent::Fork::RPC;

use Net::AMQP;

use AnyEvent::RabbitMQ::Fork::Channel;

=head1 SYNOPSIS

  use AnyEvent::RabbitMQ::Fork;

  my $cv = AnyEvent->condvar;

  my $ar = AnyEvent::RabbitMQ::Fork->new->load_xml_spec()->connect(
      host       => 'localhost',
      port       => 5672,
      user       => 'guest',
      pass       => 'guest',
      vhost      => '/',
      timeout    => 1,
      tls        => 0, # Or 1 if you'd like SSL
      tune       => { heartbeat => 30, channel_max => $whatever, frame_max = $whatever },
      on_success => sub {
          my $ar = shift;
          $ar->open_channel(
              on_success => sub {
                  my $channel = shift;
                  $channel->declare_exchange(
                      exchange   => 'test_exchange',
                      on_success => sub {
                          $cv->send('Declared exchange');
                      },
                      on_failure => $cv,
                  );
              },
              on_failure => $cv,
              on_close   => sub {
                  my $method_frame = shift->method_frame;
                  die $method_frame->reply_code, $method_frame->reply_text;
              },
          );
      },
      on_failure => $cv,
      on_read_failure => sub { die @_ },
      on_return  => sub {
          my $frame = shift;
          die "Unable to deliver ", Dumper($frame);
      },
      on_close   => sub {
          my $why = shift;
          if (ref($why)) {
              my $method_frame = $why->method_frame;
              die $method_frame->reply_code, ": ", $method_frame->reply_text;
          }
          else {
              die $why;
          }
      },
  );

  print $cv->recv, "\n";

=cut

has verbose => (is => 'rw', isa => Bool, default => 0);
has is_open => (is => 'ro', isa => Bool, default => 0);
has login_user        => (is => 'ro', isa => Str);
has server_properties => (is => 'ro', isa => Str);

has worker_class    => (is => 'lazy', isa => Str);
has channel_class   => (is => 'lazy', isa => Str);
has worker_function => (is => 'lazy', isa => Str);
has init_function   => (is => 'lazy', isa => Str);

sub _build_worker_class    { return __PACKAGE__ . '::Worker' }
sub _build_channel_class   { return __PACKAGE__ . '::Channel' }
sub _build_worker_function { return $_[0]->worker_class . '::run' }
sub _build_init_function   { return $_[0]->worker_class . '::init' }

has _drain_cv => (is => 'lazy', isa => Object, predicate => 1, clearer => 1);

sub _build__drain_cv { return AE::cv }

has channels => (
    is      => 'ro',
    isa     => HashRef [InstanceOf ['AnyEvent::RabbitMQ::Fork::Channel']],
    clearer => 1,
    default  => sub { {} },
    init_arg => undef,
);

has cb_registry => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
    clearer  => 1,
    init_arg => undef,
);

has rpc => (
    is        => 'lazy',
    isa       => CodeRef,
    predicate => 1,
    clearer   => 1,
    init_arg  => undef,
);

sub _build_rpc {
    my $self = shift;
    weaken(my $wself = $self);

    return AnyEvent::Fork->new          #
      ->require($self->worker_class)    #
      ->send_arg($self->worker_class, verbose => $self->verbose)    #
      ->AnyEvent::Fork::RPC::run(
        $self->worker_function,
        async      => 1,
        serialiser => $AnyEvent::Fork::RPC::STORABLE_SERIALISER,
        on_event   => sub { $wself->_on_event(@_) },
        on_error   => sub { $wself->_on_error(@_) },
        on_destroy => sub { $wself->_on_destroy(@_) },
        init       => $self->init_function,
        # TODO look into
        #done => '',
      );
}

=head1 DESCRIPTION

This module is mean't to be a close to a drop-in facade for running
L<AnyEvent::RabbitMQ> in a background process via L<AnyEvent::Fork::RPC>.

Tha main use case is for programs where other operations block with little
control due to difficulty/laziness. In this way, the process hosting the
connection RabbitMQ is doing nothing else but processing messages.

=cut

my $cb_id = 'a';    # textual ++ gives a bigger space than numerical ++

sub _delegate {
    my ($self, $method, $ch_id, @args, %args) = @_;

    unless (@args % 2) {
        %args = @args;
        @args = ();
        foreach my $event (grep { /^on_/ } keys %args) {
            my $id = $cb_id++;

            # store the user callback
            $self->cb_registry->{$id} = delete $args{$event};

            # create a signature to send back to on_event
            $args{$event} = [$id, $event, $method, scalar caller];
        }
    }

    $self->rpc->(
        $method, $ch_id,
        (@args ? @args : %args),
        sub {
            croak @_ if @_;
        }
    );

    return $self;
}

=head1 CONSTRCTOR

    my $ar = AnyEvent::RabbitMQ::Fork->new();

=head2 Options

=over

=item verbose [Bool]

Prints a LOT of debugging information to C<STDOUT>.

=back

=cut

before verbose => sub {
    return if @_ < 2;
    $_[0]->_delegate(verbose => 0, $_[1]);
};

=head1 METHODS

=over

=item load_xml_spec([$amqp_spec_xml_path])

Declare and load the AMQP Specification you wish to use. The default id to use
version 0.9.1 with RabbitMQ specific extensions.

B<Returns: $self>

=cut

my $_loaded_spec;
sub load_xml_spec {
    my $self = shift;
    my $spec = shift || DEFAULT_AMQP_SPEC;

    if ($_loaded_spec and $_loaded_spec ne $spec) {
        croak(
            "Tried to load AMQP spec $spec, but have already loaded $_loaded_spec, not possible"
        );
    } elsif (!$_loaded_spec) {
        Net::AMQP::Protocol->load_xml_spec($_loaded_spec = $spec);
    }

    return $self->_delegate(load_xml_spec => 0, $spec);
}

=item connect(%opts)

Open connection to an AMQP server to begin work.

Arguments:

=over

=item B<host>

=item B<port>

=item B<user>

=item B<pass>

=item B<vhost>

=item B<timeout> TCP timeout in seconds. Default: use L<AnyEvent::Socket> default

=item B<tls> Boolean to use SSL/TLS or not. Default: 0

=item B<tune> Hash: (values are negotiated with the server)

=over

=item B<heartbeat> Heartbeat interval in seconds. Default: 0 (off)

=item B<channel_max> Maximum channel ID. Default: 65536

=item B<frame_max> Maximum frame size in bytes. Default: 131072

=back

=item B<on_success> Callback when the connection is successfully established.

=item B<on_failure> Called when a failure occurs over the lifetime of the connection.

=item B<on_read_failure> Called when there is a problem reading response from the server.

=item B<on_return> Called if the server returns a published message.

=item B<on_close> Called when the connection is closed remotely.

=back

B<Returns: $self>

=item open_channel(%opts)

Open a logical channel which is where all the AMQP fun is.

Arguments:

=over

=item B<on_success> Called when the channel is open and ready for use.

=item B<on_failure> Called if there is a problem opening the channel.

=item B<on_close> Called when the channel is closed.

=back

=item close(%opts)

Close this connection.

=over

=item B<on_success> Called on successful shutdown.

=item B<on_failure> Called on failed shutdown. Note: the connection is still
closed after this

=back

=back

=cut

foreach my $method (qw(connect open_channel close)) {
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        return $self->_delegate($method => 0, @_);
    };
}

sub drain_writes {
    my ($self, $to) = @_;

    my $w;
    if ($to) {
        $w = AE::timer $to, 0,
          sub { $self->_drain_cv->croak("Timed out after $to") };
    }

    $self->_drain_cv->recv;
    $self->_clear_drain_cv;
    undef $w;

    return;
}

my %event_handlers = (
    cb  => '_handle_callback',
    cbd => '_handle_callback_destroy',
    chd => '_handle_channel_destroy',
    cdw => '_handle_connection_drain_writes',
    i   => '_handle_info',
);

sub _on_event {
    my $self = shift;
    my $type = shift;

    if (my $handler = $event_handlers{$type}) {
        $self->$handler(@_);
    } else {
        croak "Unknown event type: '$type'";
    }

    return;
}

sub _handle_callback {    ## no critic (Subroutines::RequireArgUnpacking)
    my $self = shift;
    my $sig  = shift;
    my ($id, $event, $method, $pkg) = @$sig;

    warn "_handle_callback $id $event $method $pkg\n" if $self->verbose;

    if (my $cb = $self->cb_registry->{$id}) {
        if (ref($_[0]) eq 'REF' and ref(${ $_[0] }) eq 'ARRAY') {
            my ($class, @args) = @{ ${ $_[0] } };

            if ($class eq 'AnyEvent::RabbitMQ') {
                $_[0] = $self;
            } elsif ($class eq 'AnyEvent::RabbitMQ::Channel') {
                my $channel_id = shift @args;
                $_[0] = $self->channels->{$channel_id}
                  ||= $self->channel_class->new(
                    id         => $channel_id,
                    connection => $self
                  );
            } else {
                croak "Unknown class type: '$class'";
            }
        }

        goto &$cb;
    } else {
        croak "Unknown callback id: '$id'";
    }

    return;
}

sub _handle_info {
    my ($self, $info) = @_;

    $self->_handle_connection_info(%{ delete $info->{connection} })
        if $info->{connection};

    $self->_handle_channel_info($_, %{ $info->{$_} }) foreach keys %$info;

    return;
}

# channel information passback
sub _handle_channel_info {
    my ($self, $ch_id, %args) = @_;

    warn "_handle_channel_info $ch_id @{[ %args ]}\n" if $self->verbose;

    if (my $ch = $self->channels->{$ch_id}) {
        @$ch{ keys %args } = values %args;
    } else {
        croak "Unknown channel: '$ch_id'";
    }

    return;
}

sub _handle_channel_destroy {
    my ($self, $ch_id) = @_;

    warn "_handle_channel_destroy $ch_id\n" if $self->verbose;

    delete $self->channels->{$ch_id};

    return;
}

# connection information passback
sub _handle_connection_info {
    my ($self, %args) = @_;

    warn "_handle_connection_info @{[ %args ]}\n" if $self->verbose;

    @$self{ keys %args } = values %args;

    return;
}

sub _handle_callback_destroy {
    my ($self, $id, $event, $method, $pkg) = @_;

    warn "_handle_callback_destroy $id $event $method $pkg\n" if $self->verbose;

    delete $self->cb_registry->{$id};

    return;
}

sub _handle_connection_drain_writes {
    my $self = shift;

    $self->_drain_cv->send if $self->_has_drain_cv;

    return;
}

sub _on_error {
    my $self = shift;

    croak @_;
}

sub _on_destroy {
    my $self = shift;

    warn "_on_destroy\n" if $self->verbose;

    # TODO implement reconnect
    return;
}

sub DEMOLISH {
    my ($self, $in_gd) = @_;
    return if $in_gd;
    return unless $self->has_rpc;

    $self->rpc->(DEMOLISH => 0, my $cv = AE::cv);

    $cv->recv;

    $self->clear_rpc;

    return;
}

=head1 AUTHOR

William Cox <mydimension@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014, the above named author(s).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
