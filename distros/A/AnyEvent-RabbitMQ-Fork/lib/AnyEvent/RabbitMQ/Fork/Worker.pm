package AnyEvent::RabbitMQ::Fork::Worker;
$AnyEvent::RabbitMQ::Fork::Worker::VERSION = '0.6';
=head1 NAME

AnyEvent::RabbitMQ::Fork::Worker - Fork side magic

=head1 DESCRIPTION

No user serviceable parts inside. Venture at your own risk.

=cut

use Moo;
use Types::Standard qw(InstanceOf Bool);
use Guard;
use Scalar::Util qw(weaken blessed);

use namespace::clean;

use AnyEvent::RabbitMQ 1.18;

has verbose => (is => 'rw', isa => Bool, default => 0);

has connection => (
    is      => 'lazy',
    isa     => InstanceOf['AnyEvent::RabbitMQ'],
    clearer => 1,
    handles => ['channels'],
);

sub _build_connection {
    my $self = shift;

    my $conn = AnyEvent::RabbitMQ->new(verbose => $self->verbose);

    _cb_hooks($conn);

    return $conn;
}

### RPC Interface ###

my $instance;

sub init {
    my $class = shift;
    $instance = $class->new(@_);
    return;
}

sub run {
    my ($done, $method, $ch_id, @args, %args) = @_;

    weaken(my $self = $instance);

    unless (@args % 2) {
        %args = @args;
        @args = ();
        foreach my $event (grep { /^on_/ } keys %args) {
            # callback signature provided by parent process
            my $sig = delete $args{$event};

            # our callback to be used by AE::RMQ
            $args{$event} = $self->_generate_callback($method, $event, $sig);
        }
    }

    my @error;
    if (defined $ch_id and my $ch = $self->channels->{ $ch_id }) {
        $ch->$method(@args ? @args : %args);
    } elsif (defined $ch_id and $ch_id == 0) {
        if ($method eq 'DEMOLISH') {
            $self->clear_connection;
        } else {
            $self->connection->$method(@args ? @args : %args);
        }
    } else {
        $ch_id ||= '<undef>';
        push @error, "Unknown channel: '$ch_id'";
    }

    return $done->(@error);
}

my %cb_hooks = (
    channel => {
        _state      => 'is_open',
        _is_active  => 'is_active',
        _is_confirm => 'is_confirm',
    },
    connection => {
        _state             => 'is_open',
        _login_user        => 'login_user',
        _server_properties => 'server_properties',
    }
);
sub _cb_hooks {
    weaken(my $obj = shift);

    my ($type, $hooks)
      = $obj->isa('AnyEvent::RabbitMQ')
      ? ('connection', $cb_hooks{connection})
      : ($obj->id, $cb_hooks{channel});

    foreach my $prop (keys %$hooks) {
        my $method = $hooks->{$prop};
        ## no critic (Miscellanea::ProhibitTies)
        tie $obj->{$prop}, 'AnyEvent::RabbitMQ::Fork::Worker::TieScalar',
          $obj->{$prop}, sub {
            AnyEvent::Fork::RPC::event(
                i => { $type => { $method => $obj->$method } });
          };
    }

    return;
}

sub _generate_callback {
    my ($self, $method, $event, $sig) = @_;

    my $is_conn = $sig->[-1] eq 'AnyEvent::RabbitMQ::Fork';

    my $should_clear_connection
      = ($is_conn and ($method eq 'close' or ($method eq 'connect' and $event eq 'on_close')));

    my $open_channel_success = ($method eq 'open_channel' and $event eq 'on_success');

    my $guard = guard {
        # inform parent process that this callback is no longer needed
        AnyEvent::Fork::RPC::event(cbd => @$sig);
    };

    # our callback to be used by AE::RMQ
    weaken(my $wself = $self);
    return sub {
        $guard if 0;    # keepalive

        $wself->clear_connection if $should_clear_connection;

        my $blessed = blessed($_[0]) || 'UNIVERSAL';
        if ($blessed->isa('AnyEvent::RabbitMQ') or $blessed->isa('AnyEvent::RabbitMQ::Channel')) {
            # we put our sentry value in place later
            my $obj = shift;
            # this is our signal back to the parent as to what kind of object it was
            unshift @_, \[$blessed, ($obj->isa('AnyEvent::RabbitMQ::Channel') ? $obj->id : ())];

            if ($open_channel_success) {
                my $id = $obj->id;
                $obj->{"_$wself\_guard"} ||= guard {
                    # channel was GC'd by AE::RMQ
                    AnyEvent::Fork::RPC::event(chd => $id);
                };

                # needs to be done after parent registers channel
                AE::postpone { _cb_hooks($obj) };
            }

            if ($obj->isa('AnyEvent::RabbitMQ')) {
                # replace with our own handling
                $obj->{_handle}->on_drain(sub { AnyEvent::Fork::RPC::event('cdw') });
            }
        }

            # these values don't pass muster with Storable
        delete local @{ $_[0] }{ 'fh', 'on_error', 'on_drain' }
            #if $blessed->isa('AnyEvent::Handle');
            if $method eq 'connect' and $event eq 'on_failure' and $blessed->isa('AnyEvent::Handle');

        # tell the parent to run the users callback known by $sig
        AnyEvent::Fork::RPC::event(cb => $sig, @_);
    };
}

=head1 AUTHOR

William Cox <mydimension@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014, the above named author(s).

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

package    # hide from PAUSE
  AnyEvent::RabbitMQ::Fork::Worker::TieScalar;

use strict;
use warnings;

sub TIESCALAR { $_[2]->(); return bless [$_[1], $_[2]] => $_[0] }
sub FETCH { return $_[0][0] }
sub STORE { $_[0][1]->(); return $_[0][0] = $_[1] }
sub DESTROY { return @{ $_[0] } = () }

1;
