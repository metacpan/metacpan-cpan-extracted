package BusyBird::StatusStorage;
use v5.8.0;
use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

BusyBird::StatusStorage - interface for status storage objects

=head1 DESCRIPTION

This is an interface (or role) class for status storage objects.
This document is mainly for implementors of BusyBird::StatusStorage::* modules.

An L<BusyBird::StatusStorage> implementation stores and serves status objects for multiple timelines.
End-users usually access the status storage via L<BusyBird::Timeline> objects.

This class implements nothing.
An implementation of L<BusyBird::StatusStorage> must be a subclass of L<BusyBird::StatusStorage>
and implement the following methods.

To test if an implementation of L<BusyBird::StatusStorage> meets the specification,
you can use functions provided by L<BusyBird::Test::StatusStorage>.

Some methods are already implemented in L<BusyBird::StatusStorage::Common>.
You can import those implementations or implement them from scratch for better performance.

=head1 OBJECT METHODS

=head2 $storage->ack_statuses(%args)

=head2 $storage->get_statuses(%args)

=head2 $storage->put_statuses(%args)

=head2 $storage->delete_statuses(%args)

=head2 $storage->get_unacked_counts(%args)

=head2 $storage->contains(%args)

The above methods are the basis of L<BusyBird::Timeline>'s methods of the same names.
See L<BusyBird::Timeline> for the specification.

In addition to L<BusyBird::Timeline>'s specification,
C<%args> in all the methods has the following field.

=over

=item C<timeline> => TIMELINE_NAME (mandatory)

Specifies the name of the timeline.
If the name includes Unicode characters, it must be a character string (decoded string), not a binary string (encoded string).

=back

These methods are all in callback-style, that is,
the results are not returned but given to the callback functions.
This allows for both synchronous and asynchronous implementations.


=head1 GUIDELINE

This section describes guideline of the interface.

Implementations are recommended to follow the guideline, but they are
allowed not to follow it if their own rule is clearly documented.


=head2 Error Handling for Callback-style Methods

=over

=item 1.

Throw an exception if obviously illegal arguments are given, i.e. if
the user is to blame.

=item 2.

Never throw an exception but call C<callback> with truthy C<$error> if you
fail to complete the request, i.e. if you is to blame.

=item 3.

If some statuses given to C<put_statuses()> method do not have their C<id> fields,
the method may either throw an exception or automatically generate IDs for them and proceed.

=back


=head2 acked_at Field

C<ack_statuses()> method should update C<< $status->{busybird}{acked_at} >> field
of the target statuses to the date/time string of the current time.
The date/time format should be parsable by L<BusyBird::DateTime::Format> class.


=head2 Order of Statuses

In timelines, statuses should be sorted in descending order of
C<< $status->{busybird}{acked_at} >> field
(interpreted as date/time).
Unacked statuses should always be above acked statuses.
Ties are broken by sorting the statuses
in descending order of C<< $status->{created_at} >>
field (interpreted as date/time).

So the top of timeline is the latest created unacked status.
Below unacked statuses are layers of acked statuses.
The top of the acked statuses is the latest created status in the latest
acked ones.


=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut

