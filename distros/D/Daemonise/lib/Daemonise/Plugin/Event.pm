package Daemonise::Plugin::Event;

use 5.010;
use Mouse::Role;
use experimental 'smartmatch';
use Scalar::Util qw(looks_like_number);

# ABSTRACT: Daemonise Event plugin

use Carp;

BEGIN {
    with("Daemonise::Plugin::CouchDB");
    with("Daemonise::Plugin::RabbitMQ");
}


has 'event_db' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'events' },
);


has 'event_queue' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'event' },
);


after 'configure' => sub {
    my ($self, $reconfig) = @_;

    $self->log("configuring Events plugin") if $self->debug;

    if (ref($self->config->{event}) eq 'HASH') {
        foreach my $conf_key ('db', 'queue') {
            my $attr = "event_" . $conf_key;
            $self->$attr($self->config->{event}->{$conf_key})
                if defined $self->config->{event}->{$conf_key};
        }
    }

    $self->couchdb->db($self->event_db);

    return;
};


sub create_event {
    my ($self, $type, $offset, $data) = @_;

    unless (ref \$type eq 'SCALAR') {
        $self->log("event type must be a string!");
        return;
    }

    unless (ref \$offset eq 'SCALAR' and looks_like_number($offset)) {
        $self->log("offset must be a number!");
        return;
    }

    # data is optional but has to be a hash ref if exists
    if ($data) {
        unless (ref $data eq 'HASH') {
            $self->log("data must be a hash ref!");
            return;
        }
    }

    # base event keys/values
    my $now   = time;
    my $event = {
        type      => 'event',
        timestamp => $now,
    };

    # add mapped stuff
    given ($type) {
        when ('restart_billing') {
            unless (exists $data->{key}
                and ref \$data->{key} eq 'SCALAR'
                and $data->{key})
            {
                $self->log('data->key missing or empty');
                return;
            }

            $event = {
                %$event,
                backend => 'internal',
                object  => 'billing',
                action  => 'restart',
                status  => 'none',
                job_id  => $data->{key},
            };
        }
        when ('start_billing') {
            unless (exists $data->{key}
                and ref \$data->{key} eq 'SCALAR'
                and $data->{key})
            {
                $self->log('data->key missing or empty');
                return;
            }

            $event = {
                %$event,
                backend => 'internal',
                object  => 'billing',
                action  => 'start',
                status  => 'none',
                job_id  => $data->{key},
            };
        }
        when ('continue') {
            unless (exists $data->{key}
                and ref \$data->{key} eq 'SCALAR'
                and $data->{key})
            {
                $self->log('data->key missing or empty');
                return;
            }

            $event = {
                %$event,
                backend => 'internal',
                object  => 'none',
                action  => 'continue',
                status  => 'none',
                job_id  => $data->{key},
            };
        }
        when ('restart') {
            unless (exists $data->{key}
                and ref \$data->{key} eq 'SCALAR'
                and $data->{key})
            {
                $self->log('data->key missing or empty');
                return;
            }

            $event = {
                %$event,
                backend => 'internal',
                object  => 'none',
                action  => 'restart',
                status  => 'none',
                job_id  => $data->{key},
            };
        }
        when ('backend_call') {
            unless (exists $data->{queue}
                and exists $data->{command}
                and exists $data->{options})
            {
                $self->log(
                    '"queue", "command" and "options" keys must be present');
                return;
            }

            # include all keys from $data hash first here to have "command",
            # "queue" and "options" available later
            $event = {
                %$data,
                %$event,
                backend => 'internal',
                object  => 'none',
                action  => 'call',
                status  => 'none',
            };
        }
        when (/^[a-z0-9]+_[a-z0-9]+_[a-z0-9]+_[a-z0-9]+$/) {
            my ($backend, $object, $action, $status) = split(/_/, $type);
            $event = {
                %$data,
                %$event,
                backend => $backend,
                object  => $object,
                action  => $action,
                status  => $status,
            };
        }
        default {
            $self->log("unsupported event type: $type");
            return;
        }
    }

    if ($data) {
        $event->{parsed} = $data->{parsed};
        $event->{raw}    = $data->{raw};
    }

    # offset is number of hours or unix timestamp
    if ($offset) {
        $event->{when} =
            length($offset) >= 10 ? int $offset : $now + ($offset * 60 * 60);

        my $old_db = $self->couchdb->db;
        $self->couchdb->db($self->event_db);
        my ($id, $rev) = $self->couchdb->put_doc({ doc => $event });
        $self->couchdb->db($old_db);

        if ($self->couchdb->has_error) {
            $self->log("failed creating $type event: " . $self->couchdb->error);
            return;
        }

        # graph new event
        if ($self->can('graph')) {
            my $service = join('.',
                $event->{backend}, $event->{object},
                $event->{action},  $event->{status});
            $self->graph("event.$service", 'new', 1);
        }

        return $id;
    }
    else {
        my $frame = {
            data => {
                command => "event_add",
                options => $event,
            },
        };
        my $res = $self->queue($self->event_queue, $frame);
        if ($res->{error}) {
            $self->log(
                "failed to create $type event via queue: " . $res->{error});
            return;
        }

        return $res->{response}->{event_id};
    }
}


sub stop_event {
    my ($self, $id, $reason) = @_;

    return unless $id;

    my $old_db = $self->couchdb->db;
    $self->couchdb->db($self->event_db);
    my $event = $self->couchdb->get_doc({ id => $id });

    if ($event) {
        unless (exists $event->{processed} and $event->{processed}) {
            $event->{processed} = time;
            $event->{error} = $reason || ('stopped by ' . $self->name);

            $self->couchdb->put_doc({ doc => $event });
            $self->couchdb->db($old_db);

            $self->log("stopped event $id");

            # graph stopped event
            if ($self->can('graph')) {
                my $service = join('.',
                    $event->{backend}, $event->{object},
                    $event->{action},  $event->{status});
                $self->graph("event.$service", 'stopped', 1);
            }
        }

        return 1;
    }

    $self->couchdb->db($old_db);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Daemonise::Plugin::Event - Daemonise Event plugin

=head1 VERSION

version 2.13

=head1 SYNOPSIS

    use Daemonise;

    my $d = Daemonise->new();
    $d->debug(1);
    $d->foreground(1) if $d->debug;
    $d->config_file('/path/to/some.conf');

    $d->load_plugin('Event');

    $d->configure;

    # this will create an event, store it in the event_db and trigger it if
    # necessary. requires a daemon to be running that can process such events.
    my $when = 24 || 1360934857 || undef;
    my $options = {
        parsed => 'some parsed response',
        raw    => 'some%20raw%20response',
    };
    my $event_id = $d->create_event('pre_defined_type', "job_id", $when, $options);

    # stop an event
    $d->stop_event($event_id);

=head1 ATTRIBUTES

=head2 event_db

=head2 event_queue

=head1 SUBROUTINES/METHODS provided

=head2 configure

=head2 create_event

=head2 stop_event

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
