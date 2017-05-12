package Argon::Client;

use Moo;
use MooX::HandlesVia;
use Types::Standard qw(-types);
use Carp;
use AnyEvent;
use AnyEvent::Socket;
use Coro;
use Coro::AnyEvent;
use Coro::Handle;
use List::Util qw(max);
use Guard qw(scope_guard);
use Argon qw(:commands :priorities :logging);
use Argon::Message;
use Argon::Stream;

has host => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has port => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has stream => (
    is       => 'lazy',
    isa      => InstanceOf['Argon::Stream'],
    init_arg => undef,
    handles  => {
        addr => 'addr',
    },
);

sub _build_stream {
    my $self = shift;
    return Argon::Stream->connect($self->host, $self->port);
}

after _build_stream => sub {
    my $self = shift;
    $self->read_loop;
};

has pending => (
    is          => 'ro',
    isa         => HashRef,
    init_arg    => undef,
    default     => sub {{}},
    handles_via => 'Hash',
    handles  => {
        set_pending => 'set',
        get_pending => 'get',
        del_pending => 'delete',
        has_pending => 'exists',
        all_pending => 'keys',
    }
);

has inbox => (
    is       => 'ro',
    isa      => InstanceOf['Coro::Channel'],
    init_arg => undef,
    default  => sub { Coro::Channel->new() },
);

has read_loop => (
    is       => 'lazy',
    isa      => InstanceOf['Coro'],
    init_arg => undef,
);

sub _build_read_loop {
    my $self = shift;

    return async {
        scope_guard { $self->shutdown };

        while (1) {
            my $msg = $self->stream->read or last;

            if ($self->has_pending($msg->id)) {
                $self->get_pending($msg->id)->put($msg);
            } else {
                $self->inbox->put($msg);
            }
        }
    };
}

sub shutdown {
    my $self = shift;

    $self->stream->close;
    $self->inbox->shutdown;

    my $error = 'Lost connection to worker while processing request';
    foreach my $msgid ($self->all_pending) {
        my $msg = Argon::Message->new(cmd => $CMD_ERROR, id => $msgid, payload => $error);
        $self->get_pending($msgid)->put($msg);
    }
}

sub connect {
    my $self = shift;
    $self->stream;
}

sub _wait_msgid {
    my ($self, $msgid) = @_;
    my $reply = $self->get_pending($msgid)->get();
    $self->del_pending($msgid);
    return $reply;
}

sub send {
    my ($self, $msg) = @_;
    $self->set_pending($msg->id, Coro::Channel->new());
    $self->stream->write($msg);
    return $self->_wait_msgid($msg->id);
}

sub queue {
    my ($self, $f, $args, $pri, $max_tries) = @_;
    defined $f && (!ref $f || ref $f eq 'CODE') || croak 'expected CODE ref or class name';

    $args ||= [];
    ref $args eq 'ARRAY' || croak 'expected ARRAY ref of args';

    $pri       ||= $PRI_NORMAL;
    $max_tries ||= 10;

    my $msg = Argon::Message->new(
        cmd     => $CMD_QUEUE,
        pri     => $pri,
        payload => [$f, $args],
    );

    my $next_try = 0.1;
    my $reply;

    for (my $tries = 1; $tries <= $max_tries; ++$tries) {
        $reply = $self->send($msg);

        if ($reply->cmd == $CMD_REJECTED) {
            $next_try = log(max($tries, 1.1)) / log(10);
            Coro::AnyEvent::sleep $next_try;
            next;
        }
        elsif ($reply->cmd == $CMD_ACK) {
            return $reply->id;
        }
        else {
            croak sprintf('Unknown response type: %s', $reply->cmd);
        }
    }

    croak sprintf('Request failed after %d attempts. %s', $max_tries, $reply->payload);
}

sub collect {
    my ($self, $id) = @_;
    my $msg   = Argon::Message->new(id => $id, cmd => $CMD_COLLECT, payload => $id);
    my $reply = $self->send($msg);

    if ($reply->cmd == $CMD_COMPLETE) {
        return $reply->payload;
    } else {
        croak $reply->payload;
    }
}

sub process {
    my ($self, $f, $args, $pri, $max_tries) = @_;
    my $id     = $self->queue($f, $args, $pri, $max_tries);
    my $result = $self->collect($id);
    return $result;
}

sub defer {
    my $self  = shift;
    my $msgid = $self->queue(@_);
    return sub { $self->collect($msgid) };
}

