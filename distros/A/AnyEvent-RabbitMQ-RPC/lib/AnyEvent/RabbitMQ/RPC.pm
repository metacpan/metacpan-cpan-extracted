package AnyEvent::RabbitMQ::RPC;

use strict;
use warnings;

use AnyEvent::RabbitMQ;
use Try::Tiny;

our $VERSION = '0.5';

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless {}, $class;

    my $cv = AE::cv;
    my $success = $args{on_success} || $cv;
    my $failure = $args{on_failure} || sub {
        warn "@_";
        $cv->(undef);
    };

    $self->{connection} = $args{connection};
    my $channel = sub {
        $self->connection->open_channel(
            on_success => sub {
                $self->{channel} = shift;
                $self->{channel}->qos;
                $success->($self);
            },
            on_failure => sub {
                $failure->("Channel failed: @_");
            }
        );
    };
    if ($self->connection) {
        $channel->();
    } else {
        AnyEvent::RabbitMQ->load_xml_spec;
        $self->{connection} = AnyEvent::RabbitMQ->new(timeout => 1, verbose => 0);
        $self->connection->connect(
            %args,
            on_success => $channel,
            on_failure => sub {
                $failure->("Connect failed: @_");
            }
        );
    }

    $args{serialize} ||= '';
    if ($args{serialize} eq "YAML") {
        require YAML::Any;
        $self->{serialize}   = \&YAML::Any::Dump;
        $self->{unserialize} = \&YAML::Any::Load;
    } elsif ($args{serialize} eq "JSON") {
        require JSON::Any;
        JSON::Any->import;
        my $json = JSON::Any->new;
        $self->{serialize}   = sub { $json->objToJson( [@_] ) };
        $self->{unserialize} = sub { (@{ $json->jsonToObj(@_) })[0] };
    } elsif ($args{serialize} eq "Storable") {
        require Storable;
        $self->{serialize}   = sub { Storable::nfreeze( [@_] )};
        $self->{unserialize} = sub { (@{ Storable::thaw(@_) })[0] };
    }

    # If they have a callback waiting for them, bail now
    return if $args{on_success};

    # Otherwise, block on having set up the channel
    return $cv->recv;
}

sub connection {
    my $self = shift;
    return $self->{connection};
}

sub channel {
    my $self = shift;
    return $self->{channel};
}

sub rpc_queue {
    my $self = shift;
    my %args = @_;

    # These queues are durable -- as such, we should only need to check
    # that they are there once per process.
    return $args{on_success}->()
        if $self->{queues}{$args{queue}};

    $self->channel->declare_queue(
        no_ack     => 0,
        durable    => 1,
        exclusive  => 0,
        %args,
        on_success => sub {
            $self->{queues}{$args{queue}}++;
            $args{on_success}->();
        },
    );
}

sub reply_queue {
    my $self = shift;
    my %args = @_;

    $self->channel->declare_queue(
        no_ack     => 1,
        durable    => 0,
        exclusive  => 1,
        on_success => sub {
            $args{on_success}->(shift->method_frame->queue);
        },
        on_failure => $args{on_failure},
    );
}

sub register {
    my $self = shift;
    my %args = (
        name => undef,
        run  => sub {},
        on_failure => sub { warn "Failure: @_" },
        @_
    );

    # Ensure we have the queue
    $self->rpc_queue(
        queue      => $args{name},
        on_success => sub {
            # And set up a listen on it
            $self->channel->consume(
                queue      => $args{name},
                no_ack     => 0,
                on_consume => sub {
                    my $frame = shift;
                    my $failed;
                    my $args = $frame->{body}->payload;
                    if ($self->{unserialize}) {
                        try {
                            $args = $self->{unserialize}->($args);
                        } catch {
                            $failed = 1;
                            $args{on_failure}->("Unserialization failed: $_");
                        };
                        return if $failed;
                    }

                    # Call the sub
                    my $return;
                    try {
                        $return = $args{run}->( $args );
                    } catch {
                        $failed = 1;
                        $args{on_failure}->("Call died: $_");
                    };
                    return if $failed;

                    # Send the response, if they asked for it
                    if (my $reply_to = $frame->{header}->reply_to) {
                        if ($self->{serialize}) {
                            try {
                                $return = $self->{serialize}->($return);
                            } catch {
                                $failed = 1;
                                $args{on_failure}->("Serialization failed: $_");
                            };
                            return if $failed;
                        }

                        $return = "0E0" if not $return;
                        $self->channel->publish(
                            exchange => '',
                            routing_key => $reply_to,
                            body => $return,
                        );
                    }

                    # And finally mark the task as complete
                    $self->channel->ack;
                },
                on_failure => $args{on_failure},
            );
        },
        on_failure => $args{on_failure},
    );
}

