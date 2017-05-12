package Bb::Collaborate::V3::Session::Attendance;
use warnings; use strict;

use Mouse;
use Carp;

extends 'Bb::Collaborate::V3';

use Bb::Collaborate::V3::Session::Attendees;

=head1 NAME

Bb::Collaborate::V3::Session::Attendance - Session Attendance Report

=head1 DESCRIPTION

This is the main entity class for session attendance reports.

=cut

__PACKAGE__->entity_name('SessionAttendance');
__PACKAGE__->params(sessionId => 'Int',
		    startTime => 'HiResDate',
		    endTime => 'HiResDate',
    );

=head1 PROPERTIES

=head2 roomName (Str)

The name of the room. This is derived from the name of the session as it was defined at the time the scheduled session was launched.

=cut

has 'roomName' => (is => 'rw', isa => 'Str', required => 1,
		   documentation => 'Name of the room'
    );

=head2 roomOpened (HiResDate)

The date and time that the room opened (also known as the date and time session was launched) in milliseconds.

=cut

has 'roomOpened' => (is => 'rw', isa => 'HiResDate', required => 1,
		       documentation => 'date and time that the session was launched');

=head2 roomClosed (HiResDate)

The date and time that the room shut down.

=cut

has 'roomClosed' => (is => 'rw', isa => 'HiResDate', required => 1,
		       documentation => 'date and time that room shut down');

=head2 attendees (Arr)

This is a collection of L<Bb::Collaborate::V3::Session::Attendee> objects. This collection represents all the attendees who were present in this session between the roomOpen and roomClosed time.

Since guests can attend sessions, not all the attendees may be users in your system.

=cut

has 'attendees' => (is => 'rw', isa => 'Bb::Collaborate::V3::Session::Attendees',
		    coerce => 1, documentation => 'Session attendees',);

# give soap a helping hand
__PACKAGE__->_alias(attendeeResponseCollection => 'attendees');

=head1 METHODS

=cut

=head2 list

    my $session_id = '123456789012';
    my $yesterday = DateTime->today->subtract(days => 1);

    my $attendance = Bb::Collaborate::V3::Session::Attendance->list(
                                    sessionId => $session_id,
                                    startTime => $yesterday->epoch.'000');

Gets a session attendance report. It returns a reference to an array of Bb::Collaborate::V3::Session::Attendance objects.

The attendance information is returned for the specified session for the 24 hour period starting from the date/time passed in. If the session ran more than once during that 24 hour period, you will get the attendance data for all instances of the session that ran during that date.
=cut

1;
