package Couchbase::Client::Async::Event;
use strict;
use warnings;

use Couchbase::Client::IDXConst;
use Class::XSAccessor::Array {
    accessors => {
        dupfh => EVIDX_DUPFH,
        pldata => EVIDX_PLDATA,
    },
    getters => {
        fd => EVIDX_FD,
        old_flags => EVIDX_WATCHFLAGS,
        old_state => EVIDX_STATEFLAGS,
        opaque => EVIDX_OPAQUE
    }
};

1;

__END__

=head1 NAME

Couchbase::Client::Async::Event

Event object for asynchronous couchbase client

=head1 DESCRIPTION

This documents the specific fields in the Event structure. For a more detailed
overview of what this is used for, see L<Couchbase::Client::Async>

=head2 FIELDS

The Event object is a simple array, and can be accessed by using either the
listed index constants (exported by L<Couchbase::Client::IDXConst>) or by
using the named accessors.

Accessors are safer and do some basic sanity checking, at the cost of performance.

=over

=item EVIDX_FD, fd

Read-Only.

The file descriptor number for this event.

=item EVIDX_DUPFH, dupfh

The perl-level C<dup'd> file descriptor, if applicable.

This is mainly for use by event library plugins, but is modified (or rather,
deleted) if we detect the file descriptor has changed or otherwise become invalid.


=item EVIDX_WATCHLFAGS, old_flags

Read-Only.

The old event flags before invoking the callback with the new flags

=item EVIDX_STATEFLAGS, old_state

The old state (resumed, active, suspended, etc) of the event, before this
callback was invokved

=item EVIDX_OPAQUE, opaque

B<Read-Only>.

The opaque data to be passed back to us when an event is triggered.

=item EVIDX_PLDATA, pldata

This is for perl-level data. This library does not modify it, so feel free to
store whatever you want here.

