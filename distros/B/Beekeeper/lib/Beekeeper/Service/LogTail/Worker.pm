package Beekeeper::Service::LogTail::Worker;

use strict;
use warnings;

our $VERSION = '0.07';

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Beekeeper::Logger ':log_levels';
use Scalar::Util 'weaken';
use JSON::XS;

my @Log_buffer;


sub authorize_request {
    my ($self, $req) = @_;

    return unless $self->__has_authorization_token('BKPR_ADMIN');

    return BKPR_REQUEST_AUTHORIZED;
}

sub on_startup {
    my $self = shift;

    $self->{max_entries} = $self->{config}->{buffer_entries} || 100000;
    $self->{log_level}   = $self->{config}->{log_level}      || LOG_INFO;

    $self->_connect_to_all_brokers;

    $self->accept_remote_calls(
        '_bkpr.logtail.tail' => 'tail',
    );

    log_info "Ready";
}

sub _connect_to_all_brokers {
    my $self = shift;
    weaken($self);

    my $own_bus = $self->{_BUS};
    my $group_config = Beekeeper::Config->get_bus_group_config( bus_id => $own_bus->bus_id );

    $self->{_BUS_GROUP} = [];

    foreach my $config (@$group_config) {

        my $bus_id = $config->{'bus_id'};

        if ($bus_id eq $own_bus->bus_id) {
            # Already connected to our own bus
            $self->_collect_log($own_bus);
            next;
        }

        my $bus; $bus = Beekeeper::MQTT->new( 
            %$config,
            bus_id     => $bus_id,
            timeout    => 300,
            on_connect => sub {
                # Setup subscriptions
                $self->_collect_log($bus);
            },
            on_error => sub {
                # Reconnect
                my $errmsg = $_[0] || ""; $errmsg =~ s/\s+/ /sg;
                log_error "Connection to $bus_id failed: $errmsg";
                my $delay = $self->{connect_err}->{$bus_id}++;
                $self->{reconnect_tmr}->{$bus_id} = AnyEvent->timer(
                    after => ($delay < 10 ? $delay * 3 : 30),
                    cb    => sub { $bus->connect },
                );
            },
        );

        push @{$self->{_BUS_GROUP}}, $bus;

        $bus->connect;
    }
}

sub _collect_log {
    my ($self, $bus) = @_;

    # Default logger logs to topic log/$level/$service

    my $max_entries = $self->{max_entries};
    my $log_level   = $self->{log_level};
    my $worker      = $self->{_WORKER};

    foreach my $level (1..$log_level) {

        my $topic = "log/$level/#";
        my $req;

        $bus->subscribe(
            topic      => $topic,
            on_publish => sub {
              # my ($payload_ref, $mqtt_properties) = @_;

                $req = decode_json( ${$_[0]} );

                push @Log_buffer, $req->{params};

                shift @Log_buffer if (@Log_buffer > $max_entries);

                # Track number of collected log entries
                $worker->{notif_count}++;
            },
            on_suback => sub {
                my ($success, $prop) = @_;
                die "Could not subscribe to log topic '$topic'" unless $success;
            },
        );
    }
}

sub on_shutdown {
    my ($self, %args) = @_;

     foreach my $bus (@{$self->{_BUS_GROUP}}) {

        next unless ($bus->{is_connected});
        $bus->disconnect;
    }
}

sub tail {
    my ($self, $params) = @_;

    foreach ('count','level','after') {
        next unless defined $params->{$_};
        unless ($params->{$_} =~ m/^\d+(\.\d+)?$/) {
            die "Invalid parameter $_";
        }
    }

    foreach ('host','pool','service','message') {
        next unless defined $params->{$_};
        # Allow simple regexes
        unless ($params->{$_} =~ m/^[\w .*+?:,()\-\[\]\\]+$/) {
            die "Invalid parameter $_";
        }
    }

    my $count = $params->{count} || 10;
    my $after = $params->{after};
    my $level = $params->{level};

    # This will die when an invalid regex is provided, but that's fine
    my $host_re = defined $params->{host}    ? qr/$params->{host}/i    : undef;
    my $pool_re = defined $params->{pool}    ? qr/$params->{pool}/i    : undef;
    my $svc_re  = defined $params->{service} ? qr/$params->{service}/i : undef;
    my $msg_re  = defined $params->{message} ? qr/$params->{message}/i : undef;

    my ($entry, @filtered);

    for (my $i = @Log_buffer - 1; $i >= 0; $i--) {

        $entry = $Log_buffer[$i];

        next if (defined $level   && $entry->{level}    > $level   ) || 
                (defined $after   && $entry->{tstamp}  <= $after   ) ||
                (defined $host_re && $entry->{host}    !~ $host_re ) ||
                (defined $pool_re && $entry->{pool}    !~ $pool_re ) ||
                (defined $svc_re  && $entry->{service} !~ $svc_re  ) ||
                (defined $msg_re  && $entry->{message} !~ $msg_re  );

        unshift @filtered, $entry;

        last if (@filtered >= $count);
    }

    return \@filtered;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::Service::LogTail::Worker - Buffer log entries

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

=head1 DESCRIPTION

By default all workers use a L<Beekeeper::Logger> logger which logs errors and
warnings both to files and to a topic C<log/{level}/{service}> on the message bus.

This worker keeps an in-memory buffer of every log entry sent to these topics in
every broker of a logical message bus. Then this buffer can be queried using the 
C<tail> method provided by L<Beekeeper::Service::LogTail> or using the command line
client L<bkpr-log>.

Buffered entries consume 1.5 kiB for messages of 100 bytes, increasing to 2 KiB
for messages of 500 bytes. Holding the last million log entries in memory will 
consume around 2 GiB.

LogTail workers are CPU bound and can collect up to 20000 log entries per second.
Applications exceeding that traffic will need another strategy to consolidate log
entries from brokers.

LogTail workers are not created automatically. In order to add a LogTail worker to a
pool it must be declared into config file C<pool.config.json>:

  [
      {
          "pool_id" : "myapp",
          "bus_id"  : "backend",
          "workers" : {
              "Beekeeper::Service::LogTail::Worker" : { "buffer_entries": 100000 },
               ...
          },
      },
  ]

=head1 METHODS

See L<Beekeeper::Service::LogTail> for a description of the methods exposed by 
this worker class.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