sub server_status {
    my $self  = shift;
    my $msg   = Argon::Message->new(cmd => $CMD_STATUS);
    my $reply = $self->send($msg);

    if ($reply->cmd == $CMD_COMPLETE) {
        return $reply->payload;
    } elsif ($reply->cmd == $CMD_ERROR) {
        croak $reply->payload;
    } else {
        DEBUG 'Invalid server response [%d]: %s', $reply->cmd, $reply->payload;
        croak 'Invalid server response';
    }
}

1;
__DATA__

=head1 NAME

Argon::Client

=head1 SYNOPSIS

    use Argon::Client;

    # Connect
    my $client = Argon::Client->new(host => '...', port => XXXX);

    # Send task and wait for result
    my $the_answer = $client->queue(sub {
        my ($x, $y) = @_;
        return $x * $y;
    }, [6, 7]);

    # Send task and get a deferred result that can be synchronized later
    my $deferred = $client->defer(sub {
        my ($x, $y) = @_;
        return $x * $y;
    }, [6, 7]);

    my $result = $deferred->();

    # Close the client connection
    $client->shutdown;

=head1 DESCRIPTION

Establishes a connection to an Argon network and provides methods for executing
tasks and collecting the results.

=head1 METHODS

=head2 new(host => $host, port => $port)

Creates a new C<Argon::Client>. The connection is made lazily when the first
call to L</queue> or L</connect> is performed. The connection can be forced by
calling L</connect>.

=head2 connect

Connects to the remote host.

=head2 server_status

Returns a hash of status information about the manager's load, capacity, and
workers.

=head2 queue($f, $args, $pri, $max_tries)

Queues a task with the L<Argon::Manager> and returns a message id which can
be used to collect the results at a later time. The results are stored for
at least C<$Argon::DEL_COMPLETE_AFTER> seconds.

Similarly, a class implementing 'new' and 'run' methods may be used in place
of a CODE ref:

    my $msgid = $client->queue('Task::Whatever', $args);
    # Executes Task::Whatever->new(@$args)->run();

This avoids import and closure issues that can occur when passing in a CODE
reference.

=over

=item $f <code ref|string>

Subroutine to execute or a task class implementing C<new(@$args)> and C<run>.

=item $args <array ref>

Arguments to pass to C<$f>.

=item $pri <int|undef - $Argon::PRI_(LOW|NORMAL|HIGH) constant>

Task priority. Affects how the task is queued with the Manager when load is
high enough that tasks are not immediately serviced. Defaults to
C<$Argon::PRI_NORMAL>.

=item $max_tries <int|undef>

When Manager's queue is full, new tasks are rejected until the queue is
reduced.  Tasks will be retried up to 10 times (by default) until they are
accepted by the manager. If the task has not been accepted after C<$max_tries>,
an error is thrown.

=back

=head2 collect($msgid)

Blocks the thread until the result identified by C<$msgid> is available and
returns the result. If processing the task resulted in an error, the error is
rethrown when C<collect> is called.

=head2 process($f, $args, $pri, $max_tries)

Equivalent to calling:

    my $msg = $client->queue($f, $args, $pri, $max_tries);
    my $result = $client->collect($msg);

=head2 defer($f, $args)

Similar to L</process>, but instead of waiting for the result, returns an
anonymous function that, when called, waits and returns the result. If an error
occurs when calling <$f>, it is re-thrown from the anonymous function.

C<defer> accepts a either a CODE ref or a task class.

=head2 shutdown

Disconnects from the Argon network.

=head1 A NOTE ABOUT SCOPE

L<Storable> is used to serialize code that is sent to the Argon network. This
means that the code sent I<will not have access to variables and modules outside
of itself> when executed. Therefore, the following I<will not work>:

    my $x = 0;
    $client->queue(sub { return $x + 1 }); # $x not found!

The right way is to pass it to the function as part of the task's arguments:

    my $x = 0;

    $client->queue(sub {
        my $x = shift;
        return $x + 1;
    }, [$x]);

Similarly, module imports are not available to the function:

    use Data::Dumper;

    my $data = [1,2,3];
    my $string = $client->queue(sub {
        my $data = shift;
        return Dumper($data); # Dumper not found
    }, [$data]);

The right way is to import the module inside the task:

    my $data = [1,2,3];
    my $string = $client->queue(sub {
        require Data::Dumper;
        my $data = shift;
        return Data::Dumper::Dumper($data);
    }, [$data]);

Note the use of C<require> instead of C<use>. This is because C<use> is
performed at compilation time, causing it to be triggered when the calling code
is compiled, rather than from within the worker process. C<require>, on the
other hand, is triggered at runtime and will behave as expected.

Using a task class avoids this issue entirely; the task is loaded within the
Argon worker process at run time, including any C<use> or C<require>
statements.

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>
