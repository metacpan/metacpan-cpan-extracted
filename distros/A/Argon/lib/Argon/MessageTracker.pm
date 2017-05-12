package Argon::MessageTracker;

use Moo;
use MooX::HandlesVia;
use Types::Standard qw(-types);
use Carp;
use Time::HiRes qw(time);
use Coro;
use Coro::AnyEvent;
use Coro::Channel;
use Argon;
use Argon::Message;

#-------------------------------------------------------------------------------
# As messages are added to the tracker, a Coro::Channel is created (and mapped
# to the message id). It is used to allow callers to block until the result is
# posted to the channel.
#-------------------------------------------------------------------------------
has tracked => (
    is          => 'ro',
    isa         => Map[Str, InstanceOf['Coro::Channel']],
    init_arg    => undef,
    default     => sub {{}},
    handles_via => 'Hash',
    handles     => {
        set_tracked => 'set',
        get_tracked => 'get',
        del_tracked => 'delete',
        is_tracked  => 'exists',
        all_tracked => 'keys',
        num_tracked => 'count',
    }
);

#-------------------------------------------------------------------------------
# Tracks the completion time stamp for messages.
#-------------------------------------------------------------------------------
has complete => (
    is          => 'ro',
    isa         => Map[Str, Num],
    init_arg    => undef,
    default     => sub {{}},
    handles_via => 'Hash',
    handles     => {
        set_complete => 'set',
        get_complete => 'get',
        del_complete => 'delete',
        is_complete  => 'exists',
        all_complete => 'keys',
        num_complete => 'count',
    }
);

#-------------------------------------------------------------------------------
# Uses the completion time stamp to delete any messages which were completed
# more than $Argon::DEL_COMPLETE_AFTER seconds ago and remain unclaimed.
#-------------------------------------------------------------------------------
has cleanup_thread => (
    is       => 'lazy',
    isa      => InstanceOf['Coro'],
    init_arg => undef,
);

sub _build_cleanup_thread {
    my $self = shift;
    return async {
        while (1) {
            Coro::AnyEvent::sleep 60;
            $self->delete_unclaimed;
        }
    };
}

#-------------------------------------------------------------------------------
# Starts tracking on a message.
#-------------------------------------------------------------------------------
sub track_message {
    my ($self, $msgid) = @_;
    croak 'message is already tracked' if $self->is_tracked($msgid);
    $self->set_tracked($msgid => Coro::Channel->new());
}

#-------------------------------------------------------------------------------
# Completes tracking on a message and posts results.
#-------------------------------------------------------------------------------
sub complete_message {
    my ($self, $msg) = @_;
    croak 'message is not tracked' unless $self->is_tracked($msg->id);
    $self->cleanup_thread; # make sure this is running
    $self->set_complete($msg->id => time);
    $self->get_tracked($msg->id)->put($msg);
}

#-------------------------------------------------------------------------------
# Waits until a tracked message's results are available and returns them, then
# cleans up after the message.
#-------------------------------------------------------------------------------
sub collect_message {
    my ($self, $msgid) = @_;
    croak 'message is not tracked' unless $self->is_tracked($msgid);
    my $msg = $self->get_tracked($msgid)->get();
    $self->cleanup_message($msgid);
    return $msg;
}

#-------------------------------------------------------------------------------
# Removes tracking information for a tracked message.
#-------------------------------------------------------------------------------
sub cleanup_message {
    my ($self, $msgid) = @_;
    $self->del_tracked($msgid);
    $self->del_complete($msgid);
}

#-------------------------------------------------------------------------------
# Deletes unclaimed messages which were completed more than
# $Argon::DEL_COMPLETE_AFTER seconds ago. Run in a loop stored in
# cleanup_thread.
#-------------------------------------------------------------------------------
sub delete_unclaimed {
    my $self = shift;
    my $now  = time;

    foreach my $msgid ($self->all_complete) {
        my $ts = $self->get_complete($msgid);

        if ($now - $ts >= $Argon::DEL_COMPLETE_AFTER) {
            $self->cleanup_message($msgid);
        }
    }
}

1;
