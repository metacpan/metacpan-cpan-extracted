#-------------------------------------------------------------------------------
# Tracks the length of time it takes to process requests for a node. Used by
# Argon::Cluster to monitor Node responsiveness.
#-------------------------------------------------------------------------------
package Argon::Tracker;

use strict;
use warnings;
use Carp;

use Moo;
use MooX::HandlesVia;
use Types::Standard qw(-types);
use Time::HiRes qw/time/;

#-------------------------------------------------------------------------------
# The length of tracking history to keep.
#-------------------------------------------------------------------------------
has tracking => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

#-------------------------------------------------------------------------------
# The number of workers a node has.
#-------------------------------------------------------------------------------
has workers => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

#-------------------------------------------------------------------------------
# The total number of requests this node has served.
#-------------------------------------------------------------------------------
has requests => (
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    default  => 0,
);

sub inc_requests {
    my ($self, $amount) = @_;
    $amount ||= 0;
    $self->{requests} += $amount;
}

#-------------------------------------------------------------------------------
# Stores the last <tracking> request timings.
#-------------------------------------------------------------------------------
has history => (
    is          => 'ro',
    isa         => ArrayRef[Num],
    init_arg    => undef,
    default     => sub {[]},
    handles_via => 'Array',
    handles     => {
        add_history    => 'push',
        del_history    => 'shift',
        len_history    => 'count',
        reduce_history => 'reduce',
    }
);

#-------------------------------------------------------------------------------
# Hash of pending requests (msgid => tracking start time).
#-------------------------------------------------------------------------------
has pending => (
    is          => 'ro',
    isa         => Map[Str,Num],
    init_arg    => undef,
    default     => sub {{}},
    handles_via => 'Hash',
    handles     => {
        set_pending => 'set',
        get_pending => 'get',
        del_pending => 'delete',
        num_pending => 'count',
        all_pending => 'keys',
        is_pending  => 'exists',
    }
);

#-------------------------------------------------------------------------------
# Avg processing time, calculated after each request completes.
#-------------------------------------------------------------------------------
has avg_proc_time => (
    is       => 'rw',
    isa      => Num,
    init_arg => undef,
    default  => 0,
);

#-------------------------------------------------------------------------------
# Begins tracking a request.
#-------------------------------------------------------------------------------
sub start_request {
    my ($self, $msg_id) = @_;
    $self->set_pending($msg_id, time);
    $self->inc_requests;
}

#-------------------------------------------------------------------------------
# Completes tracking for a request and updates tracking stats.
#-------------------------------------------------------------------------------
sub end_request {
    my ($self, $msg_id) = @_;
    my $taken = time - $self->get_pending($msg_id);

    $self->del_pending($msg_id);
    $self->add_history($taken);

    if ($self->len_history > $self->tracking) {
        my $to_delete = $self->len_history - $self->tracking;
        $self->del_history foreach 1 .. $to_delete;
    }

    my $sum  = $self->reduce_history(sub { $_[0] + $_[1] });
    $self->avg_proc_time($sum / $self->len_history);
}

#-------------------------------------------------------------------------------
# Returns the current capacity (workers - pending requests).
#-------------------------------------------------------------------------------
sub capacity {
    my $self = shift;
    return $self->workers - $self->num_pending;
}

#-------------------------------------------------------------------------------
# Returns the estimated time it would take to process a task, based on the
# number of pending tasks for this node and the average processing time.
#-------------------------------------------------------------------------------
sub est_proc_time {
    my $self = shift;
    return $self->avg_proc_time * ($self->num_pending + 1);
}

#-------------------------------------------------------------------------------
# Calculates the age of a tracked job.
#-------------------------------------------------------------------------------
sub age {
    my ($self, $msg_id) = @_;
    if ($self->is_pending($msg_id)) {
        return time - $self->get_pending($msg_id);
    } else {
        return;
    }
}

1;