sub call {
    my $self = shift;

    my %args = (
        name => undef,
        args => undef,
        on_sent => undef,
        on_failure => sub { warn "RPC Failure: @_" },
        @_
    );

    my $finished;
    if (defined wantarray and not $args{on_reply}) {
        # We we're called in a not-void context, and without a reply
        # callback, assume this is a syncronous call, and set up
        # $finished to block on the reply
        $args{on_reply} = $finished = AE::cv;
        my $fail = $args{on_failure};
        $args{on_failure} = sub {
            $fail->(@_) if $fail;
            $finished->send(undef);
        }
    }

    my $sent_failure = $args{on_sent} ? sub {
        $args{on_sent}->(0);
        $args{on_failure}->(@_);
    } : $args{on_failure};

    my $send; $send = sub {
        my $REPLIES = shift;
        my $args = $args{args};
        if ($self->{serialize}) {
            my $failed;
            try {
                $args = $self->{serialize}->($args);
            } catch {
                $failed = 1;
                $args{on_failure}->("Serialization failed: $_");
            };
            return if $failed;
        }
        $args = "0E0" if not $args;
        $self->channel->publish(
            exchange    => '',
            routing_key => $args{name},
            body        => $args,
            header => {
                ($REPLIES ? (reply_to => $REPLIES) : ()),
                delivery_mode => 2, # Persistent storage
            },
        );
        $args{on_sent}->(1) if $args{on_sent};
    };

    unless ($args{on_reply}) {
        # Fire and forget
        $self->rpc_queue(
            queue      => $args{name},
            on_success => sub { $send->(undef) },
            on_failure => $sent_failure,
        );
        return;
    }

    # We need to set up an ephemeral reply queue
    $self->rpc_queue(
        queue      => $args{name},
        on_success => sub {
            $self->reply_queue(
                on_success => sub {
                    my $REPLIES = shift;
                    $self->channel->consume(
                        queue => $REPLIES,
                        no_ack => 1,
                        on_consume => sub {
                            my $frame = shift;
                            # We got a reply, tear down our reply queue
                            $self->channel->delete_queue(
                                queue => $REPLIES,
                            );
                            my $return = $frame->{body}->payload;
                            if ($self->{unserialize}) {
                                my $failed;
                                try {
                                    $return = $self->{unserialize}->($return);
                                } catch {
                                    $args{on_failure}->("Unserialization failed: $_");
                                    $failed = 1;
                                };
                                return if $failed;
                            }
                            $args{on_reply}->($return);
                        },
                        on_success => sub { $send->($REPLIES) },
                        on_failure => $sent_failure,
                    );
                },
                on_failure => $sent_failure,
            );
        },
        on_failure => $sent_failure,
    );

    return $finished->recv if $finished;
    return 1;
}

1;

__END__

=head1 NAME

AnyEvent::RabbitMQ::RPC - RPC queues via RabbitMQ

=head1 SYNOPSIS

    use AnyEvent::RabbitMQ::RPC;

    my $rpc = AnyEvent::RabbitMQ::RPC->new(
        host   => 'localhost',
        port   => 5672,
        user   => 'guest',
        pass   => 'guest',
        vhost  => '/',
        serialize => 'Storable',
    );

    print $rpc->call(
        name => 'MethodName',
        args => { some => "data" },
    );

=head1 DESCRIPTION

C<AnyEvent::RabbitMQ::RPC> provides an AnyEvent-based reliable job queue
atop the RabbitMQ event server.  This can be used as a replacement for
similar reliable job queue/RPC client-worker models, such as
L<TheSchwartz>.

RPC classes can L<register> calls that they can handle, and/or use
L<call> to request another client perform work.

=head1 METHODS

=head2 new

Create a new RPC object.  Either an existing L<AnyEvent::RabbitMQ>
object can be passed using the C<connection> argument, or the all of the
provided parameters will be passed through to
L<AnyEvent::RabbitMQ/connect> on a new object.  In the latter case,
common parameters include C<host>, C<port>, C<user>, C<pass>, and
C<vhost>.

If you wish to pass complex data structures back and forth to remote
workers, a value must be passed for C<serialize>.  Both worker and
client must be configured to use the same serialization method.  The
available options are:

=over

=item YAML

Use L<YAML::Any/Dump> and L<YAML::Any/Load> to serialize and deserialize
data.

=item JSON

Use L<JSON::Any/objToJson> and L<JSON::Any/jsonToObj> to serialize and
deserialize.

=item Storable

Use L<Storable/nfreeze> and L<Storable/thaw> to serialize and
deserialize.

=back

Two callback points, C<on_success> and C<on_failure>, are provided.
C<on_success> will be passed the initialized L<AnyEvent::RabbitMQ::RPC>
object; C<on_failure> will be passed the reason for the failure.  If no
C<on_success> is provided, this call will block using an
L<AnyEvent::CondVar> until the connection is established.


=head2 register name => C<STRING>, run => C<SUBREF>

Establishes that the current process knows how to run the job named
C<STRING>, whose definition is provided by the surboutine C<SUBREF>.
The subroutine will be called whenever a job is removed from the queue;
it will be called with the argument passed to C</call>, which may be
more than a string if C<serialize> was set during L</new>.

Due to a limitation of C<AnyEvent::RabbitMQ>, false values returned by
the subroutine are transformed into the true-valued string C<0E0>.
Subroutines which fail to execute to completion (via C<die> or other
runtime execution failure) will re-insert the job into the queue for the
next worker to process.

Returning non-string values requires that both worker and client have
been created with the same (non-empty) value of C<serialize> passed to
L</new>.

A callback C<on_failure> may optionally be passed, which will be called
with an error message if suitable channels cannoot be configured on the
RabbitMQ server.

=head2 call name => C<STRING>, args => C<VALUE>

Submits a job to the job queue.  The C<VALUE> provided must be a string,
unless C<serialize> was passed to L</new>.

Three callbacks exist:

=over

=item on_reply

Called when the job has been completed successfully, and will be passed
the return value of the job.  Returning non-string values requires that
both worker and client have been created with the same (non-empty) value
of C<serialize> passed to L</new>.

=item on_sent

Called once the job has been submitted, with a true value if the job was
submitted successfully.  A false value will be passed if the requisite
channels could not be configured, and the job was not submitted
sucessfully.

=item on_failure

Called if there was an error submitting the job, and is passed the
reason for the failure.  If C<on_sent> was also provided, this is
I<also> called after C<on_sent> is called with a false value.

=back


If no value for C<on_reply> is provided, and the C<call> function is not
in void context, a C<AnyEvent::CondVar> is used to automatically block
until a reply is received from a worker; the return value of the reply
is then returned from L</call>.


=head2 connection

Returns the L<AnyEvent::RabbitMQ> connection used by this object.

=head2 channel

Returns the L<AnyEvent::RabbitMQ::Channel> used by this object.

=head2 rpc_queue queue => C<NAME>, on_success => C<CALLBACK>

Creates the queue with the given name, used to schedule jobs.  These
queues are durable, and thus persist across program invocations and
RabbitMQ restarts.

The C<on_success> callback is called once the queue is known to exist.
The C<on_failure> may alternately be called with a reason if the queue
creation fails.

=head2 reply_queue on_success => C<CALLBACK>

Creates a temporary queue used to reply to job requests.  These queues
are anonymous and ephemeral, and are torn down after each RPC call.

The C<on_success> callback is called with the name of the queue that has
been created.  The C<on_failure> may alternately be called with a reason
if the queue creation fails.


=head1 AUTHOR

Alex Vandiver C<< <alexmv@bestpractical.com> >>

=head1 BUGS

All bugs should be reported via
L<http://rt.cpan.org/Public/Dist/Display.html?Name=AnyEvent-RabbitMQ-RPC>
or L<bug-AnyEvent-RabbitMQ-RPC@rt.cpan.org>.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
