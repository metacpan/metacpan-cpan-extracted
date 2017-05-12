package Data::EventStream::Aggregator;
use Moose::Role;

our $VERSION = "0.13";
$VERSION = eval $VERSION;

=head1 NAME

Data::EventStream::Aggregator - Perl extension for event processing

=head1 VERSION

This document describes Data::EventStream::Aggregator version 0.13

=head1 DESCRIPTION

This role defines interface that should be implemented by any aggregator used
with L<Data::EventStream>. Aggregator does not have to be Moose class and
literally use this role, but it should implement the methods described.

=head1 METHODS

=cut

=head2 $self->enter($event, $window)

This method is invoked when a new event enters aggregator's window. Window
object already includes the new event.

=cut

requires 'enter';

=head2 $self->leave($event, $window)

This method is invoked when an event leaves aggregator's window. Window object
already excludes the leaving event.

=cut

requires 'leave';

=head2 $self->reset($window)

This method is invoked when aggregator is used in the batch mode, each time
after it finished processing another batch. Window object already empty and
doesn't have any events.

=cut

requires 'reset';

=head2 $self->window_update($window)

This method is invoked when time changes and window contains new time limits.
Note, that when window's time limits are changed this method is guaranteed to
be invoked, subsequent I<enter> and I<leave> invocations will have the same
I<start_time>, I<end_time>, and I<time_length> as during the last
I<window_update> invocation.

=cut

requires 'window_update';

1;
