package Couchbase::Client::Async;
use strict;
use warnings;
our $VERSION = '1.0.2';
use Couchbase::Client;
use Couchbase::Client::IDXConst;
use Log::Fu;


sub new {
    my ($cls,$options) = @_;
    my @async_keys = qw(
        cb_update_event
        cb_error
        cb_waitdone
        cb_update_timer
        bless_events
    );
    my %async_opts;
    @async_opts{@async_keys} = delete @{$options}{@async_keys};

    my $arglist = Couchbase::Client::_MkCtorIDX($options);

    $arglist->[CTORIDX_CBEVMOD] = delete $async_opts{cb_update_event}
    and
    $arglist->[CTORIDX_CBERR] = delete $async_opts{cb_error}
    and
    $arglist->[CTORIDX_CBWAITDONE] = delete $async_opts{cb_waitdone}
    and
    $arglist->[CTORIDX_CBTIMERMOD] = delete $async_opts{cb_update_timer}

    or die "We require update_event, error, and wait_done callbacks";

    if($async_opts{bless_events}) {
        $arglist->[CTORIDX_BLESS_EVENT] = 1;
    }

    my $o = $cls->construct($arglist);
    return $o;
}

#Establish proxy methods:

foreach my $subname (qw(
    enable_compress
    compression_settings
    serialization_settings
    conversion_settings
    deconversion_settings
    compress_threshold
    timeout
)) {
    no strict 'refs';
    *{$subname} = sub {
        my ($self,@args) = @_;
        my $base = $self->_get_base_rv;

        @_ = ($base, @args);
        goto &{"Couchbase::Client::$subname"};
    };
}

1;

__END__

=head1 NAME

Couchbase::Client::Async - Asynchronous system for couchbase clients.

=head1 DESCRIPTION

This is a module intended for use by other higher level components which interact
directly with Perl event frameworks.

libcouchbase allows for pluggable event loops, which drive and tell it about
file descriptor events, timeouts, and other such nicetis.

The purpose of this module is to provide a unified library for perl, which will
be compatible with L<POE>,  L<AnyEvent>, L<IO::Async> and other event loops.

The module is divided into two components:

=head2 I/O Events

This part of the module provides an interface for event libraries to tell
libcouchbase about events, and conversely, have libcouchbase tell the event
library about new file descriptors and events.

=head2 Command Results and Events

This part of the module provides a framework in which event libraries can provide
interfaces to users, so that they can perform commands on a couchbase cluster, and
receive their results asynchronously.

=head1 EVENT MANAGEMENT

Event, Timer, and I/O management is the lower level of this module, and constitutes
the interface which event loop integrators would need to be most attune to.

At the most basic level, you are required to implement four callbacks. These
callbacks are indicated by values passed to their given hash keys in the object's
constructor.

=head3 C<cb_update_event>

    cb_update_event => sub {
        my ($evdata,$action,$flags) = @_;

        if(ref($evdata) ne "Couchbase::Client::Event") {
            bless $evdata, "Couchbase::Client::Event";
        }
        ...
    };

This callback is invoked to update and/or modify events. It receives three
arguments.

The first is C<$evdata> which is an array, which may be blessed into
L<Couchbase::Client::Async::Event>.

The C<$evdata> structure contains the state-'glue' for interaction with the
internal (C) event routines and their Perl dispatchers.

