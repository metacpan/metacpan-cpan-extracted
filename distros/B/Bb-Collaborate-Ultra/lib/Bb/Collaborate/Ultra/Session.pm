package Bb::Collaborate::Ultra::Session;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';

use Bb::Collaborate::Ultra::Session::Occurrence;
use Bb::Collaborate::Ultra::Session::RecurrenceRule;
use Mouse::Util::TypeConstraints;

subtype 'ArrayOfOccurrences',
    as 'ArrayRef[Bb::Collaborate::Ultra::Session::Occurrence]';

coerce 'ArrayOfOccurrences',
    from 'ArrayRef[HashRef]',
    via { [ map {Bb::Collaborate::Ultra::Session::Occurrence->new($_)} (@$_) ] };

has 'occurrences' => (isa => 'ArrayOfOccurrences', is => 'rw', coerce => 1);
has 'recurrenceRule' => (isa => 'Bb::Collaborate::Ultra::Session::RecurrenceRule', is => 'rw', coerce => 1);

=head1 NAME

Bb::Collaborate::Ultra::Session

=head1 DESCRIPTION

This class is used to manage Sessions (Virtual Classrooms).

    use Bb::Collaborate::Ultra::Session;
    my $start = time() + 60;
    my $end = $start + 900;

    my $session;
    my $session = Bb::Collaborate::Ultra::Session->post($connection, {
	    name => 'Test Session',
	    startTime => $start,
	    endTime   => $end,
	    },
	);

=head2 Enrolling User in Sessions

AFAIK, there are two classes and two different modes for enrolling user to sessions:

=over 4

=item (*)  Ad-hoc users via L<Bb::Collaborate::Ultra::LaunchContext>

    my $user = Bb::Collaborate::Ultra::User->new({
	extId => 'testLaunchUser',
	displayName => 'David Warring',
	email => 'david.warring@gmail.com',
	firstName => 'David',
	lastName => 'Warring',
    });

    my $launch_context = Bb::Collaborate::Ultra::LaunchContext->new({ launchingRole => 'moderator',
	 editingPermission => 'writer',
	 user => $user,
	 });

    my $join_url = $launch_context->join_session($session);

=item (*) Permanently managed users via L<Bb::Collaborate::Ultra::LaunchContext>

Each user is created once.

    my $ultra_user = Bb::Collaborate::Ultra::User->create($connection, {
	extId => 'testLaunchUser',
	displayName => 'David Warring',
	email => 'david.warring@gmail.com',
	firstName => 'David',
	lastName => 'Warring',
    });
    my $ultra_user_id = $ultra_user->id;
    # somehow save the user id permanently...

The saved user-id may then be used to multiple times to join sessions:

     my $enrollment =  Bb::Collaborate::Ultra::Session::Enrollment->new({ launchingRole => 'moderator',
	 editingPermission => 'writer',
	 userId => $user2->id,
	 });
      my $join_url = $enrolment->enrol($session)->permanentUrl;

=back

=head1 METHODS

This class supports the `get`, `post`, `patch` and `del` methods as described in L<https://xx-csa.bbcollab.com/documentation#Session>

=cut

sub _thaw {
    my $self = shift;
    my $data = shift;
    my $thawed = $self->SUPER::_thaw($data, @_);
    my $occurrences = $data->{occurrences};
    $thawed->{occurrences} = [ map { Bb::Collaborate::Ultra::Session::Occurrence->_thaw($_) } (@$occurrences) ]
	if $occurrences;
    $thawed;
}

__PACKAGE__->resource('sessions');
__PACKAGE__->load_schema(<DATA>);
__PACKAGE__->query_params(
    name => 'Str',
    userId => 'Str',
    contextId => 'Str',
    startTime => 'Date',
    endTime => 'Date',
    sessionCategory => 'Str',
    );

=head2 get_enrollments

Return a list of users, of type L<Bb::Collaborate::Ultra::Session::Enrollment>.

    my @enrollments = $session->get_enrollments;
    for my $enrolment (@enrollments) {
        say "user @{[$enrolment->userId]} is enrolled as a @{[$enrollment->launchingRole]}";
    }

=cut

sub get_enrollments {
    my $self = shift;
    my $query = shift || {};
    my %opt = @_;
    my $connection = $opt{connection} || $self->connection;
    my $path = $self->path.'/enrollments';
    require Bb::Collaborate::Ultra::Session::Enrollment;
    Bb::Collaborate::Ultra::Session::Enrollment->get($connection, $query, path => $path, parent => $self);
}

=head2 get_logs

Returns logging (session-instance) information for completed sessions

=cut