The following will mention some useful fields for the C<$evdata> structure. Note
this is not an exhaustive listing (see that class' documentation for that) but
a more practical guide as to what the fields are for, and how they may be used.

=over

=item C<fd>

This read-only field contains the numeric file descriptor on which the C library
will perform I/O functions. If your event loop supports watching file descriptor
numbers directly, you may simply watch this number; otherwise, look at the next
field

=item C<dupfh>

This mutatable field contains an optional dup'd Perl filehandle. Some Perl event
loops do not allow for watching a file descriptor directly and demand to be given
a 'PerlIO' filehandle (conforming to the L<IO::Handle> interface, or one of the
things returned by L<open>).

This filehandle should be a dup'd version of the C<fd> field, the reason being
that when the filehandle goes out of scope from perl, the underlying file
I<descriptor> will be C<close()>d. Since there is not necessarily a one-to-one
correlation between stream lifetimes as they exist in the Perl client, and their
lifetimes as they exist in libcouchbase, it is recommended that the file
descriptor be dup'd. In that way, close() on the dup'd file descriptor will not
affect the file descriptor in the C side.

The filehandle stored in the C<dupfh> field will remain active until the underlying
C<fd> is closed or changed.

The first time an event is created, the C<dupfh> field will be undef, and
the callback should check for this creation, and if true, create a new one,
using the following idiom:

    open my $dupfh, ">&", $evdata->fd;
    $evdata->dupfh($dupfh);

the C<dupfh> field will persist the next time the C<cb_update_event> callback
is invoked.

=item opaque

This contains opaque data to be passed to our L</HaveEvent> package method. You
must not modify this object in any way. Failure to comply will likely result in
a segfault.

=back

The third argument (we will get to the second argument later) is a bitfield of
flags, describing which events to watch for. Flags may be a bitwise-OR'd
combination of the following

=over

=item C<COUCHBASE_READ_EVENT>

Dispatch event when the stream will not block on read()

=item C<COUCHBASE_WRITE_EVENT>

Dispatch event when the stream will not block on write()

=back

Consequently, it is the responsibility of this callback to ensure that B<only>
the I/O events specified in C<$flags> are active, and that all others remain
inactive (spuriously delivering write events is a very bad idea).

To make life easier, the C<$evdata> structure has a C<old_flags> field which
contains the active events before this callback was invoked. Thus, instead of
explicitly disabling all non-listed events, one can do the following:

    my $events_to_delete = $evdata->old_flags & (~$flags);

and only handle the events mentioned in C<$events_to_delete>

The C<old_flags> will be set to the current value of C<$flags> once the callback
returns.


The second argument (C<$action>) specifies which type of update this is. It can
be one of the following:

=over

=item C<EVACTION_WATCH>

Request that the stream be watched for events

=item C<EVACTION_UNWATCH>

Remove all watchers on this stream, and possibly do cleanup

=item C<EVACTION_SUSPEND>

Temporarily disable the watching of events on this stream, but do not forget
about which events are active

=item C<EVACTION_RESUME>

Resume a suspended event

=back

The suspension and resumption of events may be necessary so that libcouchbase
only receives events when it is ready for them, without impacting performance by
re-selecting all file descriptors.

L<POE::Kernel> has C<select_resume_read> and C<select_pause_read>, for example.


For the C<EVACTION_WATCH> event, the implementation must have the event loop
dispatch to a function that will ultimately do something of the following:

    Couchbase::Client::Async->HaveEvent($which, $evdata->opaque);

Where the C<$which> argument contains the event which ocurred (either
C<COUCHBASE_READ_EVENT> or C<COUCHBASE_WRITE_EVENT>), and the C<opaque> argument
being the C<opaque> field passed in (this) callback.

See L</HaveEvent> for more details.

=head3 C<cb_update_timer>

    cb_update_timer => sub {
        my ($evdata,$action,$usecs) = @_;
        my $timer_id = $evdata->pl_data;

        if($action == EVACTION_WATCH) {
            if(defined $timer_id) {
                reschedule_timer($timer_id, $usecs / (1000*1000),
                    callback => 'Couchbase::Client::Async::HaveData',
                    args => ['Couchbase::Client::Async', 0, $evdata->opaque]);

            } else {
                $timer_id = schedule_timer(
                    $usecs / (1000*1000) ...
                );
            }
        } else {
            delete_timer($evdata->pl_data);
        }
    };

This callback is invoked to schedule an interval timer.
It is passed three arguments:

=over

=item C<$evdata>

The 'event'. See L</cb_update_event> for details.

=item C<$action>

This is one of C<EVACTION_WATCH> and C<EVACTION_UNWATCH>.

For C<EVACTION_WATCH>, a timer should be scheduled to trigger in the future, for
C<EVACTION_UNWATCH>, and active timer should be deleted.

=item C<$usecs>

How many microseconds from now should the timer be triggered.

=back

These timers should end up calling L</HaveEvent> when they expire. The first
argument to L</HaveEvent> (the flags) is ignored, but it must still be passed
the C<opaque> object from C<$evdata> (see L</cb_update_event> for details).

It is common for timers to require some kind of internal identifier by which
the event loop can allow their cancelling and postponing.

In order to maintain the timer, the C<$evdata> offers a Perl-only writeable
C<pl_data> field, which can hold anything you want it to.

Timers should not be affected (or ever receive) C<EVACTION_SUSPEND> or
C<EVACTION_RESUME> actions.

=head3 C<cb_waitdone>

This is called with no arguments whenever libcouchbase has determined it no longer
needs to watch any file descriptors. Normally the L</cb_update_timer> will be
called with C<EVACTION_SUSPEND> for all active file descriptor watchers.

This can be used to signal other layers that there are no more pending user events
to wait for.

=head3 C<cb_error>

This is called with two arguments, the first an internal libcouchbase error number,
and the second, a string describing the details of the error.


=head2 C<HaveEvent>

This is the 'return trip' function which should be called whenever an event is
ready. It is a package method and not an object method.

It is called as so:

    Couchbase::Client::Async->HaveEvent($flags, $opaque);

The C<$flags> argument is only relevant for I/O events (and not timers). The
C<$opaque> argument must be supplied and contains an internal pointer to a private
C data structure. RTFSC if you really wish to know what's inside there.

=head1 COUCHBASE COMMANDS AND RESULTS

This contains the higher level inteface for issuing commands, and asynchronously
awaiting for their results to trickle in.

The asynchronous interface to this is a bit ugly, and is intended to be wrapped
according to the style you prefer.

There is only one function with which to issue commands:

=head2 C<request>

Issue couchbase command(s).

    $async->request(
        PLCBA_CMD_*, REQTYPE_*,
        sub {
            my ($results,$arg) = @_;
            print "i am a result callback.\n";
            printf("I have results for these keys: %s\n",
                join(",", keys %$results));
            printf("My request argument was $arg\n");
        },
        "arg",
        CBTYPE_*,
        [....],
    );

Pretty complicated, eh?

It was the only sane way to have a single request function without limiting the
featureset or duplicating code an insane amount of times.

The arguments are as follows:

=over

=item 0

The command. This is one of the C<PLCBA_CMD_*> macros, and are present in
L<Couchbase::Client::IDXConst>.

=item 1

Request type. This is one of C<REQTYPE_SINGLE> or C<REQTYPE_MULTI>. If the former
is specified, then only one set of parameters for the command will be passed;
if the latter, then this will be a single command which will operate on a multitude
of keys.

=item 2

Callback.

This is the callback which will be invoked when the command receives results. It
is called with two arguments. The first argument is a hash reference with the
command key(s) as its keys, and L<Couchbase::Client::Return> objects as its
values, which contain information about the response and status of the command.

The second argument is a user defined 'arg' defined next.

=item 3

Argument

This is a dummy argument passed to the callback, and can be whatever you want.

=item 4

Callback type.

This is one of C<CBTYPE_COMPLETION> and C<CBTYPE_INCREMENTAL>.

In the case of the former, the callback will only be invoked once, when all
the results for all the keys have been gathered. In the case of the latter, the
callback will be invoked for each new result received.

Note that the contents of the callback result hash is not automatically reset
in between calls, so it is advisable to clear the hash (or delete relevant keys)
if C<CBTYPE_INCREMENTAL> is used.

=item 5

Command arguments.

Either a L<Couchbase::Client::Async::Request> object, or an arrayref of such
objects; depending on whether C<REQTYPE_SINGLE> or C<REQTYPE_MULTI> was specifed,
respectively.

The L<Couchbase::Client::Async::Request> is a simple array, and it is not
strictly required to bless into this object. See its documentation for which
fields are provided, and which commands they apply to.

It may help to use my L<Array::Assign> module to deal with the fields in the
array.

=back