sub get_logs {
    my $self = shift;
    my $query = shift || {};
    my %opt = @_;
    my $connection = $opt{connection} || $self->connection;
    my $path = $self->path.'/instances';
    require Bb::Collaborate::Ultra::Session::Log;
    Bb::Collaborate::Ultra::Session::Log->get($connection, $query, path => $path, parent => $self);
}

1;
# downloaded from https://xx-csa.bbcollab.com/documentation
__DATA__
                {
  "type" : "object",
  "id" : "urn:jsonschema:com:blackboard:collaborate:csl:core:dto:Session",
  "properties" : {
    "telephonyPhoneNumber" : {
      "type" : "string"
    },
    "courseRoomEnabled" : {
      "type" : "boolean"
    },
    "noEndDate" : {
      "type" : "boolean"
    },
    "participantCanUseTools" : {
      "type" : "boolean"
    },
    "largeSessionEnable" : {
      "type" : "boolean"
    },
    "endTime" : {
      "type" : "string",
      "required" : true,
      "format" : "DATE_TIME"
    },
    "guestRole" : {
      "type" : "string",
      "enum" : [ "participant", "moderator", "presenter" ]
    },
    "openChair" : {
      "type" : "boolean"
    },
    "showProfile" : {
      "type" : "boolean"
    },
    "startTime" : {
      "type" : "string",
      "required" : true,
      "format" : "DATE_TIME"
    },
    "id" : {
      "type" : "string"
    },
    "ltiParticipantRole" : {
      "type" : "string",
      "enum" : [ "participant", "moderator", "presenter" ]
    },
    "occurrenceType" : {
      "type" : "string",
      "enum" : [ "S", "P" ]
    },
    "canDownloadRecording" : {
      "type" : "boolean"
    },
    "created" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "description" : {
      "type" : "string"
    },
    "occurrences" : {
      "type" : "array",
      "items" : {
        "type" : "object",
        "id" : "urn:jsonschema:com:blackboard:collaborate:csl:core:dto:SessionOccurrence",
        "properties" : {
          "id" : {
            "type" : "string"
          },
          "startTime" : {
            "type" : "string",
            "format" : "DATE_TIME"
          },
          "active" : {
            "type" : "boolean"
          },
          "endTime" : {
            "type" : "string",
            "format" : "DATE_TIME"
          }
        }
      }
    },
    "name" : {
      "type" : "string",
      "required" : true
    },
    "raiseHandOnEnter" : {
      "type" : "boolean"
    },
    "canAnnotateWhiteboard" : {
      "type" : "boolean"
    },
    "recurrenceRule" : {
      "type" : "object",
      "id" : "urn:jsonschema:com:blackboard:collaborate:csl:core:dto:RecurrenceRule",
      "properties" : {
        "recurrenceEndType" : {
          "type" : "string",
          "enum" : [ "on_date", "after_occurrences_count" ]
        },
        "daysOfTheWeek" : {
          "type" : "array",
          "items" : {
            "type" : "string",
            "enum" : [ "mo", "tu", "we", "th", "fr", "sa", "su" ]
          }
        },
        "recurrenceType" : {
          "type" : "string",
          "enum" : [ "daily", "weekly", "monthly" ]
        },
        "interval" : {
          "type" : "string",
          "enum" : [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" ]
        },
        "numberOfOccurrences" : {
          "type" : "integer"
        },
        "endDate" : {
          "type" : "string",
          "format" : "DATE_TIME"
        }
      }
    },
    "sessionCategory" : {
      "type" : "string",
      "enum" : [ "default", "course" ]
    },
    "canPostMessage" : {
      "type" : "boolean"
    },
    "mustBeSupervised" : {
      "type" : "boolean"
    },
    "createdTimezone" : {
      "type" : "string"
    },
    "moderatorUrl" : {
      "type" : "string"
    },
    "allowGuest" : {
      "type" : "boolean"
    },
    "telephonyEnabled" : {
      "type" : "boolean"
    },
    "editingPermission" : {
      "type" : "string",
      "enum" : [ "reader", "writer" ]
    },
    "modified" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "guestUrl" : {
      "type" : "string"
    },
    "canShareVideo" : {
      "type" : "boolean"
    },
    "sessionExitUrl" : {
      "type" : "string"
    },
    "boundaryTime" : {
      "type" : "string",
      "enum" : [ "0", "15", "30", "45", "60" ]
    },
    "active" : {
      "type" : "boolean"
    },
    "allowInSessionInvitees" : {
      "type" : "boolean"
    },
    "canEnableLargeSession" : {
      "type" : "boolean"
    },
    "canShareAudio" : {
      "type" : "boolean"
    },
    "anonymizeRecordings" : {
      "type" : "boolean"
    }
  }
}
